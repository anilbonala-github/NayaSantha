package com.nayasantha.api.referral;

import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.common.ErrorCode;
import com.nayasantha.api.notification.NotificationService;
import com.nayasantha.api.referral.ReferralDtos.*;
import com.nayasantha.api.user.User;
import com.nayasantha.api.user.UserRepository;
import com.nayasantha.api.wallet.WalletService;
import com.nayasantha.api.wallet.WalletTransaction;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.security.SecureRandom;
import java.util.UUID;

/** Referral codes + apply, with the bonus credited to both wallets. */
@Service
public class ReferralService {

    /** Bonus each side earns when a referral is applied. */
    static final BigDecimal BONUS = new BigDecimal("50");
    private static final String ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no confusing chars
    private static final SecureRandom RNG = new SecureRandom();

    private final UserRepository users;
    private final ReferralRepository referrals;
    private final WalletService wallet;
    private final NotificationService notifications;

    public ReferralService(UserRepository users, ReferralRepository referrals,
                           WalletService wallet, NotificationService notifications) {
        this.users = users;
        this.referrals = referrals;
        this.wallet = wallet;
        this.notifications = notifications;
    }

    /** The user's code (generated on first access) + their referral stats. */
    @Transactional
    public ReferralCodeDto myCode(UUID userId) {
        User u = users.findById(userId).orElseThrow(() -> ApiException.notFound("User"));
        if (u.getReferralCode() == null || u.getReferralCode().isBlank()) {
            u.setReferralCode(generateUniqueCode());
            u = users.save(u);
        }
        long count = referrals.countByReferrerUserId(userId);
        return new ReferralCodeDto(u.getReferralCode(), count,
                BONUS.multiply(BigDecimal.valueOf(count)), BONUS);
    }

    @Transactional
    public ApplyResultDto apply(UUID userId, String code) {
        if (referrals.existsByRefereeUserId(userId)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "You've already used a referral code");
        }
        User referrer = users.findByReferralCode(code.trim().toUpperCase())
                .orElseThrow(() -> new ApiException(ErrorCode.VALIDATION_ERROR, "Invalid referral code"));
        if (referrer.getId().equals(userId)) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "You can't use your own code");
        }

        wallet.credit(userId, BONUS, WalletTransaction.Type.REFERRAL, "Welcome referral bonus", null);
        wallet.credit(referrer.getId(), BONUS, WalletTransaction.Type.REFERRAL, "A friend joined with your code", null);

        Referral r = new Referral();
        r.setReferrerUserId(referrer.getId());
        r.setRefereeUserId(userId);
        r.setCode(referrer.getReferralCode());
        r.setBonusAmount(BONUS);
        referrals.save(r);

        notifications.create(referrer.getId(), NotificationService.REFERRAL_EARNED,
                "You earned a referral bonus",
                "A friend joined with your code — ₹" + BONUS.toBigInteger()
                        + " has been credited to your wallet.", null);

        return new ApplyResultDto(BONUS, wallet.balance(userId));
    }

    private String generateUniqueCode() {
        for (int attempt = 0; attempt < 20; attempt++) {
            StringBuilder sb = new StringBuilder("NS");
            for (int i = 0; i < 6; i++) sb.append(ALPHABET.charAt(RNG.nextInt(ALPHABET.length())));
            String code = sb.toString();
            if (!users.existsByReferralCode(code)) return code;
        }
        throw new ApiException(ErrorCode.INTERNAL_ERROR, "Could not generate a referral code");
    }
}
