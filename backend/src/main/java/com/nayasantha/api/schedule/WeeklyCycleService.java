package com.nayasantha.api.schedule;

import com.nayasantha.api.notification.NotificationService;
import com.nayasantha.api.order.OrderService;
import com.nayasantha.api.plan.WeeklyPlan;
import com.nayasantha.api.plan.WeeklyPlanRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.TemporalAdjusters;
import java.util.List;

/**
 * The weekly operating calendar (Vol2A §2): Saturday 8 PM reminder to
 * un-approved households and the Saturday 10 PM order cutoff that locks
 * confirmed orders for Sunday procurement. Invoked by the cron scheduler
 * and by the ADMIN manual-trigger endpoints (so ops can run them even if a
 * sleeping instance misses the cron).
 */
@Service
public class WeeklyCycleService {

    static final ZoneId IST = ZoneId.of("Asia/Kolkata");

    private final WeeklyPlanRepository plans;
    private final NotificationService notifications;
    private final OrderService orders;

    public WeeklyCycleService(WeeklyPlanRepository plans, NotificationService notifications,
                              OrderService orders) {
        this.plans = plans;
        this.notifications = notifications;
        this.orders = orders;
    }

    static LocalDate currentWeekStart() {
        return LocalDate.now(IST).with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
    }

    /** Nudge households whose plan for this week is still a draft (not approved). */
    @Transactional
    public int sendCutoffReminders() {
        List<WeeklyPlan> drafts = plans.findByStatusAndWeekStart(WeeklyPlan.Status.DRAFT, currentWeekStart());
        for (WeeklyPlan p : drafts) {
            notifications.create(p.getUserId(), NotificationService.CUTOFF_REMINDER,
                    "Your weekly basket is ready",
                    "Approve your plan before Saturday 10 PM to get fresh Sunday delivery.", null);
        }
        return drafts.size();
    }

    /** Lock every confirmed order at cutoff. */
    @Transactional
    public int runCutoff() {
        return orders.lockAllConfirmed();
    }
}
