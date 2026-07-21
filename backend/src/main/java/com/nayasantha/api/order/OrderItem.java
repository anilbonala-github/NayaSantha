package com.nayasantha.api.order;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

/** Snapshot of a basket line at confirmation; Sunday actuals filled in on settlement. */
@Entity
@Table(name = "order_items")
@Getter
@Setter
public class OrderItem extends BaseEntity {

    @Column(name = "order_id", nullable = false)
    private UUID orderId;

    @Column(name = "product_id", nullable = false)
    private UUID productId;

    @Column(nullable = false)
    private String name;

    private String unit;

    @Column(nullable = false)
    private int quantity;

    @Column(name = "forecast_rate", nullable = false)
    private BigDecimal forecastRate;

    @Column(name = "estimated_amount", nullable = false)
    private BigDecimal estimatedAmount;

    @Column(name = "actual_rate")
    private BigDecimal actualRate;

    @Column(name = "final_qty")
    private Integer finalQty;

    @Column(name = "final_amount")
    private BigDecimal finalAmount;

    @Column(name = "substitution_reason")
    private String substitutionReason;
}
