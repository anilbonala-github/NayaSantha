package com.nayasantha.api.plan;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface WeeklyPlanItemRepository extends JpaRepository<WeeklyPlanItem, UUID> {
    List<WeeklyPlanItem> findByPlanId(UUID planId);
}
