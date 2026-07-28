package com.nayasantha.api.subscription;

import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.notification.NotificationService;
import com.nayasantha.api.subscription.SubscriptionDtos.*;
import com.nayasantha.api.wallet.WalletService;
import com.nayasantha.api.wallet.WalletTransaction;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

/**
 * Membership subscriptions with recurring billing (Vol1 §9.1). Paid plans are
 * funded from the customer's wallet: month 1 on subscribe, then monthly on
 * renewal (scheduled job / admin trigger). A failed renewal goes PAST_DUE and
 * is retried; after {@link #MAX_FAILED} failures the membership EXPIRES.
 */
@Service
public class SubscriptionService {

    private static final int CYCLE_DAYS = 30;
    private static final int MAX_FAILED = 3;
    private static final DateTimeFormatter DATE =
            DateTimeFormatter.ofPattern("d MMM").withZone(ZoneId.of("Asia/Kolkata"));

    private final SubscriptionPlanRepository plans;
    private final SubscriptionRepository subs;
    private final SubscriptionPaymentRepository payments;
    private final WalletService wallet;
    private final NotificationService notifications;

    public SubscriptionService(SubscriptionPlanRepository plans, SubscriptionRepository subs,
                               SubscriptionPaymentRepository payments, WalletService wallet,
                               NotificationService notifications) {
        this.plans = plans;
        this.subs = subs;
        this.payments = payments;
        this.wallet = wallet;
        this.notifications = notifications;
    }

    @Transactional(readOnly = true)
    public List<PlanDto> listPlans() {
        return plans.findByActiveTrueOrderBySortOrderAsc().stream().map(PlanDto::from).toList();
    }

    /** The user's current membership (ACTIVE or PAST_DUE), or FREE-equivalent (null). */
    @Transactional(readOnly = true)
    public SubscriptionDto current(UUID userId) {
        return subs.findFirstByUserIdAndStatusInOrderByCreatedAtDesc(userId,
                        List.of(Subscription.Status.ACTIVE, Subscription.Status.PAST_DUE))
                .map(this::toDto).orElse(null);
    }

    /**
     * The enforced perks for a user. A PAST_DUE membership keeps its perks (grace
     * period); Basic / expired / none get {@link MemberPerks#BASIC}.
     */
    @Transactional(readOnly = true)
    public MemberPerks perksOf(UUID userId) {
        return subs.findFirstByUserIdAndStatusInOrderByCreatedAtDesc(userId,
                        List.of(Subscription.Status.ACTIVE, Subscription.Status.PAST_DUE))
                .flatMap(s -> plans.findById(s.getPlanId()))
                .map(p -> new MemberPerks(p.getCode(), p.isFreeDelivery(), p.isMemberOffers(), p.isPrioritySlot()))
                .orElse(MemberPerks.BASIC);
    }

    @Transactional
    public SubscriptionDto subscribe(UUID userId, String planCode) {
        SubscriptionPlan plan = plans.findByCode(planCode)
                .filter(SubscriptionPlan::isActive)
                .orElseThrow(() -> ApiException.userError("That plan isn't available."));

        // End any current membership first.
        subs.findFirstByUserIdAndStatusInOrderByCreatedAtDesc(userId,
                        List.of(Subscription.Status.ACTIVE, Subscription.Status.PAST_DUE))
                .ifPresent(s -> {
                    s.setStatus(Subscription.Status.CANCELLED);
                    s.setCancelledAt(Instant.now());
                    subs.save(s);
                });

        // The free plan just means "no active paid membership".
        if ("FREE".equalsIgnoreCase(planCode)) {
            return null;
        }

        Instant now = Instant.now();
        Instant periodEnd = now.plus(CYCLE_DAYS, ChronoUnit.DAYS);
        BigDecimal price = plan.getPricePerMonth();

        Subscription s = new Subscription();
        s.setUserId(userId);
        s.setPlanId(plan.getId());
        s.setStatus(Subscription.Status.ACTIVE);
        s.setStartedAt(now);
        s.setRenewsAt(periodEnd);

        // Charge the first month up front from the wallet.
        if (price.signum() > 0) {
            BigDecimal balance = wallet.balance(userId);
            if (balance.compareTo(price) < 0) {
                throw ApiException.userError(plan.getName() + " is " + money(price)
                        + "/month. Your wallet has " + money(balance) + " — top up to subscribe.");
            }
            wallet.post(userId, price.negate(), WalletTransaction.Type.SUBSCRIPTION,
                    plan.getName() + " membership", null);
            s.setLastBilledAt(now);
        }
        Subscription saved = subs.save(s);
        if (price.signum() > 0) {
            recordPayment(saved, plan, price, "PAID", "First month", now, periodEnd);
        }
        return toDto(saved);
    }

    @Transactional
    public void cancel(UUID userId) {
        subs.findFirstByUserIdAndStatusInOrderByCreatedAtDesc(userId,
                        List.of(Subscription.Status.ACTIVE, Subscription.Status.PAST_DUE))
                .ifPresent(s -> {
                    s.setStatus(Subscription.Status.CANCELLED);
                    s.setCancelledAt(Instant.now());
                    subs.save(s);
                });
    }

    @Transactional(readOnly = true)
    public List<PaymentDto> paymentHistory(UUID userId, int page, int size) {
        return payments.findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(page, Math.min(size, 50)))
                .getContent().stream()
                .map(p -> new PaymentDto(p.getId(), planCode(p.getPlanId()), p.getAmount(), p.getStatus(),
                        p.getReason(), p.getPeriodStart(), p.getPeriodEnd(), p.getCreatedAt()))
                .toList();
    }

    /**
     * Bill every membership due for renewal. Idempotent per due date: a PAST_DUE
     * membership is retried on each run until it succeeds or hits {@link #MAX_FAILED}.
     */
    @Transactional
    public RenewalResultDto renewDue() {
        Instant now = Instant.now();
        List<Subscription> due = subs.findByStatusInAndRenewsAtLessThanEqual(
                List.of(Subscription.Status.ACTIVE, Subscription.Status.PAST_DUE), now);
        int renewed = 0, pastDue = 0, expired = 0;
        BigDecimal charged = BigDecimal.ZERO;

        for (Subscription s : due) {
            SubscriptionPlan plan = plans.findById(s.getPlanId()).orElse(null);
            if (plan == null) continue;
            BigDecimal price = plan.getPricePerMonth();
            Instant periodStart = s.getRenewsAt() != null ? s.getRenewsAt() : now;
            Instant periodEnd = periodStart.plus(CYCLE_DAYS, ChronoUnit.DAYS);

            if (price.signum() <= 0) {   // free-priced membership: just roll the date
                s.setRenewsAt(periodEnd);
                subs.save(s);
                continue;
            }

            // Check the balance up front — never let an over-draw throw inside the
            // batch transaction (that would mark it rollback-only and fail every
            // other membership in the run).
            boolean paid = wallet.balance(s.getUserId()).compareTo(price) >= 0;
            if (paid) {
                wallet.post(s.getUserId(), price.negate(), WalletTransaction.Type.SUBSCRIPTION,
                        plan.getName() + " renewal", null);
            }

            if (paid) {
                recordPayment(s, plan, price, "PAID", "Renewal", periodStart, periodEnd);
                s.setStatus(Subscription.Status.ACTIVE);
                s.setRenewsAt(periodEnd);
                s.setLastBilledAt(now);
                s.setFailedAttempts(0);
                subs.save(s);
                charged = charged.add(price);
                renewed++;
                notifications.create(s.getUserId(), NotificationService.SUBSCRIPTION_RENEWED,
                        plan.getName() + " renewed",
                        money(price) + " charged from your wallet. Next renewal " + DATE.format(periodEnd) + ".",
                        null);
            } else {
                recordPayment(s, plan, price, "FAILED", "Insufficient wallet balance", periodStart, periodEnd);
                int fails = s.getFailedAttempts() + 1;
                s.setFailedAttempts(fails);
                if (fails >= MAX_FAILED) {
                    s.setStatus(Subscription.Status.EXPIRED);
                    subs.save(s);
                    expired++;
                    notifications.create(s.getUserId(), NotificationService.SUBSCRIPTION_ENDED,
                            plan.getName() + " membership ended",
                            "We couldn't renew after " + MAX_FAILED + " tries. You're on Basic now — resubscribe any time.",
                            null);
                } else {
                    s.setStatus(Subscription.Status.PAST_DUE);
                    subs.save(s);
                    pastDue++;
                    notifications.create(s.getUserId(), NotificationService.SUBSCRIPTION_PAST_DUE,
                            plan.getName() + " renewal failed",
                            "Top up your wallet with " + money(price) + " to keep " + plan.getName()
                                    + ". We'll retry automatically.",
                            null);
                }
            }
        }
        return new RenewalResultDto(due.size(), renewed, pastDue, expired, charged);
    }

    private void recordPayment(Subscription s, SubscriptionPlan plan, BigDecimal amount,
                               String status, String reason, Instant start, Instant end) {
        SubscriptionPayment p = new SubscriptionPayment();
        p.setSubscriptionId(s.getId());
        p.setUserId(s.getUserId());
        p.setPlanId(plan.getId());
        p.setAmount(amount);
        p.setStatus(status);
        p.setReason(reason);
        p.setPeriodStart(start);
        p.setPeriodEnd(end);
        payments.save(p);
    }

    private String planCode(UUID planId) {
        return plans.findById(planId).map(SubscriptionPlan::getCode).orElse(null);
    }

    private SubscriptionDto toDto(Subscription s) {
        SubscriptionPlan plan = plans.findById(s.getPlanId()).orElse(null);
        return new SubscriptionDto(s.getId(),
                plan == null ? null : plan.getCode(),
                plan == null ? null : plan.getName(),
                s.getStatus().name(), s.getBillingCycle(),
                plan == null ? null : plan.getPricePerMonth(),
                s.getStartedAt(), s.getRenewsAt(), s.getLastBilledAt());
    }

    private static String money(BigDecimal v) {
        return "₹" + (v == null ? "0" : v.stripTrailingZeros().toPlainString());
    }
}
