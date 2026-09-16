package com.nayasantha.api.basket;

import com.nayasantha.api.catalogue.*;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class FixedBasketPricingTest {
    @Test void editableBasketRefreshesAtRolloverAndHasNoMarkupCap() {
        BasketRepository baskets = mock(BasketRepository.class);
        BasketItemRepository items = mock(BasketItemRepository.class);
        ProductRepository products = mock(ProductRepository.class);
        WeeklyPricingService prices = mock(WeeklyPricingService.class);
        BasketService service = new BasketService(baskets, items, products, prices);
        UUID user = UUID.randomUUID(), product = UUID.randomUUID();
        Basket basket = new Basket(); basket.setId(UUID.randomUUID());
        when(baskets.findByUserIdAndStatus(user, Basket.Status.ACTIVE)).thenReturn(Optional.of(basket));
        BasketItem line = new BasketItem(); line.setProductId(product); line.setQuantity(2);
        line.setUnitSellingPrice(new BigDecimal("60")); line.setUnitMaxPrice(new BigDecimal("70"));
        when(items.findByBasketId(basket.getId())).thenReturn(List.of(line));
        ProductPrice current = new ProductPrice(); current.setSellingPrice(new BigDecimal("75.50"));
        when(prices.current(List.of(product))).thenReturn(Map.of(product, current));
        var dto = service.getCurrent(user);
        assertEquals(new BigDecimal("151.00"), dto.estimatedTotal());
        assertEquals(dto.estimatedTotal(), dto.maximumPayable());
        verify(items).save(line);
    }
}
