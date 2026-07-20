package com.nayasantha.api.catalogue;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Effective-dated price for a product/zone. estimate = sellingPrice; the basket's
 *  guaranteed ceiling = maxPrice (Vol1 §6, Vol2 §3.2). No updated_at column. */
@Entity
@Table(name = "product_prices")
@Getter
@Setter
public class ProductPrice {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "product_id", nullable = false)
    private UUID productId;

    @Column(nullable = false)
    private String zone = "HYD_PILOT";

    private BigDecimal mrp;

    @Column(name = "forecast_price", nullable = false)
    private BigDecimal forecastPrice;

    @Column(name = "selling_price", nullable = false)
    private BigDecimal sellingPrice;

    @Column(name = "max_price", nullable = false)
    private BigDecimal maxPrice;

    @Column(name = "effective_from", nullable = false)
    private Instant effectiveFrom = Instant.now();

    @Column(name = "effective_to")
    private Instant effectiveTo;

    @Column(nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Version
    @Column(nullable = false)
    private Long version;
}
