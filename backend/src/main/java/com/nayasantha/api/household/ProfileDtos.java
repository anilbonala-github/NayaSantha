package com.nayasantha.api.household;

import com.nayasantha.api.user.User;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/** DTOs for profile, household and household-member endpoints (Vol2 §6.12). */
public final class ProfileDtos {

    private ProfileDtos() {}

    public record ProfileDto(UUID id, String mobile, String name, String email,
                             String profileCompletionStatus) {
        static ProfileDto from(User u) {
            return new ProfileDto(u.getId(), u.getMobile(), u.getName(), u.getEmail(),
                    u.getProfileCompletionStatus().name());
        }
    }

    public record UpdateProfileRequest(String name, @Email String email) {}

    public record HouseholdDto(UUID id, BigDecimal weeklyBudget, String language,
                               String defaultPriceConsent, Long version,
                               List<MemberDto> members) {}

    public record UpdateHouseholdRequest(
            @PositiveOrZero BigDecimal weeklyBudget, String language,
            String defaultPriceConsent, Long version) {}

    public record MemberDto(UUID id, String name, Integer age, String dietaryType,
                            String allergies, String nutritionNotes, Long version) {
        static MemberDto from(HouseholdMember m) {
            return new MemberDto(m.getId(), m.getName(), m.getAge(), m.getDietaryType().name(),
                    m.getAllergies(), m.getNutritionNotes(), m.getVersion());
        }
    }

    public record UpsertMemberRequest(String name, @Min(0) Integer age, String dietaryType,
                                      String allergies, String nutritionNotes, Long version) {}
}
