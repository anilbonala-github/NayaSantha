package com.nayasantha.api.order;

import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class OrderDtos {

    private OrderDtos() {}

    /** Approve the plan before Saturday cutoff with a price preference + consent (Vol2A §6.2). */
    public record ApproveRequest(
            @NotNull String pricePreference,   // SMART_SUBSTITUTE | KEEP_EXACT_ITEMS | ASK_BEFORE_CHANGE | REMOVE_EXPENSIVE_ITEMS
            BigDecimal maxPayable,             // optional stricter cap
            Boolean substitutionConsent,
            String deviceInfo) {}

    public record PriceDecisionRequest(@NotNull String decision) {} // ACCEPT | REMOVE_EXPENSIVE | CANCEL

    public record OrderItemDto(UUID id, UUID productId, String name, String unit, int quantity,
                               BigDecimal forecastRate, BigDecimal estimatedAmount,
                               BigDecimal actualRate, Integer finalQty, BigDecimal finalAmount,
                               String substitutionReason) {}

    public record ExceptionDto(UUID id, String reason, BigDecimal finalTotal, BigDecimal maxPayable,
                               Instant responseDeadline, String resolution) {}

    public record OrderDto(UUID id, String status, String pricePreference,
                           BigDecimal estimatedTotal, BigDecimal maximumPayable, BigDecimal finalTotal,
                           BigDecimal savings, String deliverySlot, String fulfillmentStage, String paymentStatus,
                           List<OrderItemDto> items, ExceptionDto exception, Instant createdAt, Long version) {}

    public record PriceComparisonLine(String name, int quantity, BigDecimal forecastRate,
                                      BigDecimal actualRate, BigDecimal estimatedAmount,
                                      BigDecimal finalAmount, BigDecimal difference) {}

    public record PriceComparisonDto(BigDecimal estimatedTotal, BigDecimal finalTotal,
                                     BigDecimal savings, boolean withinCap,
                                     List<PriceComparisonLine> lines) {}
}
