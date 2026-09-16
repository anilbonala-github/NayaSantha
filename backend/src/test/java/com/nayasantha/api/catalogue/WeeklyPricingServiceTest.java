package com.nayasantha.api.catalogue;

import com.nayasantha.api.common.ApiException;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class WeeklyPricingServiceTest {
    private final ProductPriceRepository prices = mock(ProductPriceRepository.class);
    private final ProductRepository products = mock(ProductRepository.class);
    private final PriceCalendarRepository calendars = mock(PriceCalendarRepository.class);
    private final Instant now = Instant.parse("2026-09-16T10:00:00Z");
    private final WeeklyPricingService service = new WeeklyPricingService(prices, products, calendars,
            Clock.fixed(now, ZoneOffset.UTC));
    private final UUID id = UUID.randomUUID();
    private final UUID admin = UUID.randomUUID();
    private final LocalDate monday = LocalDate.of(2026, 9, 21);

    private WeeklyPricingService.PublishRequest request(LocalDate week, String amount) {
        return new WeeklyPricingService.PublishRequest(week, List.of(
                new WeeklyPricingService.Entry(id, new BigDecimal(amount), new BigDecimal("100"))));
    }
    private PriceCalendar validCatalogue() {
        PriceCalendar calendar = new PriceCalendar(); calendar.setZone("HYD_PILOT");
        when(calendars.lockCalendar("HYD_PILOT")).thenReturn(Optional.of(calendar));
        Product product = new Product(); product.setId(id); product.setActive(true);
        when(products.findAllById(any())).thenReturn(List.of(product));
        return calendar;
    }
    @Test void currentLookupUsesOneInstantAndZone() {
        ProductPrice newest = new ProductPrice(); newest.setProductId(id);
        ProductPrice older = new ProductPrice(); older.setProductId(id);
        when(prices.findEffectivePrices(List.of(id), "HYD_PILOT", now)).thenReturn(List.of(newest, older));
        assertSame(newest, service.current(List.of(id)).get(id));
        verify(prices).findEffectivePrices(List.of(id), "HYD_PILOT", now);
    }
    @Test void publishActivatesAtMondayMidnightIndiaAndClosesOldWindow() {
        PriceCalendar calendar = validCatalogue();
        ProductPrice old = new ProductPrice(); old.setProductId(id);
        old.setEffectiveFrom(now.minusSeconds(86400)); old.setSellingPrice(new BigDecimal("60"));
        when(prices.findByProductIdInAndZoneAndActiveTrue(anyList(), eq("HYD_PILOT"))).thenReturn(List.of(old));
        var result = service.publish(admin, request(monday, "75.50"));
        Instant boundary = Instant.parse("2026-09-20T18:30:00Z");
        assertEquals(boundary, result.effectiveFrom());
        assertEquals(boundary, old.getEffectiveTo());
        assertEquals(new BigDecimal("60"), old.getSellingPrice());
        assertEquals(monday, calendar.getLastPublishedWeek());
        ArgumentCaptor<ProductPrice> saved = ArgumentCaptor.forClass(ProductPrice.class);
        verify(prices, times(2)).save(saved.capture());
        ProductPrice next = saved.getAllValues().get(1);
        assertEquals(new BigDecimal("75.50"), next.getSellingPrice());
        assertEquals(next.getSellingPrice(), next.getMaxPrice());
        assertEquals(admin, next.getPublishedBy());
    }
    @Test void cannotChangeTheCurrentWeek() {
        assertThrows(ApiException.class, () -> service.publish(admin, request(monday.minusWeeks(1), "75")));
        verifyNoInteractions(prices, products, calendars);
    }
    @Test void weekMustStartOnMonday() {
        assertThrows(ApiException.class, () -> service.publish(admin, request(monday.plusDays(1), "75")));
    }
    @Test void cannotRepublishOrInsertBeforeScheduledWeek() {
        PriceCalendar calendar = new PriceCalendar(); calendar.setLastPublishedWeek(monday);
        when(calendars.lockCalendar("HYD_PILOT")).thenReturn(Optional.of(calendar));
        assertThrows(ApiException.class, () -> service.publish(admin, request(monday, "75")));
        verify(prices, never()).save(any());
    }
    @Test void rejectsDuplicateProductsBeforeWriting() {
        validCatalogue(); var r = request(monday, "75");
        assertThrows(ApiException.class, () -> service.publish(admin,
                new WeeklyPricingService.PublishRequest(monday, List.of(r.prices().get(0), r.prices().get(0)))));
        verify(prices, never()).save(any());
    }
    @Test void rejectsPriceAboveMrp() {
        validCatalogue();
        assertThrows(ApiException.class, () -> service.publish(admin, request(monday, "101")));
        verify(prices, never()).save(any());
    }
    @Test void absentCurrentPriceCannotBeOrdered() {
        assertThrows(ApiException.class, () -> service.requireCurrent(id));
    }
}
