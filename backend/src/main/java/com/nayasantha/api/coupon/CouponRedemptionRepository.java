package com.nayasantha.api.coupon;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface CouponRedemptionRepository extends JpaRepository<CouponRedemption, UUID> {
    Optional<CouponRedemption> findByOrderId(UUID orderId);
    void deleteByOrderId(UUID orderId);

    // Usage counts exclude the current order so re-applying to the same order is idempotent.
    long countByCouponIdAndOrderIdNot(UUID couponId, UUID orderId);
    long countByCouponIdAndUserIdAndOrderIdNot(UUID couponId, UUID userId, UUID orderId);
}
