package com.nayasantha.api.coupon;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

/** Records that a coupon was applied to an order, for usage limits + audit. */
@Entity
@Table(name = "coupon_redemptions")
@Getter
@Setter
public class CouponRedemption extends BaseEntity {

    @Column(name = "coupon_id", nullable = false)
    private UUID couponId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "order_id", nullable = false)
    private UUID orderId;

    @Column(name = "discount_amount", nullable = false)
    private BigDecimal discountAmount;
}
