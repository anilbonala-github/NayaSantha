package com.nayasantha.api.household;

import com.nayasantha.api.address.Address;
import com.nayasantha.api.address.AddressRepository;
import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.user.User;
import com.nayasantha.api.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ProfileServiceTest {
    private final UserRepository users = mock(UserRepository.class);
    private final HouseholdRepository households = mock(HouseholdRepository.class);
    private final HouseholdMemberRepository members = mock(HouseholdMemberRepository.class);
    private final AddressRepository addresses = mock(AddressRepository.class);
    private final ProfileService service = new ProfileService(users, households, members, addresses);
    private final UUID userId = UUID.randomUUID();
    private User user;
    private Household household;
    private HouseholdMember member;
    private Address address;

    @BeforeEach
    void setUp() {
        user = new User();
        user.setId(userId);
        user.setName("Test household");
        user.setMobile("9000000000");
        user.setProfileCompletionStatus(User.ProfileCompletionStatus.ONBOARDING);
        household = new Household();
        household.setId(UUID.randomUUID());
        household.setOwnerUserId(userId);
        household.setWeeklyBudget(new BigDecimal("1500"));
        member = new HouseholdMember();
        member.setId(UUID.randomUUID());
        member.setHouseholdId(household.getId());
        member.setDietaryType(HouseholdMember.DietaryType.VEG);
        member.setVersion(1L);
        address = new Address();
        address.setUserId(userId);
        address.setDefault(true);
        address.setServiceable(true);
        when(users.findById(userId)).thenReturn(Optional.of(user));
        when(users.save(any())).thenAnswer(i -> i.getArgument(0));
        when(households.findByOwnerUserId(userId)).thenReturn(Optional.of(household));
        when(members.findByHouseholdId(household.getId())).thenReturn(List.of(member));
        when(addresses.findByUserIdOrderByIsDefaultDescCreatedAtDesc(userId)).thenReturn(List.of(address));
    }

    @Test
    void validHouseholdCompletesWithoutPantryItems() {
        assertEquals("COMPLETE", service.completeOnboarding(userId).profileCompletionStatus());
        verify(users).save(user);
    }

    @Test
    void missingNameCannotComplete() {
        user.setName(" ");
        assertIncomplete("name");
    }

    @Test
    void missingHouseholdCannotComplete() {
        when(households.findByOwnerUserId(userId)).thenReturn(Optional.empty());
        assertIncomplete("household");
    }

    @Test
    void emptyHouseholdCannotComplete() {
        when(members.findByHouseholdId(household.getId())).thenReturn(List.of());
        assertIncomplete("member");
    }

    @Test
    void zeroBudgetCannotComplete() {
        household.setWeeklyBudget(BigDecimal.ZERO);
        assertIncomplete("budget");
    }

    @Test
    void noAddressCannotComplete() {
        when(addresses.findByUserIdOrderByIsDefaultDescCreatedAtDesc(userId)).thenReturn(List.of());
        assertIncomplete("address");
    }

    @Test
    void unserviceableDefaultCannotComplete() {
        address.setServiceable(false);
        assertIncomplete("address");
    }

    @Test
    void unselectedAddressCannotComplete() {
        address.setDefault(false);
        assertIncomplete("address");
    }

    @Test
    void memberEditCanClearAllergiesAndOptionalAge() {
        member.setAge(30);
        member.setAllergies("Peanut");
        when(members.findById(member.getId())).thenReturn(Optional.of(member));
        when(members.save(any())).thenAnswer(i -> i.getArgument(0));
        var updated = service.updateMember(userId, member.getId(),
                new ProfileDtos.UpsertMemberRequest("Updated", null, "VEG", "", null, 1L, true));
        assertEquals(member.getId(), updated.id());
        assertNull(updated.age());
        assertEquals("", updated.allergies());
        verify(members).save(member);
    }

    @Test
    void memberFromAnotherHouseholdCannotBeEdited() {
        member.setHouseholdId(UUID.randomUUID());
        when(members.findById(member.getId())).thenReturn(Optional.of(member));
        assertThrows(ApiException.class, () -> service.updateMember(userId, member.getId(),
                new ProfileDtos.UpsertMemberRequest("Wrong", null, "VEG", "", null, 1L, false)));
        verify(members, never()).save(any());
    }

    private void assertIncomplete(String expectedMessage) {
        var error = assertThrows(ApiException.class, () -> service.completeOnboarding(userId));
        assertTrue(error.getUserMessage().contains(expectedMessage));
        assertEquals(User.ProfileCompletionStatus.ONBOARDING, user.getProfileCompletionStatus());
        verify(users, never()).save(any());
    }
}
