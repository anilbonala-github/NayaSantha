package com.nayasantha.api.subscription;

import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.common.ErrorCode;
import com.nayasantha.api.subscription.SubscriptionDtos.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

/**
 * Membership subscriptions (Vol1 §9.1). Recurring billing is not charged yet —
 * subscribing records an ACTIVE membership; a real gateway mandate is a follow-up.
 */
@Service
public class SubscriptionService {

    private final SubscriptionPlanRepository plans;
    private final SubscriptionRepository subs;

    public SubscriptionService(SubscriptionPlanRepository plans, SubscriptionRepository subs) {
        this.plans = plans;
        this.subs = subs;
    }

    @Transactional(readOnly = true)
    public List<PlanDto> listPlans() {
        return plans.findByActiveTrueOrderBySortOrderAsc().stream().map(PlanDto::from).toList();
    }

    /** The user's current membership, or FREE-equivalent (null) when none active. */
    @Transactional(readOnly = true)
    public SubscriptionDto current(UUID userId) {
        return subs.findFirstByUserIdAndStatusOrderByCreatedAtDesc(userId, Subscription.Status.ACTIVE)
                .map(this::toDto).orElse(null);
    }

    @Transactional
    public SubscriptionDto subscribe(UUID userId, String planCode) {
        SubscriptionPlan plan = plans.findByCode(planCode)
                .filter(SubscriptionPlan::isActive)
                .orElseThrow(() -> new ApiException(ErrorCode.VALIDATION_ERROR, "Unknown plan"));

        // Cancel any current active membership first.
        subs.findFirstByUserIdAndStatusOrderByCreatedAtDesc(userId, Subscription.Status.ACTIVE)
                .ifPresent(s -> {
                    s.setStatus(Subscription.Status.CANCELLED);
                    s.setCancelledAt(Instant.now());
                    subs.save(s);
                });

        // The free plan just means "no active paid membership".
        if ("FREE".equalsIgnoreCase(planCode)) {
            return null;
        }

        Subscription s = new Subscription();
        s.setUserId(userId);
        s.setPlanId(plan.getId());
        s.setStatus(Subscription.Status.ACTIVE);
        s.setStartedAt(Instant.now());
        s.setRenewsAt(Instant.now().plus(30, ChronoUnit.DAYS));
        return toDto(subs.save(s));
    }

    @Transactional
    public void cancel(UUID userId) {
        subs.findFirstByUserIdAndStatusOrderByCreatedAtDesc(userId, Subscription.Status.ACTIVE)
                .ifPresent(s -> {
                    s.setStatus(Subscription.Status.CANCELLED);
                    s.setCancelledAt(Instant.now());
                    subs.save(s);
                });
    }

    private SubscriptionDto toDto(Subscription s) {
        SubscriptionPlan plan = plans.findById(s.getPlanId()).orElse(null);
        return new SubscriptionDto(s.getId(),
                plan == null ? null : plan.getCode(),
                plan == null ? null : plan.getName(),
                s.getStatus().name(), s.getBillingCycle(), s.getStartedAt(), s.getRenewsAt());
    }
}
