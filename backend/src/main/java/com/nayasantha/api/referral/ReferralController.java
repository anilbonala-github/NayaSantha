package com.nayasantha.api.referral;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.referral.ReferralDtos.*;
import com.nayasantha.api.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

/** Referral code + apply (Vol2 §6 referral module). */
@RestController
@RequestMapping("/api/v1/referrals")
public class ReferralController {

    private final ReferralService referrals;

    public ReferralController(ReferralService referrals) {
        this.referrals = referrals;
    }

    @GetMapping("/code")
    public ApiResponse<ReferralCodeDto> myCode() {
        return ApiResponse.of(referrals.myCode(CurrentUser.id()));
    }

    @PostMapping("/apply")
    public ApiResponse<ApplyResultDto> apply(@Valid @RequestBody ApplyRequest body) {
        return ApiResponse.of(referrals.apply(CurrentUser.id(), body.code()));
    }
}
