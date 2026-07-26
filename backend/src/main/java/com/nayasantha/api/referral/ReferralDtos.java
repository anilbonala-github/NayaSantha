package com.nayasantha.api.referral;

import jakarta.validation.constraints.NotBlank;

import java.math.BigDecimal;

public final class ReferralDtos {

    private ReferralDtos() {}

    public record ReferralCodeDto(String code, long referredCount,
                                  BigDecimal totalEarned, BigDecimal bonusPerReferral) {}

    public record ApplyRequest(@NotBlank String code) {}

    public record ApplyResultDto(BigDecimal bonus, BigDecimal walletBalance) {}
}
