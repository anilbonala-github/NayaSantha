package com.nayasantha.api.plan;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface WeeklyPlanRepository extends JpaRepository<WeeklyPlan, UUID> {
    Optional<WeeklyPlan> findFirstByUserIdOrderByCreatedAtDesc(UUID userId);
}
