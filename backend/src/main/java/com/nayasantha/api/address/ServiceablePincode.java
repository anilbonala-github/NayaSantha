package com.nayasantha.api.address;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "serviceable_pincodes")
@Getter
@Setter
public class ServiceablePincode {

    @Id
    private String pincode;

    @Column(name = "area_name")
    private String areaName;

    @Column(nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();
}
