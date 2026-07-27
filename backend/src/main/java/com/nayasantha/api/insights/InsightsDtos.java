package com.nayasantha.api.insights;

import java.math.BigDecimal;
import java.util.List;

public final class InsightsDtos {

    private InsightsDtos() {}

    public record PointDto(String label, BigDecimal amount) {}

    public record CategorySpendDto(String category, BigDecimal amount) {}

    public record BudgetInsightsDto(
            BigDecimal weeklyBudget,
            int ordersSettled,
            BigDecimal avgWeeklySpend,
            BigDecimal lastSpend,
            BigDecimal totalSaved,
            double withinBudgetRate,
            List<PointDto> recentSpend,
            List<CategorySpendDto> categorySpend) {}
}
