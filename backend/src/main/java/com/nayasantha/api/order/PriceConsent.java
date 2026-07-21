package com.nayasantha.api.order;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Immutable, audited record of the customer's price/substitution consent (Vol2A §6.2). */
@Entity
@Table(name = "price_consents")
@Getter
@Setter
public class PriceConsent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "plan_id", nullable = false)
    private UUID planId;

    @Column(name = "order_id")
    private UUID orderId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "max_payable", nullable = false)
    private BigDecimal maxPayable;

    @Column(nullable = false)
    private String preference;

    @Column(name = "substitution_consent", nullable = false)
    private boolean substitutionConsent = true;

    @Column(name = "consent_version", nullable = false)
    private String consentVersion = "v1";

    @Column(name = "device_info")
    private String deviceInfo;

    @Column(name = "consented_at", nullable = false)
    private Instant consentedAt = Instant.now();
}
