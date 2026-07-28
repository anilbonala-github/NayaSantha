package com.nayasantha.api.coupon;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** A discount coupon applied to a settled order's payable amount (Vol1 offers). */
@Entity
@Table(name = "coupons")
@Getter
@Setter
public class Coupon {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String code;

    @Column(nullable = false)
    private String title;

    private String description;

    @Column(name = "discount_type", nullable = false)
    private String discountType;      // PERCENT | FLAT

    @Column(name = "discount_value", nullable = false)
    private BigDecimal discountValue;

    @Column(name = "min_basket", nullable = false)
    private BigDecimal minBasket = BigDecimal.ZERO;

    @Column(name = "max_discount")
    private BigDecimal maxDiscount;   // cap for PERCENT (null = uncapped)

    @Column(name = "valid_from")
    private Instant validFrom;

    @Column(name = "valid_until")
    private Instant validUntil;

    @Column(name = "usage_limit")
    private Integer usageLimit;       // global cap (null = unlimited)

    @Column(name = "per_user_limit", nullable = false)
    private int perUserLimit = 1;

    @Column(name = "new_users_only", nullable = false)
    private boolean newUsersOnly = false;

    @Column(name = "members_only", nullable = false)
    private boolean membersOnly = false;

    private String tint;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder = 0;

    @Column(nullable = false)
    private boolean active = true;

    public boolean isPercent() { return "PERCENT".equalsIgnoreCase(discountType); }
}
