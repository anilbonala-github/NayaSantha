package com.nayasantha.api.catalogue;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;

/** One lockable publication calendar per delivery zone. */
@Entity @Table(name = "price_calendars") @Getter @Setter
public class PriceCalendar {
    @Id private String zone;
    @Column(name = "last_published_week") private LocalDate lastPublishedWeek;
}
