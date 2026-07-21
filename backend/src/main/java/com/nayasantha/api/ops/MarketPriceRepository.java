package com.nayasantha.api.ops;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MarketPriceRepository extends JpaRepository<MarketPrice, UUID> {
    List<MarketPrice> findByWeekStart(LocalDate weekStart);
    Optional<MarketPrice> findByProductIdAndWeekStart(UUID productId, LocalDate weekStart);
}
