package com.nayasantha.api.security;

import com.nayasantha.api.config.AppProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

/** Issues and validates short-lived JWT access tokens (Vol2 §5 auth). */
@Service
public class JwtService {

    private final SecretKey key;
    private final AppProperties props;

    public JwtService(AppProperties props) {
        this.props = props;
        this.key = Keys.hmacShaKeyFor(props.getJwt().getSecret().getBytes(StandardCharsets.UTF_8));
    }

    public record Principal(UUID userId, String role, long roleVersion, boolean staffVerified) {}

    public String issueAccessToken(UUID userId, String mobile, String role) {
        return issueAccessToken(userId, mobile, role, 0);
    }
    public String issueAccessToken(UUID userId, String mobile, String role, long roleVersion) {
        return issueAccessToken(userId, mobile, role, roleVersion, !props.getOtp().isDevMode());
    }
    public String issueAccessToken(UUID userId, String mobile, String role, long roleVersion, boolean staffVerified) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(userId.toString())
                .claim("mobile", mobile)
                .claim("role", role)
                .claim("roleVersion", roleVersion)
                .claim("staffVerified", staffVerified)
                .issuer(props.getJwt().getIssuer())
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(props.getJwt().getAccessTokenTtlSeconds())))
                .signWith(key)
                .compact();
    }

    /** Returns the userId + role from a valid token, or throws if invalid/expired. */
    public Principal parse(String token) {
        Claims claims = Jwts.parser().verifyWith(key).requireIssuer(props.getJwt().getIssuer()).build()
                .parseSignedClaims(token).getPayload();
        String role = claims.get("role", String.class);
        Number version = (Number) claims.get("roleVersion");
        return new Principal(UUID.fromString(claims.getSubject()), role == null ? "CUSTOMER" : role,
            version == null ? 0 : version.longValue(), Boolean.TRUE.equals(claims.get("staffVerified")));
    }
}
