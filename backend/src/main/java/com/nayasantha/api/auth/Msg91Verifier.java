package com.nayasantha.api.auth;

import com.fasterxml.jackson.databind.JsonNode;
import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.common.ErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;
import java.util.Map;

/** Exchanges provider proof on the server. Never trusts a browser-supplied identity. */
@Service
public class Msg91Verifier {
    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(Msg91Verifier.class);
    private final RestClient client;
    private final String authKey;
    private final boolean enabled;

    public Msg91Verifier(@Value("${MSG91_AUTH_KEY:}") String authKey,
                         @Value("${MSG91_ENABLED:false}") boolean enabled) {
        this.authKey = authKey;
        this.enabled = enabled;
        var factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(5000);
        factory.setReadTimeout(10000);
        this.client = RestClient.builder().requestFactory(factory)
                .baseUrl("https://control.msg91.com/api/v5/widget").build();
    }

    public String verify(String token) {
        if (!enabled || authKey.isBlank()) throw ApiException.userError("SMS sign-in is not configured yet.");
        JsonNode result;
        try {
            result = client.post().uri("/verifyAccessToken")
                    .body(Map.of("authkey", authKey, "access-token", token))
                    .retrieve().body(JsonNode.class);
        } catch (Exception e) {
            // Provider exceptions can contain credentials or user tokens. Do not expose/log them.
            throw ApiException.userError("Could not verify SMS sign-in. Please request a new code and try again.");
        }
        // Only structural diagnostics: no code, token, mobile number or provider message.
        log.info("MSG91 verification response: success={}, rootIdentifierType={}, dataType={}, nestedIdentifierType={}",
                result != null && "success".equals(result.path("type").asText()),
                result == null ? "NULL" : result.path("identifier").getNodeType(),
                result == null ? "NULL" : result.path("data").getNodeType(),
                result == null ? "NULL" : result.path("data").path("identifier").getNodeType());
        if (result != null) {
            var keys = new java.util.ArrayList<String>();
            result.fieldNames().forEachRemaining(keys::add);
            log.info("MSG91 verification response field names: {}", keys);
        }
        return verifiedMobile(result);
    }

    static String verifiedMobile(JsonNode result) {
        if (result == null || !"success".equals(result.path("type").asText())) throw invalid("SMS_PROOF_REJECTED");
        // Read identity only from MSG91's authenticated server response, never the client JWT.
        String direct = identifier(result.path("identifier"));
        String nested = identifier(result.path("data").path("identifier"));
        if (direct != null && nested != null && !direct.equals(nested)) throw invalid("SMS_IDENTITY_CONFLICT");
        String mobile = direct != null ? direct : nested;
        if (mobile == null) throw new ApiException(ErrorCode.INTERNAL_ERROR,
                "MSG91 success response did not contain a supported verified mobile identity",
                "SMS verification completed, but we could not finish sign-in. Please contact support.");
        return mobile;
    }

    private static String identifier(JsonNode value) {
        if (value.isMissingNode() || value.isNull()) return null;
        if (!value.isTextual() || !value.textValue().matches("\\+?91[6-9]\\d{9}")) throw invalid("SMS_IDENTITY_FORMAT");
        String identifier = value.textValue();
        return identifier.substring(identifier.length() - 10);
    }

    private static ApiException invalid(String reason) {
        log.warn("MSG91 sign-in rejected: {}", reason);
        return new ApiException(ErrorCode.OTP_INVALID, reason,
                "Could not confirm your SMS verification (" + reason + "). Request a new code or contact support.");
    }
}
