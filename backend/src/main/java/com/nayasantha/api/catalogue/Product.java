package com.nayasantha.api.catalogue;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "products")
@Getter
@Setter
public class Product extends BaseEntity {

    @Column(nullable = false, unique = true)
    private String sku;

    @Column(nullable = false)
    private String name;

    @Column(name = "category_id", nullable = false)
    private UUID categoryId;

    @Column(nullable = false)
    private String unit;

    private String description;
    private String emoji;

    @Column(name = "image_url")
    private String imageUrl;

    private String origin;
    private String farmer;

    private BigDecimal rating;

    @Column(name = "rating_count", nullable = false)
    private int ratingCount = 0;

    /** Comma-separated trust markers, e.g. "Farm Fresh,No Chemicals". */
    private String badges;

    @Column(nullable = false)
    private boolean active = true;
    // Note: the `nutrition` jsonb column exists in the DB but is not mapped yet.
}
