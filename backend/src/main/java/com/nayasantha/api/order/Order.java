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

    @Column(name = "delivery_slot")
    private String deliverySlot;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status = Status.CONFIRMED;

    @Column(name = "locked_at")
    private Instant lockedAt;

    public enum Status { CONFIRMED, LOCKED, PURCHASING, FINALIZED, AWAITING_APPROVAL, PAID, DELIVERED, CANCELLED }
}
