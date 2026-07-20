package com.nayasantha.api.household;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Entity
@Table(name = "household_members")
@Getter
@Setter
public class HouseholdMember extends BaseEntity {

    @Column(name = "household_id", nullable = false)
    private UUID householdId;

    private String name;
    private Integer age;

    @Enumerated(EnumType.STRING)
    @Column(name = "dietary_type", nullable = false)
    private DietaryType dietaryType = DietaryType.VEG;

    /** Comma-separated hard exclusions (allergies are exclusions, not preferences). */
    private String allergies;

    @Column(name = "nutrition_notes")
    private String nutritionNotes;

    public enum DietaryType { VEG, NON_VEG, VEGAN, EGGETARIAN }
}
