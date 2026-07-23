package com.nayasantha.api.payment;

import com.fasterxml.jackson.databind.JsonNode;
import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.common.ErrorCode;
import com.nayasantha.api.order.OrderDtos.OrderDto;
import com.nayasantha.api.order.OrderService;
import com.nayasantha.api.security.CurrentUser;
import jakarta.validation.constraints.NotNull;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Razorpay Standard Checkout endpoints (Vol2A §14). The client asks for a
 * Razorpay order, opens the modal, then posts the signature back for verification.
 * The order is only marked paid after the signature verifies server-side.
 */
@RestController
@RequestMapping("/api/v1/payments/razorpay")
public class RazorpayCheckoutController {

    private final RazorpayCheckoutService razorpay;
    private final OrderService orders;

    public RazorpayCheckoutController(RazorpayCheckoutService razorpay, OrderService orders) {
        this.razorpay = razorpay;
        this.orders = orders;
    }

    public record CreateOrderRequest(@NotNull UUID orderId) {}

    public record VerifyRequest(@NotNull UUID orderId, String razorpayOrderId,
                                String razorpayPaymentId, String razorpaySignature) {}

    /** Create a Razorpay order for the settled order's final amount. */
    @PostMapping("/order")
    public ApiResponse<Map<String, Object>> createOrder(@RequestBody CreateOrderRequest body) {
        if (!razorpay.isConfigured()) {
            // Frontend falls back to the simulated capture when Razorpay isn't set up.
            return ApiResponse.of(Map.of("configured", false));
        }
        OrderDto order = orders.get(CurrentUser.id(), body.orderId());
        if (order.finalTotal() == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Order has no final amount yet");
        }
        if ("PAID".equals(order.status())) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Order is already paid");
        }
        long amountPaise = order.finalTotal().movePointRight(2)
                .setScale(0, java.math.RoundingMode.HALF_UP).longValueExact();

        // Razorpay caps receipt at 40 chars; a bare UUID is 36.
        JsonNode rzp = razorpay.createOrder(amountPaise, body.orderId().toString());

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("configured", true);
        out.put("keyId", razorpay.keyId());
        out.put("razorpayOrderId", rzp.path("id").asText());
        out.put("amount", rzp.path("amount").asLong());
        out.put("currency", rzp.path("currency").asText("INR"));
        out.put("orderId", body.orderId().toString());
        out.put("name", "NayaSantha");
        out.put("description", "Weekly grocery order");
        return ApiResponse.of(out);
    }

    /** Verify the signature; mark the order paid only if it matches. */
    @PostMapping("/verify")
    public ApiResponse<Map<String, Object>> verify(@RequestBody VerifyRequest body) {
        if (body.razorpayOrderId() == null || body.razorpayPaymentId() == null
                || body.razorpaySignature() == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Missing payment fields");
        }
        boolean ok = razorpay.verifySignature(
                body.razorpayOrderId(), body.razorpayPaymentId(), body.razorpaySignature());
        if (!ok) {
            // 400 — do NOT mark as paid.
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Payment signature verification failed");
        }
        OrderDto paid = orders.markPaidExternally(CurrentUser.id(), body.orderId(), body.razorpayPaymentId());
        return ApiResponse.of(Map.of("status", "paid", "orderStatus", paid.status(),
                "paymentId", body.razorpayPaymentId()));
    }
}
