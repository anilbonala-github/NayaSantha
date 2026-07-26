package com.nayasantha.api.recipe;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

/** A recipe whose ingredients map to catalogue products. */
@Entity
@Table(name = "recipes")
@Getter
@Setter
public class Recipe {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(nullable = false, unique = true)
    private String code;

    @Column(nullable = false)
    private String title;

    private String description;
    private String emoji;
    private String cuisine;

    @Column(nullable = false)
    private int servings = 4;

    @Column(name = "prep_minutes", nullable = false)
    private int prepMinutes = 30;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder = 0;

    @Column(nullable = false)
    private boolean active = true;
}
