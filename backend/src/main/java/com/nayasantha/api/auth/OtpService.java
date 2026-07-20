package com.nayasantha.api.auth;

import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.common.ErrorCode;
import com.nayasantha.api.config.AppProperties;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

/**
 * OTP request + verification. Currently dev-stubbed (no SMS provider): in dev
 * mode the configured {@code dev-code} always verifies. The OTP result still
 * comes from the backend, per Vol2 §6.1 acceptance criteria.
 */
@Service
public class OtpService {

    private final OtpChallengeRepository challenges;
    private final AppProperties props;

    public OtpService(OtpChallengeRepository challenges, AppProperties props) {
        this.challenges = challenges;
        this.props = props;
    }

    @Transactional
    public AuthDtos.OtpRequestResult request(String mobile) {
        AppProperties.Otp cfg = props.getOtp();
        String code = cfg.isDevMode() ? cfg.getDevCode() : generateCode(cfg.getLength());

        OtpChallenge challenge = new OtpChallenge();
        challenge.setMobile(mobile);
        challenge.setCodeHash(Hashing.sha256(code));
        challenge.setExpiresAt(Instant.now().plusSeconds(cfg.getTtlSeconds()));
        challenges.save(challenge);

        // TODO: send `code` via SMS provider once wired. Never return it in prod.
        String devHint = cfg.isDevMode() ? "Dev mode: use code " + code : null;
        return new AuthDtos.OtpRequestResult(mobile, cfg.isDevMode(), devHint);
    }

    @Transactional
    public void verify(String mobile, String code) {
        OtpChallenge challenge = challenges.findFirstByMobileOrderByCreatedAtDesc(mobile)
                .orElseThrow(() -> new ApiException(ErrorCode.OTP_INVALID, "No OTP requested for " + mobile));

        if (!challenge.isUsable()) {
            throw new ApiException(ErrorCode.OTP_INVALID, "OTP expired or already used");
        }
        challenge.setAttempts(challenge.getAttempts() + 1);
        if (!challenge.getCodeHash().equals(Hashing.sha256(code))) {
            challenges.save(challenge);
            throw new ApiException(ErrorCode.OTP_INVALID, "OTP code mismatch");
        }
        challenge.setConsumedAt(Instant.now());
        challenges.save(challenge);
    }

    private String generateCode(int length) {
        int bound = (int) Math.pow(10, length);
        return String.format("%0" + length + "d", new java.security.SecureRandom().nextInt(bound));
    }
}
