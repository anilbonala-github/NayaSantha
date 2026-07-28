package com.nayasantha.api.coupon;

import jakarta.validation.constraints.NotBlank;

import java.math.BigDecimal;
import java.time.Instant;

public final class CouponDtos {

    private CouponDtos() {}

    public record CouponDto(String code, String title, String description, String summary,
                            String discountType, BigDecimal discountValue, BigDecimal minBasket,
                            BigDecimal maxDiscount, boolean newUsersOnly, boolean membersOnly,
                            String tint, Instant validUntil) {}

    public record ApplyCouponRequest(@NotBlank String code) {}
}
