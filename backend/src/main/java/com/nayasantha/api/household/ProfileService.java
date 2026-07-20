package com.nayasantha.api.household;

import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.household.ProfileDtos.*;
import com.nayasantha.api.user.User;
import com.nayasantha.api.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Profile, household and member reads/writes for the current user (Vol2 §6.12). */
@Service
public class ProfileService {

    private final UserRepository users;
    private final HouseholdRepository households;
    private final HouseholdMemberRepository members;

    public ProfileService(UserRepository users, HouseholdRepository households,
                          HouseholdMemberRepository members) {
        this.users = users;
        this.households = households;
        this.members = members;
    }

    @Transactional(readOnly = true)
    public ProfileDto getProfile(UUID userId) {
        return ProfileDto.from(loadUser(userId));
    }

    @Transactional
    public ProfileDto updateProfile(UUID userId, UpdateProfileRequest req) {
        User u = loadUser(userId);
        if (req.name() != null) u.setName(req.name());
        if (req.email() != null) u.setEmail(req.email());
        return ProfileDto.from(users.save(u));
    }

    /** Returns the current household, creating an empty one on first access. */
    @Transactional
    public HouseholdDto getCurrentHousehold(UUID userId) {
        Household h = households.findByOwnerUserId(userId).orElseGet(() -> {
            Household created = new Household();
            created.setOwnerUserId(userId);
            return households.save(created);
        });
        return toDto(h);
    }

    @Transactional
    public HouseholdDto updateHousehold(UUID userId, UpdateHouseholdRequest req) {
        Household h = households.findByOwnerUserId(userId)
                .orElseThrow(() -> ApiException.notFound("Household"));
        applyOptimisticVersion(h.getVersion(), req.version());
        if (req.weeklyBudget() != null) h.setWeeklyBudget(req.weeklyBudget());
        if (req.language() != null) h.setLanguage(req.language());
        if (req.defaultPriceConsent() != null) {
            h.setDefaultPriceConsent(Household.PriceConsent.valueOf(req.defaultPriceConsent()));
        }
        return toDto(households.save(h));
    }

    @Transactional
    public MemberDto addMember(UUID userId, UpsertMemberRequest req) {
        Household h = requireHousehold(userId);
        HouseholdMember m = new HouseholdMember();
        m.setHouseholdId(h.getId());
        applyMember(m, req);
        // Preferences affect the next plan generation (Vol2 §6.12 acceptance).
        markOnboarding(userId);
        return MemberDto.from(members.save(m));
    }

    @Transactional
    public MemberDto updateMember(UUID userId, UUID memberId, UpsertMemberRequest req) {
        Household h = requireHousehold(userId);
        HouseholdMember m = members.findById(memberId)
                .filter(x -> x.getHouseholdId().equals(h.getId()))
                .orElseThrow(() -> ApiException.notFound("Member"));
        applyOptimisticVersion(m.getVersion(), req.version());
        applyMember(m, req);
        return MemberDto.from(members.save(m));
    }

    @Transactional
    public void deleteMember(UUID userId, UUID memberId) {
        Household h = requireHousehold(userId);
        HouseholdMember m = members.findById(memberId)
                .filter(x -> x.getHouseholdId().equals(h.getId()))
                .orElseThrow(() -> ApiException.notFound("Member"));
        members.delete(m);
    }

    // --- helpers -----------------------------------------------------------
    private User loadUser(UUID userId) {
        return users.findById(userId).orElseThrow(() -> ApiException.notFound("User"));
    }

    private Household requireHousehold(UUID userId) {
        return households.findByOwnerUserId(userId)
                .orElseThrow(() -> ApiException.notFound("Household"));
    }

    private void markOnboarding(UUID userId) {
        User u = loadUser(userId);
        if (u.getProfileCompletionStatus() == User.ProfileCompletionStatus.NEW) {
            u.setProfileCompletionStatus(User.ProfileCompletionStatus.ONBOARDING);
            users.save(u);
        }
    }

    private void applyMember(HouseholdMember m, UpsertMemberRequest req) {
        if (req.name() != null) m.setName(req.name());
        if (req.age() != null) m.setAge(req.age());
        if (req.dietaryType() != null) m.setDietaryType(HouseholdMember.DietaryType.valueOf(req.dietaryType()));
        if (req.allergies() != null) m.setAllergies(req.allergies());
        if (req.nutritionNotes() != null) m.setNutritionNotes(req.nutritionNotes());
    }

    /** Optimistic-lock pre-check so we return VERSION_CONFLICT (Vol2 §5.1) cleanly. */
    private void applyOptimisticVersion(Long current, Long expected) {
        if (expected != null && !expected.equals(current)) {
            throw new org.springframework.orm.ObjectOptimisticLockingFailureException(
                    "expected version " + current + " but received " + expected, null);
        }
    }

    private HouseholdDto toDto(Household h) {
        List<MemberDto> memberDtos = members.findByHouseholdId(h.getId()).stream()
                .map(MemberDto::from).toList();
        return new HouseholdDto(h.getId(), h.getWeeklyBudget(), h.getLanguage(),
                h.getDefaultPriceConsent().name(), h.getVersion(), memberDtos);
    }
}
