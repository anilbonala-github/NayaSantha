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
            BigDecimal forecastRate,
            BigDecimal capturedRate,
            BigDecimal estimatedAmount) {}

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
