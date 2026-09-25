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
        return verifiedMobile(result);
    }

    static String verifiedMobile(JsonNode result) {
        if (result == null || !"success".equals(result.path("type").asText())) throw invalid();
        String identifier = result.path("data").path("identifier").asText("");
        if (!identifier.matches("\\+?91[6-9]\\d{9}")) throw invalid();
        return identifier.substring(identifier.length() - 10);
    }

    private static ApiException invalid() {
        return new ApiException(ErrorCode.OTP_INVALID, "Provider did not return a verified Indian mobile identity");
    }
}
