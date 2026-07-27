package com.nayasantha.api.insights;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.insights.InsightsDtos.BudgetInsightsDto;
import com.nayasantha.api.security.CurrentUser;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Budget insights from the customer's order history. */
@RestController
@RequestMapping("/api/v1/budget-insights")
public class BudgetController {

    private final BudgetInsightsService insights;

    public BudgetController(BudgetInsightsService insights) {
        this.insights = insights;
    }

    @GetMapping
    public ApiResponse<BudgetInsightsDto> get() {
        return ApiResponse.of(insights.forUser(CurrentUser.id()));
    }
}
