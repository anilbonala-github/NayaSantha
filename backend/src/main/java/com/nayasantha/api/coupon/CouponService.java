package com.nayasantha.api.coupon;

import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.coupon.CouponDtos.CouponDto;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Coupon catalogue + validation/computation. Discounts apply to a settled
 * order's payable amount; {@link com.nayasantha.api.order.OrderService} owns the
 * order mutation and calls {@link #validateAndCompute} / {@link #recordRedemption}.
 */
@Service
public class CouponService {

    private final CouponRepository coupons;
    private final CouponRedemptionRepository redemptions;

    public CouponService(CouponRepository coupons, CouponRedemptionRepository redemptions) {
        this.coupons = coupons;
        this.redemptions = redemptions;
    }

    /** The outcome of applying a coupon to a specific payable amount. */
    public record Applied(Coupon coupon, BigDecimal discount) {}

    /** Active, in-window coupons for the offers screen. */
    @Transactional(readOnly = true)
    public List<CouponDto> listActive() {
        Instant now = Instant.now();
        return coupons.findByActiveTrueOrderBySortOrderAsc().stream()
                .filter(c -> inWindow(c, now))
                .map(this::toDto)
                .toList();
    }

    /**
     * Validate {@code code} against {@code payable} and return the coupon + discount.
     * {@code excludeOrderId} keeps the caller's own order out of usage counts so a
     * re-apply to the same order is idempotent. Throws {@link ApiException} (400) if
     * the coupon can't be applied.
     */
    @Transactional(readOnly = true)
    public Applied validateAndCompute(String code, UUID userId, BigDecimal payable,
                                      boolean isNewUser, UUID excludeOrderId) {
        Coupon c = coupons.findByCodeIgnoreCase(code.trim())
                .filter(Coupon::isActive)
                .orElseThrow(() -> bad("That coupon code isn't valid."));
        if (!inWindow(c, Instant.now())) throw bad("That coupon has expired.");
        if (payable.compareTo(c.getMinBasket()) < 0) {
            throw bad("This coupon needs a basket of at least " + money(c.getMinBasket()) + ".");
        }
        if (c.isNewUsersOnly() && !isNewUser) {
            throw bad("This coupon is for first-time households only.");
        }
        if (redemptions.countByCouponIdAndUserIdAndOrderIdNot(c.getId(), userId, excludeOrderId)
                >= c.getPerUserLimit()) {
            throw bad("You've already used this coupon.");
        }
        if (c.getUsageLimit() != null
                && redemptions.countByCouponIdAndOrderIdNot(c.getId(), excludeOrderId) >= c.getUsageLimit()) {
            throw bad("This coupon has been fully claimed.");
        }
        BigDecimal discount = computeDiscount(c, payable);
        if (discount.signum() <= 0) throw bad("This coupon gives no discount on this order.");
        return new Applied(c, discount);
    }

    /** Persist (or replace) the redemption for an order. */
    @Transactional
    public void recordRedemption(Coupon coupon, UUID userId, UUID orderId, BigDecimal discount) {
        redemptions.deleteByOrderId(orderId);
        CouponRedemption r = new CouponRedemption();
        r.setCouponId(coupon.getId());
        r.setUserId(userId);
        r.setOrderId(orderId);
        r.setDiscountAmount(discount);
        redemptions.save(r);
    }

    /** Remove any coupon redemption tied to an order. */
    @Transactional
    public void clearRedemption(UUID orderId) {
        redemptions.deleteByOrderId(orderId);
    }

    BigDecimal computeDiscount(Coupon c, BigDecimal payable) {
        BigDecimal raw = c.isPercent()
                ? payable.multiply(c.getDiscountValue()).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP)
                : c.getDiscountValue();
        if (c.isPercent() && c.getMaxDiscount() != null && raw.compareTo(c.getMaxDiscount()) > 0) {
            raw = c.getMaxDiscount();
        }
        return raw.min(payable).max(BigDecimal.ZERO);
    }

    private boolean inWindow(Coupon c, Instant now) {
        if (c.getValidFrom() != null && now.isBefore(c.getValidFrom())) return false;
        return c.getValidUntil() == null || !now.isAfter(c.getValidUntil());
    }

    private CouponDto toDto(Coupon c) {
        return new CouponDto(c.getCode(), c.getTitle(), c.getDescription(), summary(c),
                c.getDiscountType(), c.getDiscountValue(), c.getMinBasket(), c.getMaxDiscount(),
                c.isNewUsersOnly(), c.getTint(), c.getValidUntil());
    }

    private String summary(Coupon c) {
        if (c.isPercent()) {
            String s = c.getDiscountValue().stripTrailingZeros().toPlainString() + "% off";
            return c.getMaxDiscount() != null ? s + ", up to " + money(c.getMaxDiscount()) : s;
        }
        return money(c.getDiscountValue()) + " off";
    }

    private static ApiException bad(String msg) {
        return ApiException.userError(msg);
    }

    private static String money(BigDecimal v) {
        return "₹" + v.stripTrailingZeros().toPlainString();
    }
}
