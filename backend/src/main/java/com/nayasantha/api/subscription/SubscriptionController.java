package com.nayasantha.api.subscription;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.security.CurrentUser;
import com.nayasantha.api.subscription.SubscriptionDtos.*;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** Membership plans + the customer's subscription (Vol1 §9.1). */
@RestController
@RequestMapping("/api/v1")
public class SubscriptionController {

    private final SubscriptionService subscriptions;

    public SubscriptionController(SubscriptionService subscriptions) {
        this.subscriptions = subscriptions;
    }

    @GetMapping("/subscription-plans")
    public ApiResponse<List<PlanDto>> plans() {
        return ApiResponse.of(subscriptions.listPlans());
    }

    /** Current active membership, or null (= Basic/free). */
    @GetMapping("/subscriptions/current")
    public ApiResponse<SubscriptionDto> current() {
        return ApiResponse.of(subscriptions.current(CurrentUser.id()));
    }

    @PostMapping("/subscriptions")
    public ApiResponse<SubscriptionDto> subscribe(@Valid @RequestBody SubscribeRequest body) {
        return ApiResponse.of(subscriptions.subscribe(CurrentUser.id(), body.planCode()));
    }

    @PostMapping("/subscriptions/cancel")
    public ApiResponse<Map<String, String>> cancel() {
        subscriptions.cancel(CurrentUser.id());
        return ApiResponse.of(Map.of("status", "cancelled"));
    }

    /** The customer's subscription billing history (most recent first). */
    @GetMapping("/subscriptions/payments")
    public ApiResponse<List<PaymentDto>> payments(@RequestParam(defaultValue = "0") int page,
                                                  @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.of(subscriptions.paymentHistory(CurrentUser.id(), page, size));
    }
}
