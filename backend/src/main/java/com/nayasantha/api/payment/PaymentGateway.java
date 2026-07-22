package com.nayasantha.api.payment;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Payment provider seam (Vol2A §14). The app authorizes the guaranteed maximum,
 * captures only the final amount, and refunds against the capture. Swap the
 * {@link MockPaymentGateway} for a real adapter (e.g. Razorpay/UPI-Autopay) by
 * providing a bean when merchant credentials are configured — no other code
 * changes. Never handles raw card/UPI credentials; amounts + references only.
 */
public interface PaymentGateway {

    /** Whether this is a real money-moving gateway (false for the simulator). */
    boolean isLive();

    /** Authorize (hold) up to {@code maxAmount}; returns a mandate/auth reference. */
    String authorize(UUID orderId, BigDecimal maxAmount);

    /** Capture {@code amount} against an authorization; returns a capture reference. */
    String capture(String authorizationReference, BigDecimal amount);

    /** Refund {@code amount} against a capture; returns a refund reference. */
    String refund(String captureReference, BigDecimal amount);
}
