package com.nayasantha.api.payment;

import com.fasterxml.jackson.databind.JsonNode;
import com.nayasantha.api.config.AppProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

/**
 * Real Razorpay adapter (Vol2A §14). Activated only when
 * {@code nayasantha.payments.razorpay.enabled=true} and keys are set; @Primary so
 * it replaces {@link MockPaymentGateway}. Handles amounts + references only — the
 * customer authorizes payment via Razorpay Checkout in the app, never here.
 *
 * <p>NOTE: {@code capture} and {@code refund} operate on a Razorpay <b>payment id</b>
 * obtained from the client checkout + webhook flow. Until that flow is wired, only
 * {@code authorize} (order creation) is exercised. Use TEST keys to verify.
 */
@Component
@Primary
@ConditionalOnProperty(name = "nayasantha.payments.razorpay.enabled", havingValue = "true")
public class RazorpayGateway implements PaymentGateway {

    private static final Logger log = LoggerFactory.getLogger(RazorpayGateway.class);
    private static final String BASE = "https://api.razorpay.com/v1";

    private final RestClient http = RestClient.create();
    private final String authHeader;

    public RazorpayGateway(AppProperties props) {
        var r = props.getPayments().getRazorpay();
        this.authHeader = "Basic " + Base64.getEncoder().encodeToString(
                (r.getKeyId() + ":" + r.getKeySecret()).getBytes(StandardCharsets.UTF_8));
        log.info("Razorpay gateway active (keyId {}…)",
                r.getKeyId().length() > 6 ? r.getKeyId().substring(0, 6) : r.getKeyId());
    }

    @Override
    public boolean isLive() { return true; }

    /** Create a Razorpay order for the guaranteed maximum (payment_capture=0 = manual). */
    @Override
    public String authorize(UUID orderId, BigDecimal maxAmount) {
        JsonNode res = http.post().uri(BASE + "/orders")
                .header("Authorization", authHeader)
                .body(Map.of(
                        "amount", paise(maxAmount),
                        "currency", "INR",
                        "receipt", orderId.toString(),
                        "payment_capture", 0))
                .retrieve().body(JsonNode.class);
        return res == null ? null : res.path("id").asText();
    }

    /** Capture only the final amount against the authorized payment id (from checkout). */
    @Override
    public String capture(String paymentId, BigDecimal amount) {
        JsonNode res = http.post().uri(BASE + "/payments/" + paymentId + "/capture")
                .header("Authorization", authHeader)
                .body(Map.of("amount", paise(amount), "currency", "INR"))
                .retrieve().body(JsonNode.class);
        return res == null ? null : res.path("id").asText();
    }

    /** Refund an amount against the captured payment id. */
    @Override
    public String refund(String paymentId, BigDecimal amount) {
        JsonNode res = http.post().uri(BASE + "/payments/" + paymentId + "/refund")
                .header("Authorization", authHeader)
                .body(Map.of("amount", paise(amount)))
                .retrieve().body(JsonNode.class);
        return res == null ? null : res.path("id").asText();
    }

    /** Razorpay amounts are in paise (integer). */
    private static long paise(BigDecimal rupees) {
        return rupees.movePointRight(2).setScale(0, RoundingMode.HALF_UP).longValueExact();
    }
}
