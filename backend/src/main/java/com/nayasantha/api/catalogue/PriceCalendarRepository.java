package com.nayasantha.api.catalogue;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface PriceCalendarRepository extends JpaRepository<PriceCalendar, String> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select c from PriceCalendar c where c.zone = :zone")
    Optional<PriceCalendar> lockCalendar(@Param("zone") String zone);
}
