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
    private final com.nayasantha.api.subscription.SubscriptionService subscriptions;
    private final com.nayasantha.api.push.PushSender pushSender;
    private final com.nayasantha.api.user.UserRepository users;
    private final com.nayasantha.api.device.UserDeviceRepository devices;
    private final com.nayasantha.api.notification.NotificationService notifications;

    public OpsController(OpsService ops, WeeklyCycleService cycle,
                         com.nayasantha.api.subscription.SubscriptionService subscriptions,
                         com.nayasantha.api.push.PushSender pushSender,
                         com.nayasantha.api.user.UserRepository users,
                         com.nayasantha.api.device.UserDeviceRepository devices,
                         com.nayasantha.api.notification.NotificationService notifications) {
        this.ops = ops;
        this.cycle = cycle;
        this.subscriptions = subscriptions;
        this.pushSender = pushSender;
        this.users = users;
        this.devices = devices;
        this.notifications = notifications;
    }

    /** Send a REAL test push (+ in-app notification) to a customer by mobile. (admin-only) */
    @PostMapping("/push-user")
    public ApiResponse<Map<String, Object>> pushUser(@RequestParam String mobile) {
        var user = users.findByMobile(mobile)
                .orElseThrow(() -> com.nayasantha.api.common.ApiException.notFound("User " + mobile));
        int deviceCount = devices.findByUserId(user.getId()).size();
        notifications.create(user.getId(), "TEST", "NayaSantha",
                "🎉 Your push notifications are working.", null);
        Map<String, Object> out = new java.util.LinkedHashMap<>();
        out.put("mobile", mobile);
        out.put("devices", deviceCount);
        out.put("sender", pushSender.getClass().getSimpleName());
        out.put("note", deviceCount == 0
                ? "No devices registered for this user — open the app, log in, and tap Enable notifications first."
                : "Sent to " + deviceCount + " device(s).");
        return ApiResponse.of(out);
    }

    /** Diagnostic: is FCM active and do the credentials authenticate? (admin-only) */
    @PostMapping("/push-test")
    public ApiResponse<Map<String, Object>> pushTest(@RequestParam(required = false) String token) {
        Map<String, Object> out = new java.util.LinkedHashMap<>();
        out.put("sender", pushSender.getClass().getSimpleName());
        if (pushSender instanceof com.nayasantha.api.push.FcmPushSender fcm) {
            out.put("initialised", fcm.isInitialised());
            out.put("dryRun", fcm.dryRun(token != null ? token : "diagnostic-dummy-token"));
        } else {
            out.put("note", "FCM disabled — LogPushSender active (set FCM_ENABLED=true)");
        }
        return ApiResponse.of(out);
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

    /** Manually run subscription billing — renew memberships due from the wallet. */
    @PostMapping("/run-subscription-billing")
    public ApiResponse<com.nayasantha.api.subscription.SubscriptionDtos.RenewalResultDto> runSubscriptionBilling() {
        return ApiResponse.of(subscriptions.renewDue());
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

    // --- fulfillment: packing (§7.4) + delivery (Vol1 §14) ----------------------
    @GetMapping("/packing")
    public ApiResponse<PackingDto> packing() {
        return ApiResponse.of(ops.packing());
    }

    @GetMapping("/delivery")
    public ApiResponse<DeliveryDto> delivery() {
        return ApiResponse.of(ops.delivery());
    }

    @PostMapping("/orders/{id}/pack")
    public ApiResponse<Map<String, String>> pack(@PathVariable java.util.UUID id) {
        return ApiResponse.of(Map.of("stage", ops.pack(id)));
    }

    @PostMapping("/orders/{id}/dispatch")
    public ApiResponse<Map<String, String>> dispatch(@PathVariable java.util.UUID id) {
        return ApiResponse.of(Map.of("stage", ops.dispatch(id)));
    }

    @PostMapping("/orders/{id}/deliver")
    public ApiResponse<Map<String, String>> deliver(@PathVariable java.util.UUID id) {
        return ApiResponse.of(Map.of("stage", ops.deliver(id)));
    }

    /** Issue a refund against a captured order (missing item, quality claim, cancellation). */
    @PostMapping("/orders/{id}/refund")
    public ApiResponse<com.nayasantha.api.order.OrderDtos.RefundDto> refund(
            @PathVariable java.util.UUID id, @Valid @RequestBody RefundRequest body) {
        return ApiResponse.of(ops.refund(id, body));
    }

    /** Operational report (pilot metrics). */
    @GetMapping("/reports")
    public ApiResponse<com.nayasantha.api.order.OrderDtos.ReportDto> reports() {
        return ApiResponse.of(ops.reports());
    }
}
