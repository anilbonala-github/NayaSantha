package com.nayasantha.api.catalogue;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

/** /ops/** is restricted to ADMIN by SecurityConfig. */
@RestController
@RequestMapping("/api/v1/ops/selling-prices")
public class WeeklyPricingController {
    private final WeeklyPricingService pricing;
    public WeeklyPricingController(WeeklyPricingService pricing) { this.pricing = pricing; }
    @PostMapping("/publish")
    public ApiResponse<WeeklyPricingService.Published> publish(
            @Valid @RequestBody WeeklyPricingService.PublishRequest request) {
        return ApiResponse.of(pricing.publish(CurrentUser.id(), request));
    }
}
