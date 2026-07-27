package com.nayasantha.api.order;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "orders")
@Getter
@Setter
public class Order extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "plan_id")
    private UUID planId;

    @Column(name = "address_snapshot")
    private String addressSnapshot;

    @Column(name = "price_preference", nullable = false)
    private String pricePreference;

    @Column(name = "estimated_total", nullable = false)
    private BigDecimal estimatedTotal;

    @Column(name = "maximum_payable", nullable = false)
    private BigDecimal maximumPayable;

    @Column(name = "final_total")
    private BigDecimal finalTotal;

    @Column(name = "discount_amount", nullable = false)
    private BigDecimal discountAmount = BigDecimal.ZERO;

    @Column(name = "coupon_code")
    private String couponCode;

    @Column(name = "delivery_slot")
    private String deliverySlot;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status = Status.CONFIRMED;

    @Column(name = "locked_at")
    private Instant lockedAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "fulfillment_stage", nullable = false)
    private FulfillmentStage fulfillmentStage = FulfillmentStage.PENDING;

    @Column(name = "community")
    private String community;

    /** What the customer actually pays: final total less any coupon discount, floored at zero. */
    @Transient
    public BigDecimal getAmountPayable() {
        if (finalTotal == null) return null;
        BigDecimal d = discountAmount == null ? BigDecimal.ZERO : discountAmount;
        return finalTotal.subtract(d).max(BigDecimal.ZERO);
    }

    public enum Status { CONFIRMED, LOCKED, PURCHASING, FINALIZED, AWAITING_APPROVAL, PAID, DELIVERED, CANCELLED }
    public enum FulfillmentStage { PENDING, PACKING, PACKED, OUT_FOR_DELIVERY, DELIVERED }
}
