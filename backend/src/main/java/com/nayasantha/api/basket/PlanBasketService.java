package com.nayasantha.api.basket;

import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.plan.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
public class PlanBasketService {
    private final WeeklyPlanRepository plans;
    private final WeeklyPlanItemRepository items;
    private final BasketService baskets;
    public PlanBasketService(WeeklyPlanRepository plans, WeeklyPlanItemRepository items, BasketService baskets) {
        this.plans=plans; this.items=items; this.baskets=baskets;
    }
    @Transactional
    public BasketDtos.BasketDto add(UUID user, UUID planId) {
        WeeklyPlan plan = plans.lockById(planId).filter(p -> user.equals(p.getUserId()))
                .orElseThrow(() -> ApiException.notFound("Plan"));
        if (plan.getStatus() == WeeklyPlan.Status.APPROVED) return baskets.getCurrent(user);
        if (plan.getStatus() != WeeklyPlan.Status.DRAFT) throw ApiException.userError("Generate a new plan to add items.");
        var lines = items.findByPlanId(planId);
        if (lines.isEmpty()) throw ApiException.userError("This plan has no items.");
        for (var line : lines) baskets.addItem(user, line.getProductId(), line.getQuantity());
        plan.setStatus(WeeklyPlan.Status.APPROVED); plans.save(plan);
        return baskets.getCurrent(user);
    }
}
