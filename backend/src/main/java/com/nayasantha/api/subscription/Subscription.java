package com.nayasantha.api.subscription;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

/** A user's membership subscription (Vol2 §3.2). */
@Entity
@Table(name = "subscriptions")
@Getter
@Setter
public class Subscription extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "plan_id", nullable = false)
    private UUID planId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status = Status.ACTIVE;

    @Column(name = "billing_cycle", nullable = false)
    private String billingCycle = "MONTHLY";

    @Column(name = "started_at", nullable = false)
    private Instant startedAt = Instant.now();

    @Column(name = "renews_at")
    private Instant renewsAt;

    @Column(name = "cancelled_at")
    private Instant cancelledAt;

    public enum Status { ACTIVE, CANCELLED, EXPIRED }
}
