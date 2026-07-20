package com.nayasantha.api.plan;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public final class WeeklyPlanDtos {

    private WeeklyPlanDtos() {}

    public record PlanItemDto(UUID id, UUID productId, String name, String emoji, String unit,
                              int quantity, BigDecimal unitForecastPrice, BigDecimal unitMaxPrice,
                              BigDecimal lineEstimate, BigDecimal lineMax, String reason, Long version) {}

    public record PlanDto(UUID id, LocalDate weekStart, String status, String aiSource,
                          String aiExplanation, BigDecimal estimatedTotal, BigDecimal maximumPayable,
                          int itemCount, List<PlanItemDto> items, Long version) {}

    public record UpdatePlanItemRequest(int quantity, Long version) {}
}
