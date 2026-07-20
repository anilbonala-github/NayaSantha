package com.nayasantha.api.auth;

import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.common.ErrorCode;
import com.nayasantha.api.config.AppProperties;
import com.nayasantha.api.security.JwtService;
import com.nayasantha.api.user.User;
import com.nayasantha.api.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/** Orchestrates OTP verification, user upsert and JWT/refresh-token issuance. */
@Service
public class AuthService {

    private final OtpService otpService;
    private final UserRepository users;
    private final AuthSessionRepository sessions;
    private final JwtService jwtService;
    private final AppProperties props;

    public AuthService(OtpService otpService, UserRepository users, AuthSessionRepository sessions,
                       JwtService jwtService, AppProperties props) {
        this.otpService = otpService;
        this.users = users;
        this.sessions = sessions;
        this.jwtService = jwtService;
        this.props = props;
    }

    public AuthDtos.OtpRequestResult requestOtp(String mobile) {
        return otpService.request(mobile);
    }

    @Transactional
    public AuthDtos.TokenResponse verifyOtp(String mobile, String code, String userAgent) {
        otpService.verify(mobile, code);

        User user = users.findByMobile(mobile).orElseGet(() -> {
            User u = new User();
            u.setMobile(mobile);
            u.setProfileCompletionStatus(User.ProfileCompletionStatus.NEW);
            return u;
        });
        user.setLastLoginAt(Instant.now());
        user = users.save(user);

        return issueTokens(user, userAgent);
    }

    @Transactional
    public AuthDtos.TokenResponse refresh(String refreshToken, String userAgent) {
        String hash = Hashing.sha256(refreshToken);
        AuthSession session = sessions.findByRefreshTokenHash(hash)
                .orElseThrow(() -> new ApiException(ErrorCode.TOKEN_INVALID, "Unknown refresh token"));
        if (!session.isActive()) {
            throw new ApiException(ErrorCode.TOKEN_INVALID, "Refresh token expired or revoked");
        }
        // Rotate: revoke the presented token, issue a fresh pair (Vol2 §5).
        session.setRevokedAt(Instant.now());
        sessions.save(session);

        User user = users.findById(session.getUserId())
                .orElseThrow(() -> ApiException.notFound("User"));
        return issueTokens(user, userAgent);
    }

    @Transactional
    public void logout(String refreshToken) {
        sessions.findByRefreshTokenHash(Hashing.sha256(refreshToken)).ifPresent(s -> {
            s.setRevokedAt(Instant.now());
            sessions.save(s);
        });
    }

    private AuthDtos.TokenResponse issueTokens(User user, String userAgent) {
        String accessToken = jwtService.issueAccessToken(user.getId(), user.getMobile());

        String refreshRaw = Hashing.randomToken();
        AuthSession session = new AuthSession();
        session.setUserId(user.getId());
        session.setRefreshTokenHash(Hashing.sha256(refreshRaw));
        session.setExpiresAt(Instant.now().plusSeconds(props.getJwt().getRefreshTokenTtlSeconds()));
        session.setUserAgent(userAgent);
        sessions.save(session);

        return new AuthDtos.TokenResponse(accessToken, refreshRaw,
                props.getJwt().getAccessTokenTtlSeconds(), AuthDtos.AuthUserDto.from(user));
    }
}
