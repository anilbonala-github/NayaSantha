package com.nayasantha.api.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** Typed binding for the {@code nayasantha.*} configuration tree. */
@ConfigurationProperties(prefix = "nayasantha")
public class AppProperties {

    private Jwt jwt = new Jwt();
    private Otp otp = new Otp();
    private Gemini gemini = new Gemini();

    public Jwt getJwt() { return jwt; }
    public void setJwt(Jwt jwt) { this.jwt = jwt; }
    public Otp getOtp() { return otp; }
    public void setOtp(Otp otp) { this.otp = otp; }
    public Gemini getGemini() { return gemini; }
    public void setGemini(Gemini gemini) { this.gemini = gemini; }

    /** Google Gemini for weekly-plan recommendations (Vol2 §10). Empty apiKey =>
     *  deterministic fallback planner runs instead. */
    public static class Gemini {
        private String apiKey = "";
        private String model = "gemini-2.0-flash";
        private String promptVersion = "plan-v1";

        public boolean isEnabled() { return apiKey != null && !apiKey.isBlank(); }
        public String getApiKey() { return apiKey; }
        public void setApiKey(String apiKey) { this.apiKey = apiKey; }
        public String getModel() { return model; }
        public void setModel(String model) { this.model = model; }
        public String getPromptVersion() { return promptVersion; }
        public void setPromptVersion(String promptVersion) { this.promptVersion = promptVersion; }
    }

    public static class Jwt {
        private String secret;
        private long accessTokenTtlSeconds = 3600;
        private long refreshTokenTtlSeconds = 2592000;
        private String issuer = "nayasantha";

        public String getSecret() { return secret; }
        public void setSecret(String secret) { this.secret = secret; }
        public long getAccessTokenTtlSeconds() { return accessTokenTtlSeconds; }
        public void setAccessTokenTtlSeconds(long v) { this.accessTokenTtlSeconds = v; }
        public long getRefreshTokenTtlSeconds() { return refreshTokenTtlSeconds; }
        public void setRefreshTokenTtlSeconds(long v) { this.refreshTokenTtlSeconds = v; }
        public String getIssuer() { return issuer; }
        public void setIssuer(String issuer) { this.issuer = issuer; }
    }

    public static class Otp {
        private boolean devMode = true;
        private String devCode = "000000";
        private int length = 6;
        private long ttlSeconds = 300;

        public boolean isDevMode() { return devMode; }
        public void setDevMode(boolean devMode) { this.devMode = devMode; }
        public String getDevCode() { return devCode; }
        public void setDevCode(String devCode) { this.devCode = devCode; }
        public int getLength() { return length; }
        public void setLength(int length) { this.length = length; }
        public long getTtlSeconds() { return ttlSeconds; }
        public void setTtlSeconds(long ttlSeconds) { this.ttlSeconds = ttlSeconds; }
    }
}
