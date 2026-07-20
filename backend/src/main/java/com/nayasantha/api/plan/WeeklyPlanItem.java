package com.nayasantha.api.plan;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "weekly_plan_items")
@Getter
@Setter
public class WeeklyPlanItem extends BaseEntity {

    @Column(name = "plan_id", nullable = false)
    private UUID planId;

    @Column(name = "product_id", nullable = false)
    private UUID productId;

    @Column(nullable = false)
    private int quantity;

    @Column(name = "unit_forecast_price", nullable = false)
    private BigDecimal unitForecastPrice;

    @Column(name = "unit_max_price", nullable = false)
    private BigDecimal unitMaxPrice;

    private String reason;

    @Column(name = "substitution_group")
    private String substitutionGroup;
}
