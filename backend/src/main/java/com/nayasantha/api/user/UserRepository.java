package com.nayasantha.api.user;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByMobile(String mobile);
    Optional<User> findByReferralCode(String referralCode);
    boolean existsByReferralCode(String referralCode);
    boolean existsByMobile(String mobile);
}
