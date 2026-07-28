package com.nayasantha.api.subscription;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

interface SubscriptionPlanRepository extends JpaRepository<SubscriptionPlan, UUID> {
    List<SubscriptionPlan> findByActiveTrueOrderBySortOrderAsc();
    Optional<SubscriptionPlan> findByCode(String code);
}

interface SubscriptionRepository extends JpaRepository<Subscription, UUID> {
    Optional<Subscription> findFirstByUserIdAndStatusOrderByCreatedAtDesc(UUID userId, Subscription.Status status);
    Optional<Subscription> findFirstByUserIdAndStatusInOrderByCreatedAtDesc(
            UUID userId, List<Subscription.Status> statuses);
    /** Memberships due for billing: still billable and past their renewal date. */
    List<Subscription> findByStatusInAndRenewsAtLessThanEqual(List<Subscription.Status> statuses, Instant when);
}

interface SubscriptionPaymentRepository extends JpaRepository<SubscriptionPayment, UUID> {
    Page<SubscriptionPayment> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);
}
