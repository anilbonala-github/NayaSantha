package com.nayasantha.api.schedule;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Cron triggers for the weekly calendar (Asia/Kolkata). Only active when
 * {@code nayasantha.scheduler.enabled=true} — keep it off wherever multiple
 * instances run, or on a host that sleeps (use the ADMIN manual triggers there).
 */
@Component
@ConditionalOnProperty(name = "nayasantha.scheduler.enabled", havingValue = "true")
public class WeeklyCycleScheduler {

    private static final Logger log = LoggerFactory.getLogger(WeeklyCycleScheduler.class);

    private final WeeklyCycleService cycle;
    private final com.nayasantha.api.subscription.SubscriptionService subscriptions;

    public WeeklyCycleScheduler(WeeklyCycleService cycle,
                                com.nayasantha.api.subscription.SubscriptionService subscriptions) {
        this.cycle = cycle;
        this.subscriptions = subscriptions;
    }

    /** Saturday 8:00 PM IST — remind households that haven't approved. */
    @Scheduled(cron = "0 0 20 * * SAT", zone = "Asia/Kolkata")
    public void saturdayReminder() {
        log.info("[cycle] Saturday reminder: notified {} household(s)", cycle.sendCutoffReminders());
    }

    /** Saturday 10:00 PM IST — lock confirmed orders for Sunday procurement. */
    @Scheduled(cron = "0 0 22 * * SAT", zone = "Asia/Kolkata")
    public void saturdayCutoff() {
        log.info("[cycle] Saturday cutoff: locked {} order(s)", cycle.runCutoff());
    }

    /** Daily 6:00 AM IST — bill memberships due for renewal from the wallet. */
    @Scheduled(cron = "0 0 6 * * *", zone = "Asia/Kolkata")
    public void dailySubscriptionBilling() {
        var r = subscriptions.renewDue();
        log.info("[cycle] Subscription billing: processed={} renewed={} pastDue={} expired={}",
                r.processed(), r.renewed(), r.pastDue(), r.expired());
    }
}
