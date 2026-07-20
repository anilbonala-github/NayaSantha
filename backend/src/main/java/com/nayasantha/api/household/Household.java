package com.nayasantha.api.household;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "households")
@Getter
@Setter
public class Household extends BaseEntity {

    @Column(name = "owner_user_id", nullable = false, unique = true)
    private UUID ownerUserId;

    @Column(name = "weekly_budget", nullable = false)
    private BigDecimal weeklyBudget = BigDecimal.ZERO;

    @Column(nullable = false)
    private String language = "en";

    @Enumerated(EnumType.STRING)
    @Column(name = "default_price_consent", nullable = false)
    private PriceConsent defaultPriceConsent = PriceConsent.ASK;

    public enum PriceConsent { ASK, AUTO_WITHIN_MAX, NO_SUBSTITUTION }
}
