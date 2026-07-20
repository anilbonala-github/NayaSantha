package com.nayasantha.api.address;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "addresses")
@Getter
@Setter
public class Address extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    private String label;

    @Column(nullable = false)
    private String line1;

    private String line2;
    private String apartment;

    @Column(nullable = false)
    private String city = "Hyderabad";

    @Column(nullable = false)
    private String pincode;

    private BigDecimal latitude;
    private BigDecimal longitude;

    @Column(name = "is_serviceable", nullable = false)
    private boolean serviceable = false;

    @Column(name = "is_default", nullable = false)
    private boolean isDefault = false;
}
