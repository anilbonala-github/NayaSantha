package com.nayasantha.api.plan;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.plan.WeeklyPlanDtos.*;
import com.nayasantha.api.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/** AI weekly plan (Vol2 §6.5). Gemini proposes; the server validates and owns totals. */
@RestController
@RequestMapping("/api/v1/weekly-plans")
public class WeeklyPlanController {

    private final WeeklyPlanService planService;

    public WeeklyPlanController(WeeklyPlanService planService) {
        this.planService = planService;
    }

    @PostMapping("/generate")
    public ApiResponse<PlanDto> generate() {
        return ApiResponse.of(planService.generateDto(CurrentUser.id()));
    }

    @GetMapping("/current")
    public ApiResponse<PlanDto> current() {
        return ApiResponse.of(planService.currentDto(CurrentUser.id()));
    }

    @PatchMapping("/{planId}/items/{itemId}")
    public ApiResponse<PlanDto> updateItem(@PathVariable UUID planId, @PathVariable UUID itemId,
                                           @Valid @RequestBody UpdatePlanItemRequest body) {
        return ApiResponse.of(planService.updateItem(CurrentUser.id(), planId, itemId,
                body.quantity(), body.version()));
    }
}
