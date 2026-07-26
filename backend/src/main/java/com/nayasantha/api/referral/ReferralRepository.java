package com.nayasantha.api.referral;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ReferralRepository extends JpaRepository<Referral, UUID> {
    boolean existsByRefereeUserId(UUID refereeUserId);
    long countByReferrerUserId(UUID referrerUserId);
}
