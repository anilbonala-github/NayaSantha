package com.nayasantha.api.subscription;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

interface SubscriptionPlanRepository extends JpaRepository<SubscriptionPlan, UUID> {
    List<SubscriptionPlan> findByActiveTrueOrderBySortOrderAsc();
    Optional<SubscriptionPlan> findByCode(String code);
}

interface SubscriptionRepository extends JpaRepository<Subscription, UUID> {
    Optional<Subscription> findFirstByUserIdAndStatusOrderByCreatedAtDesc(UUID userId, Subscription.Status status);
}
