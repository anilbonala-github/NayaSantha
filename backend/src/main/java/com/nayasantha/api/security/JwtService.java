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

    public String issueAccessToken(UUID userId, String mobile) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(userId.toString())
                .claim("mobile", mobile)
                .issuer(props.getJwt().getIssuer())
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(props.getJwt().getAccessTokenTtlSeconds())))
                .signWith(key)
                .compact();
    }

    /** Returns the userId from a valid token, or throws if invalid/expired. */
    public UUID parseUserId(String token) {
        Claims claims = Jwts.parser().verifyWith(key).build()
                .parseSignedClaims(token).getPayload();
        return UUID.fromString(claims.getSubject());
    }
}
