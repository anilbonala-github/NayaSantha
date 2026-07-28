package com.nayasantha.api.subscription;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** One billing attempt against a subscription (wallet-funded). */
@Entity
@Table(name = "subscription_payments")
@Getter
@Setter
public class SubscriptionPayment extends BaseEntity {

    @Column(name = "subscription_id", nullable = false)
    private UUID subscriptionId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "plan_id", nullable = false)
    private UUID planId;

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(nullable = false)
    private String status;   // PAID | FAILED

    private String reason;

    @Column(name = "period_start", nullable = false)
    private Instant periodStart;

    @Column(name = "period_end", nullable = false)
    private Instant periodEnd;
}
