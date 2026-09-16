package com.nayasantha.api.order;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.nayasantha.api.address.*;
import com.nayasantha.api.basket.*;
import com.nayasantha.api.catalogue.*;
import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.settings.SettingsService;
import com.nayasantha.api.subscription.SubscriptionService;
import com.nayasantha.api.subscription.SubscriptionDtos.MemberPerks;
import org.junit.jupiter.api.*;
import java.math.BigDecimal;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class CheckoutServiceTest {
    BasketService basketService=mock(BasketService.class);
    BasketRepository baskets=mock(BasketRepository.class);
    BasketItemRepository items=mock(BasketItemRepository.class);
    ProductRepository products=mock(ProductRepository.class);
    WeeklyPricingService pricing=mock(WeeklyPricingService.class);
    AddressRepository addresses=mock(AddressRepository.class);
    SettingsService settings=mock(SettingsService.class);
    SubscriptionService subscriptions=mock(SubscriptionService.class);
    OrderRepository orders=mock(OrderRepository.class);
    OrderService orderService=mock(OrderService.class);
    CheckoutService service=new CheckoutService(basketService,baskets,items,products,pricing,addresses,
            settings,subscriptions,orders,orderService,new ObjectMapper());
    UUID user=UUID.randomUUID(), id=UUID.randomUUID(), productId=UUID.randomUUID();
    Basket basket=new Basket(); BasketItem item=new BasketItem(); ProductPrice price=new ProductPrice();
    Address address=new Address();
    @BeforeEach void setup() {
        basket.setId(id); basket.setUserId(user);
        when(basketService.getCurrent(user)).thenReturn(new BasketDtos.BasketDto(id,"ACTIVE",2,
                new BigDecimal("151"),new BigDecimal("151"),List.of(),0L));
        when(baskets.lockById(id)).thenReturn(Optional.of(basket));
        item.setProductId(productId); item.setQuantity(2);
        when(items.findByBasketId(id)).thenReturn(List.of(item));
        Product product=new Product(); product.setId(productId); product.setActive(true); product.setName("Rice"); product.setUnit("1 kg");
        when(products.findAllById(any())).thenReturn(List.of(product));
        price.setId(UUID.randomUUID()); price.setSellingPrice(new BigDecimal("75.50"));
        when(pricing.current(anyList())).thenReturn(Map.of(productId,price));
        address.setId(UUID.randomUUID()); address.setDefault(true); address.setServiceable(true); address.setLine1("Test address");
        when(addresses.findByUserIdOrderByIsDefaultDescCreatedAtDesc(user)).thenReturn(List.of(address));
        when(subscriptions.perksOf(user)).thenReturn(MemberPerks.BASIC);
        when(settings.deliveryFee()).thenReturn(new BigDecimal("39")); when(settings.deliverySlot()).thenReturn("Sunday morning");
    }
    @Test void previewIncludesDeliveryAndExactTotal() {
        var review=service.preview(user);
        assertEquals(new BigDecimal("151.00"),review.subtotal());
        assertEquals(new BigDecimal("190.00"),review.total());
        assertEquals(64,review.quoteToken().length());
        assertEquals(review.quoteToken(),service.preview(user).quoteToken());
    }
    @Test void reviewedBasketCreatesOrderAndClosesBasket() {
        var review=service.preview(user); var dto=mock(OrderDtos.OrderDto.class);
        when(orderService.confirmBasket(eq(user),eq(id),any())).thenReturn(dto);
        assertSame(dto,service.checkout(user,id,review.quoteToken()));
        assertEquals(Basket.Status.CHECKED_OUT,basket.getStatus()); verify(baskets).save(basket);
    }
    @Test void changedPriceCannotBeSilentlyConfirmed() {
        var review=service.preview(user); price.setSellingPrice(new BigDecimal("80"));
        assertThrows(ApiException.class,()->service.checkout(user,id,review.quoteToken()));
        verifyNoInteractions(orderService);
    }
    @Test void changedQuantityCannotBeSilentlyConfirmed() {
        var review=service.preview(user); item.setQuantity(3);
        assertThrows(ApiException.class,()->service.checkout(user,id,review.quoteToken()));
        verifyNoInteractions(orderService);
    }
    @Test void changedAddressRequiresAnotherReview() {
        var review=service.preview(user); address.setLine1("Another address");
        assertThrows(ApiException.class,()->service.checkout(user,id,review.quoteToken()));
        verifyNoInteractions(orderService);
    }
    @Test void changedDeliveryFeeRequiresAnotherReview() {
        var review=service.preview(user); when(settings.deliveryFee()).thenReturn(new BigDecimal("49"));
        assertThrows(ApiException.class,()->service.checkout(user,id,review.quoteToken()));
        verifyNoInteractions(orderService);
    }
    @Test void retryAfterSuccessReturnsExistingOrderEvenIfPricesChange() {
        basket.setStatus(Basket.Status.CHECKED_OUT); Order existing=new Order(); existing.setId(UUID.randomUUID());
        var dto=mock(OrderDtos.OrderDto.class);
        when(orders.findByBasketIdAndUserId(id,user)).thenReturn(Optional.of(existing));
        when(orderService.get(user,existing.getId())).thenReturn(dto);
        assertSame(dto,service.checkout(user,id,"old-review"));
        verify(orderService,never()).confirmBasket(any(),any(),any());
    }
    @Test void otherUsersBasketCannotBeCheckedOut() {
        assertThrows(ApiException.class,()->service.checkout(UUID.randomUUID(),id,"anything"));
        verifyNoInteractions(orderService);
    }
    @Test void unavailableItemBlocksCheckout() {
        when(pricing.current(anyList())).thenReturn(Map.of());
        assertThrows(ApiException.class,()->service.preview(user));
    }
    @Test void unserviceableAddressBlocksCheckout() {
        address.setServiceable(false);
        assertThrows(ApiException.class,()->service.preview(user));
    }
}
