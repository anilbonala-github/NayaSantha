package com.nayasantha.api.ops;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Request/response DTOs for the Vol3 ops portal (JSON camelCase). */
public final class OpsDtos {

    private OpsDtos() {}

    /** Saturday-cutoff snapshot of the open procurement cycle. */
    public record OpsSummaryDto(
            LocalDate weekStart,
            long lockedOrders,
            long households,
            BigDecimal totalEstimated,
            BigDecimal totalMaxPayable,
            int distinctProducts,
            int pricesCaptured,
            int pricesPending) {}

    /** One consolidated buy line across every locked order (what the buyer takes to market). */
    public record PurchaseLineDto(
            UUID productId,
            String name,
            String unit,
            int totalQuantity,
            int bufferPercent,       // procurement buffer (Vol2A FR-007)
            int buyQuantity,         // required qty + buffer, rounded up
            BigDecimal forecastRate,
            BigDecimal maxRate,      // guaranteed max purchase rate per unit (forecast x1.025)
            BigDecimal capturedRate,
            BigDecimal estimatedAmount) {}

    /** Order-cutoff console snapshot (Vol2A §7.1). */
    public record CutoffDto(
            LocalDate weekStart,
            long approved,           // locked orders
            long pending,            // confirmed, not yet locked
            long needsAttention,     // awaiting customer approval (over cap)
            long cancelled,
            List<CutoffExceptionDto> exceptions) {}

    public record CutoffExceptionDto(String orderRef, String reason, String type) {}

    // --- fulfillment: packing (Vol2A §7.4) + delivery (Vol1 §14) -----------------
    public record FulfillmentOrderDto(UUID orderId, String ref, String community, String slot,
                                      String stage, BigDecimal finalTotal) {}

    public record PackingWaveDto(String community, int total, int packed,
                                 List<FulfillmentOrderDto> orders) {}

    public record PackingDto(int total, int pending, int packing, int packed,
                             List<PackingWaveDto> waves) {}

    public record DeliveryDto(int readyToDispatch, int outForDelivery, int delivered,
                              List<FulfillmentOrderDto> orders) {}

    public record PriceEntry(
            @NotNull UUID productId,
            @NotNull @DecimalMin(value = "0.0", inclusive = true) BigDecimal actualRate) {}

    public record CapturePricesRequest(
            LocalDate weekStart,                       // optional; defaults to current week
            @NotEmpty @Valid List<PriceEntry> prices) {}

    public record CaptureResultDto(LocalDate weekStart, int captured) {}

    public record FinalizeResultDto(
            LocalDate weekStart,
            int ordersProcessed,
            int finalized,
            int awaitingApproval,
            BigDecimal totalFinal) {}
}
