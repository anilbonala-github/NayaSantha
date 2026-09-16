package com.nayasantha.api.catalogue;

import com.nayasantha.api.common.ApiException;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;

/** Published selling prices; market purchase costs never enter this service. */
@Service
public class WeeklyPricingService {
    public static final String ZONE = "HYD_PILOT";
    public static final ZoneId TIME_ZONE = ZoneId.of("Asia/Kolkata");
    private final ProductPriceRepository prices;
    private final ProductRepository products;
    private final PriceCalendarRepository calendars;
    private final Clock clock;

    @org.springframework.beans.factory.annotation.Autowired
    public WeeklyPricingService(ProductPriceRepository prices, ProductRepository products,
                                PriceCalendarRepository calendars) {
        this(prices, products, calendars, Clock.systemUTC());
    }
    WeeklyPricingService(ProductPriceRepository prices, ProductRepository products,
                         PriceCalendarRepository calendars, Clock clock) {
        this.prices = prices; this.products = products; this.calendars = calendars; this.clock = clock;
    }

    public record Entry(@NotNull UUID productId,
                        @NotNull @DecimalMin("0.01") @Digits(integer=10, fraction=2) BigDecimal sellingPrice,
                        @DecimalMin("0.01") @Digits(integer=10, fraction=2) BigDecimal mrp) {}
    public record PublishRequest(@NotNull LocalDate weekStart,
                                 @NotEmpty @Size(max=1000) List<@NotNull @Valid Entry> prices) {}
    public record Published(LocalDate weekStart, Instant effectiveFrom, int productCount) {}

    @Transactional(readOnly = true)
    public Map<UUID, ProductPrice> current(List<UUID> ids) {
        if (ids.isEmpty()) return Map.of();
        Map<UUID, ProductPrice> result = new HashMap<>();
        for (ProductPrice price : prices.findEffectivePrices(ids, ZONE, clock.instant())) {
            result.putIfAbsent(price.getProductId(), price);
        }
        return result;
    }

    @Transactional(readOnly = true)
    public ProductPrice requireCurrent(UUID id) {
        ProductPrice price = current(List.of(id)).get(id);
        if (price == null) throw ApiException.userError("This item has no current selling price. Please remove it and try again.");
        return price;
    }

    /** Schedule a batch before its Monday 00:00 IST start. Unchanged products carry forward. */
    @Transactional
    public Published publish(UUID adminId, PublishRequest request) {
        LocalDate week = request.weekStart();
        if (week == null || week.getDayOfWeek() != DayOfWeek.MONDAY) {
            throw ApiException.userError("Choose a Monday for the pricing week.");
        }
        Instant start = week.atStartOfDay(TIME_ZONE).toInstant();
        if (!start.isAfter(clock.instant())) {
            throw ApiException.userError("Publish prices before the week starts. Current-week prices are already fixed.");
        }
        PriceCalendar calendar = calendars.lockCalendar(ZONE)
                .orElseThrow(() -> ApiException.userError("Pricing calendar is not configured."));
        if (calendar.getLastPublishedWeek() != null && !week.isAfter(calendar.getLastPublishedWeek())) {
            throw ApiException.userError("This week is already published or precedes a scheduled week.");
        }
        if (request.prices() == null || request.prices().isEmpty()) {
            throw ApiException.userError("Add at least one selling price.");
        }
        Set<UUID> ids = new HashSet<>();
        for (Entry entry : request.prices()) {
            if (entry.productId() == null || !ids.add(entry.productId())) {
                throw ApiException.userError("Each product must appear exactly once.");
            }
            if (entry.sellingPrice() == null || entry.sellingPrice().signum() <= 0
                    || entry.sellingPrice().scale() > 2
                    || (entry.mrp() != null && entry.mrp().compareTo(entry.sellingPrice()) < 0)) {
                throw ApiException.userError("Use a positive price with at most two decimals, no higher than MRP.");
            }
        }
        List<Product> selected = products.findAllById(ids);
        if (selected.size() != ids.size() || selected.stream().anyMatch(p -> !p.isActive())) {
            throw ApiException.userError("Only active catalogue products can be priced.");
        }
        // The calendar row serializes publishers, including simultaneous requests for the same week.
        for (ProductPrice old : prices.findByProductIdInAndZoneAndActiveTrue(new ArrayList<>(ids), ZONE)) {
            if (!old.getEffectiveFrom().isBefore(start)) {
                throw ApiException.userError("A later price is already scheduled for this product.");
            }
            if (old.getEffectiveTo() == null || old.getEffectiveTo().isAfter(start)) {
                old.setEffectiveTo(start);
                prices.save(old);
            }
        }
        for (Entry entry : request.prices()) {
            ProductPrice price = new ProductPrice();
            price.setProductId(entry.productId()); price.setZone(ZONE);
            price.setSellingPrice(entry.sellingPrice()); price.setMrp(entry.mrp());
            // Compatibility fields carry the same fixed selling price.
            price.setForecastPrice(entry.sellingPrice()); price.setMaxPrice(entry.sellingPrice());
            price.setEffectiveFrom(start); price.setPriceWeekStart(week); price.setPublishedBy(adminId);
            prices.save(price);
        }
        calendar.setLastPublishedWeek(week);
        calendars.save(calendar);
        return new Published(week, start, ids.size());
    }
}
