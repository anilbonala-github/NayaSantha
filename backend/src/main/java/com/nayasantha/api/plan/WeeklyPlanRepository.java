package com.nayasantha.api.plan;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface WeeklyPlanRepository extends JpaRepository<WeeklyPlan, UUID> {
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select p from WeeklyPlan p where p.id = :id")
    Optional<WeeklyPlan> lockById(@org.springframework.data.repository.query.Param("id") UUID id);

    Optional<WeeklyPlan> findFirstByUserIdOrderByCreatedAtDesc(UUID userId);
    java.util.List<WeeklyPlan> findByStatusAndWeekStart(WeeklyPlan.Status status, java.time.LocalDate weekStart);
}
