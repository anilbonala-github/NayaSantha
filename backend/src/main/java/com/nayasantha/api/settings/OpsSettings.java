package com.nayasantha.api.settings;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

/** Single-row configurable ops settings (Vol2A §9). */
@Entity
@Table(name = "ops_settings")
@Getter
@Setter
public class OpsSettings extends BaseEntity {

    @Column(name = "buffer_percent", nullable = false)
    private int bufferPercent = 5;

    @Column(name = "cap_percent", nullable = false)
    private BigDecimal capPercent = new BigDecimal("2.5");

    @Column(name = "variance_threshold_percent", nullable = false)
    private int varianceThresholdPercent = 10;

    @Column(name = "delivery_slot", nullable = false)
    private String deliverySlot = "Sun 2:00-8:00 PM";
}
