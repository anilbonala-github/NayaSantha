package com.nayasantha.api.plan;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "weekly_plans")
@Getter
@Setter
public class WeeklyPlan extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "household_id")
    private UUID householdId;

    @Column(name = "week_start", nullable = false)
    private LocalDate weekStart;

    @Column(name = "estimated_total", nullable = false)
    private BigDecimal estimatedTotal = BigDecimal.ZERO;

    @Column(name = "maximum_payable", nullable = false)
    private BigDecimal maximumPayable = BigDecimal.ZERO;

    @Column(name = "ai_explanation")
    private String aiExplanation;

    @Column(name = "ai_model")
    private String aiModel;

    @Column(name = "ai_prompt_version")
    private String aiPromptVersion;

    @Enumerated(EnumType.STRING)
    @Column(name = "ai_source", nullable = false)
    private AiSource aiSource = AiSource.FALLBACK;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status = Status.DRAFT;

    public enum AiSource { GEMINI, FALLBACK }
    public enum Status { DRAFT, APPROVED, CONFIRMED, EXPIRED }
}
