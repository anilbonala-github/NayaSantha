package com.nayasantha.api.household;

import com.nayasantha.api.common.ApiResponse;
import com.nayasantha.api.household.ProfileDtos.*;
import com.nayasantha.api.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/** Profile, household and member endpoints for the signed-in customer (Vol2 §6.12, §7). */
@RestController
@RequestMapping("/api/v1")
public class ProfileController {

    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping("/profile")
    public ApiResponse<ProfileDto> getProfile() {
        return ApiResponse.of(profileService.getProfile(CurrentUser.id()));
    }

    @PatchMapping("/profile")
    public ApiResponse<ProfileDto> updateProfile(@Valid @RequestBody UpdateProfileRequest body) {
        return ApiResponse.of(profileService.updateProfile(CurrentUser.id(), body));
    }

    /** Marks onboarding complete (Vol2 §6.1 profileCompletionStatus). */
    @PostMapping("/profile/complete")
    public ApiResponse<ProfileDto> completeOnboarding() {
        return ApiResponse.of(profileService.completeOnboarding(CurrentUser.id()));
    }

    @GetMapping("/households/current")
    public ApiResponse<HouseholdDto> getHousehold() {
        return ApiResponse.of(profileService.getCurrentHousehold(CurrentUser.id()));
    }

    @PatchMapping("/households/current")
    public ApiResponse<HouseholdDto> updateHousehold(@Valid @RequestBody UpdateHouseholdRequest body) {
        return ApiResponse.of(profileService.updateHousehold(CurrentUser.id(), body));
    }

    @PostMapping("/household-members")
    public ApiResponse<MemberDto> addMember(@Valid @RequestBody UpsertMemberRequest body) {
        return ApiResponse.of(profileService.addMember(CurrentUser.id(), body));
    }

    @PatchMapping("/household-members/{id}")
    public ApiResponse<MemberDto> updateMember(@PathVariable UUID id,
                                               @Valid @RequestBody UpsertMemberRequest body) {
        return ApiResponse.of(profileService.updateMember(CurrentUser.id(), id, body));
    }

    @DeleteMapping("/household-members/{id}")
    public ApiResponse<String> deleteMember(@PathVariable UUID id) {
        profileService.deleteMember(CurrentUser.id(), id);
        return ApiResponse.of("ok");
    }
}
