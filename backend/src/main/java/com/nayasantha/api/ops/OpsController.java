package com.nayasantha.api.ops;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.ops.OpsDtos.*;
import com.nayasantha.api.schedule.WeeklyCycleService;
import com.nayasantha.api.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Vol3 ops/admin portal. Guarded by {@code hasRole('ADMIN')} in SecurityConfig,
 * so only mobiles listed in ADMIN_MOBILES reach these endpoints.
 */
@RestController
@RequestMapping("/api/v1/ops")
public class OpsController {

    private final OpsService ops;
    private final WeeklyCycleService cycle;

    public OpsController(OpsService ops, WeeklyCycleService cycle) {
        this.ops = ops;
        this.cycle = cycle;
    }

    /** Manually send the Saturday cutoff reminders (fallback when the cron can't run). */
    @PostMapping("/run-reminder")
    public ApiResponse<Map<String, Integer>> runReminder() {
        return ApiResponse.of(Map.of("remindersSent", cycle.sendCutoffReminders()));
    }

    /** Manually run the Saturday cutoff — lock all confirmed orders. */
    @PostMapping("/run-cutoff")
    public ApiResponse<Map<String, Integer>> runCutoff() {
        return ApiResponse.of(Map.of("ordersLocked", cycle.runCutoff()));
    }

    /** Cutoff snapshot: locked orders, households, totals, price-capture progress. */
    @GetMapping("/summary")
    public ApiResponse<OpsSummaryDto> summary() {
        return ApiResponse.of(ops.summary());
    }

    /** Order-cutoff console: status counts + exceptions queue. */
    @GetMapping("/cutoff")
    public ApiResponse<CutoffDto> cutoff() {
        return ApiResponse.of(ops.cutoff());
    }

    /** Consolidated buy list across every locked order (what the buyer takes to market). */
    @GetMapping("/purchase-list")
    public ApiResponse<List<PurchaseLineDto>> purchaseList() {
        return ApiResponse.of(ops.purchaseList());
    }

    /** Record the real Sunday rates for one or more products (upsert per week). */
    @PostMapping("/prices")
    public ApiResponse<CaptureResultDto> capturePrices(@Valid @RequestBody CapturePricesRequest body) {
        return ApiResponse.of(ops.capturePrices(CurrentUser.id(), body));
    }

    /** Settle every locked order against the captured rates and close the cycle. */
    @PostMapping("/finalize")
    public ApiResponse<FinalizeResultDto> finalizeWeek(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart) {
        return ApiResponse.of(ops.finalizeWeek(weekStart));
    }
}
