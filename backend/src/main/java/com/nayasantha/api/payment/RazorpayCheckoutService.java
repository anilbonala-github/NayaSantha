package com.nayasantha.api.payment;

import com.fasterxml.jackson.databind.JsonNode;
import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.common.ErrorCode;
import com.nayasantha.api.config.AppProperties;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.Map;

/**
 * Razorpay Standard Checkout server side (create order + verify signature).
 * Reads keys from config (never exposes the secret). KEY_SECRET stays server-only;
 * only the KEY_ID is returned to the client for the modal.
 */
@Service
public class RazorpayCheckoutService {

    private static final String ORDERS_URL = "https://api.razorpay.com/v1/orders";

    private final RestClient http = RestClient.create();
    private final AppProperties props;

    public RazorpayCheckoutService(AppProperties props) {
        this.props = props;
    }

    private AppProperties.Payments.Razorpay cfg() {
        return props.getPayments().getRazorpay();
    }

    /** True when both keys are present, so the real checkout can run. */
    public boolean isConfigured() {
        return cfg().getKeyId() != null && !cfg().getKeyId().isBlank()
                && cfg().getKeySecret() != null && !cfg().getKeySecret().isBlank();
    }

    public String keyId() {
        return cfg().getKeyId();
    }

    private String authHeader() {
        return "Basic " + Base64.getEncoder().encodeToString(
                (cfg().getKeyId() + ":" + cfg().getKeySecret()).getBytes(StandardCharsets.UTF_8));
    }

    /** Create a Razorpay order (amount in paise, >= 100). Returns id/amount/currency. */
    public JsonNode createOrder(long amountPaise, String receipt) {
        if (amountPaise < 100) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Amount must be at least 100 paise");
        }
        try {
            return http.post().uri(ORDERS_URL)
                    .header("Authorization", authHeader())
                    .body(Map.of("amount", amountPaise, "currency", "INR", "receipt", receipt))
                    .retrieve().body(JsonNode.class);
        } catch (RestClientResponseException e) {
            if (e.getStatusCode().value() == 401) {
                throw new ApiException(ErrorCode.UNAUTHORIZED, "Razorpay authentication failed (check keys)");
            }
            throw new ApiException(ErrorCode.INTERNAL_ERROR,
                    "Razorpay order creation failed: " + e.getResponseBodyAsString());
        }
    }

    /**
     * Verify the checkout signature: HMAC-SHA256(razorpayOrderId + "|" + paymentId, KEY_SECRET),
     * compared constant-time with the signature Razorpay returned.
     */
    public boolean verifySignature(String razorpayOrderId, String paymentId, String signature) {
        if (isBlank(razorpayOrderId) || isBlank(paymentId) || isBlank(signature)) return false;
        String expected = hmacSha256Hex(razorpayOrderId + "|" + paymentId, cfg().getKeySecret());
        return MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8), signature.getBytes(StandardCharsets.UTF_8));
    }

    private static boolean isBlank(String s) { return s == null || s.isBlank(); }

    private static String hmacSha256Hex(String data, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] raw = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(raw.length * 2);
            for (byte b : raw) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR, "Signature computation failed");
        }
    }
}
