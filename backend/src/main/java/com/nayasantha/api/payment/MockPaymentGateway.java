package com.nayasantha.api.payment;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Simulated gateway used until a real provider is configured. Generates
 * reference strings so the order/refund flow is exercised end-to-end without
 * moving money. To go live, add a real {@link PaymentGateway} adapter (e.g.
 * RazorpayGateway) as {@code @Primary} gated by config, and this stays the fallback.
 */
@Component
public class MockPaymentGateway implements PaymentGateway {

    @Override
    public boolean isLive() { return false; }

    @Override
    public String authorize(UUID orderId, BigDecimal maxAmount) {
        return "auth_" + UUID.randomUUID().toString().substring(0, 12);
    }

    @Override
    public String capture(String authorizationReference, BigDecimal amount) {
        return "cap_" + UUID.randomUUID().toString().substring(0, 12);
    }

    @Override
    public String refund(String captureReference, BigDecimal amount) {
        return "rfnd_" + UUID.randomUUID().toString().substring(0, 12);
    }
}
