package com.nayasantha.api.ops;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * The real market rate captured on Sunday for a product in a given delivery week
 * (Vol3 ops). One row per (product, week); replaces the random settlement stub.
 */
@Entity
@Table(name = "market_prices")
@Getter
@Setter
public class MarketPrice {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(name = "product_id", nullable = false)
    private UUID productId;

    @Column(name = "week_start", nullable = false)
    private LocalDate weekStart;

    @Column(name = "actual_rate", nullable = false)
    private BigDecimal actualRate;

    @Column(name = "captured_by")
    private UUID capturedBy;

    @Column(name = "captured_at", nullable = false)
    private Instant capturedAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    @Version
    @Column(nullable = false)
    private long version;
}
