package com.nayasantha.api.order;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.order.OrderDtos.*;
import com.nayasantha.api.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/** Phase 4 pricing/order endpoints (Vol2A §11). Server owns all totals. */
@RestController
@RequestMapping("/api/v1")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    /** Approve the plan with price consent before Saturday cutoff. */
    @PostMapping("/weekly-plans/{planId}/approve")
    public ApiResponse<OrderDto> approve(@PathVariable UUID planId,
                                         @Valid @RequestBody ApproveRequest body) {
        return ApiResponse.of(orderService.approve(CurrentUser.id(), planId, body));
    }

    @PostMapping("/orders/{id}/lock")
    public ApiResponse<OrderDto> lock(@PathVariable UUID id) {
        return ApiResponse.of(orderService.lock(CurrentUser.id(), id));
    }

    /** DEV: simulates the Sunday market price capture (the real ops portal is Vol3). */
    @PostMapping("/orders/{id}/simulate-settlement")
    public ApiResponse<OrderDto> simulateSettlement(@PathVariable UUID id) {
        return ApiResponse.of(orderService.simulateSettlement(CurrentUser.id(), id));
    }

    @PostMapping("/orders/{id}/price-decision")
    public ApiResponse<OrderDto> decide(@PathVariable UUID id,
                                        @Valid @RequestBody PriceDecisionRequest body) {
        return ApiResponse.of(orderService.decide(CurrentUser.id(), id, body.decision()));
    }

    @PostMapping("/payments/{orderId}/capture")
    public ApiResponse<OrderDto> capture(@PathVariable UUID orderId) {
        return ApiResponse.of(orderService.capture(CurrentUser.id(), orderId));
    }

    @GetMapping("/orders")
    public ApiResponse<List<OrderDto>> list(@RequestParam(defaultValue = "0") int page,
                                            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.of(orderService.list(CurrentUser.id(), page, size));
    }

    @GetMapping("/orders/{id}")
    public ApiResponse<OrderDto> get(@PathVariable UUID id) {
        return ApiResponse.of(orderService.get(CurrentUser.id(), id));
    }

    @GetMapping("/orders/{id}/price-comparison")
    public ApiResponse<PriceComparisonDto> priceComparison(@PathVariable UUID id) {
        return ApiResponse.of(orderService.priceComparison(CurrentUser.id(), id));
    }
}
