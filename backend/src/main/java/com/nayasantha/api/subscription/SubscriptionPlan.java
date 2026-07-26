package com.nayasantha.api.subscription;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

/** A membership plan (Vol1 §9.1). */
@Entity
@Table(name = "subscription_plans")
@Getter
@Setter
public class SubscriptionPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String code;

    @Column(nullable = false)
    private String name;

    private String badge;

    @Column(name = "price_per_month", nullable = false)
    private BigDecimal pricePerMonth = BigDecimal.ZERO;

    /** Newline-separated perks. */
    @Column(nullable = false)
    private String perks = "";

    @Column(name = "sort_order", nullable = false)
    private int sortOrder = 0;

    @Column(nullable = false)
    private boolean active = true;
}
