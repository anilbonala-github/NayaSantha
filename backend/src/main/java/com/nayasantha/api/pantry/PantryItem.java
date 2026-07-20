package com.nayasantha.api.pantry;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "pantry_items")
@Getter
@Setter
public class PantryItem extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "product_id")
    private UUID productId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private BigDecimal quantity = BigDecimal.ZERO;

    private String unit;

    @Column(name = "low_stock_threshold", nullable = false)
    private BigDecimal lowStockThreshold = BigDecimal.ONE;

    @Column(name = "purchase_date")
    private LocalDate purchaseDate;

    @Column(name = "expiry_date")
    private LocalDate expiryDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Source source = Source.MANUAL;

    public enum Source { MANUAL, ORDER, SCAN }
}
