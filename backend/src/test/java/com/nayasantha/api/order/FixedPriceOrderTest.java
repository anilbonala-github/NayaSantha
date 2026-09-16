package com.nayasantha.api.order;

import com.nayasantha.api.address.*;
import com.nayasantha.api.catalogue.*;
import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.plan.*;
import com.nayasantha.api.subscription.SubscriptionDtos.MemberPerks;
import org.junit.jupiter.api.*;
import org.mockito.*;
import java.math.BigDecimal;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class FixedPriceOrderTest {
    @Mock OrderRepository orders;
    @Mock OrderItemRepository items;
    @Mock PriceConsentRepository consents;
    @Mock PaymentAuthorizationRepository payments;
    @Mock PriceExceptionRepository exceptions;
    @Mock WeeklyPlanRepository plans;
    @Mock WeeklyPlanItemRepository planItems;
    @Mock ProductRepository products;
    @Mock WeeklyPricingService sellingPrices;
    @Mock com.nayasantha.api.notification.NotificationService notifications;
    @Mock AddressRepository addresses;
    @Mock RefundRepository refunds;
    @Mock com.nayasantha.api.payment.PaymentGateway gateway;
    @Mock com.nayasantha.api.payment.RazorpayCheckoutService razorpayCheckout;
    @Mock com.nayasantha.api.settings.SettingsService settings;
    @Mock com.nayasantha.api.wallet.WalletService wallet;
    @Mock com.nayasantha.api.coupon.CouponService coupons;
    @Mock com.nayasantha.api.subscription.SubscriptionService subscriptions;
    @InjectMocks OrderService service;
    AutoCloseable mocks;
    UUID user = UUID.randomUUID(), planId = UUID.randomUUID(), productId = UUID.randomUUID();
    Order order;
    WeeklyPlan plan;
    @BeforeEach void setup() {
        mocks = MockitoAnnotations.openMocks(this);
        order = new Order(); order.setId(UUID.randomUUID()); order.setUserId(user);
        order.setPricingMode("FIXED_WEEKLY"); order.setStatus(Order.Status.LOCKED);
        order.setEstimatedTotal(new BigDecimal("151.00")); order.setMaximumPayable(new BigDecimal("151.00"));
        order.setFinalTotal(new BigDecimal("151.00")); order.setDeliveryFee(new BigDecimal("39"));
        when(orders.findById(order.getId())).thenReturn(Optional.of(order));
        when(orders.save(any())).thenAnswer(inv -> { Order o = inv.getArgument(0); if(o.getId()==null) o.setId(UUID.randomUUID()); return o; });
        when(subscriptions.perksOf(user)).thenReturn(MemberPerks.BASIC);
        when(settings.deliveryFee()).thenReturn(new BigDecimal("39"));
        plan = new WeeklyPlan(); plan.setId(planId); plan.setUserId(user); plan.setPricingMode("FIXED_WEEKLY"); plan.setVersion(2L);
        plan.setEstimatedTotal(new BigDecimal("151.00"));
        when(plans.lockById(planId)).thenReturn(Optional.of(plan));
        WeeklyPlanItem line = new WeeklyPlanItem(); line.setProductId(productId); line.setQuantity(2);
        line.setUnitForecastPrice(new BigDecimal("75.50"));
        when(planItems.findByPlanId(planId)).thenReturn(List.of(line));
        ProductPrice price = new ProductPrice(); price.setSellingPrice(new BigDecimal("75.50"));
        when(sellingPrices.current(anyList())).thenReturn(Map.of(productId, price));
        Product product = new Product(); product.setId(productId); product.setName("Rice"); product.setActive(true);
        when(products.findAllById(any())).thenReturn(List.of(product));
        Address address = new Address(); address.setDefault(true); address.setServiceable(true);
        when(addresses.findByUserIdOrderByIsDefaultDescCreatedAtDesc(user)).thenReturn(List.of(address));
    }
    @AfterEach void close() throws Exception { mocks.close(); }
    private OrderDtos.ApproveRequest request() {
        return new OrderDtos.ApproveRequest("KEEP_EXACT_ITEMS", new BigDecimal("151"), false, "test", 2L);
    }
    @Test void unavailableGatewayCannotMarkAnOrderPaid() {
        order.setStatus(Order.Status.FINALIZED);
        when(payments.findFirstByOrderIdOrderByCreatedAtDesc(order.getId())).thenReturn(Optional.of(new PaymentAuthorization()));
        assertThrows(ApiException.class, () -> service.capture(user, order.getId()));
        assertEquals(Order.Status.FINALIZED, order.getStatus());
        verify(gateway, never()).capture(any(), any());
        verify(payments, never()).save(any());
    }
    @Test void fullyCoveredOrderDoesNotRequireGatewayCharge() {
        order.setStatus(Order.Status.FINALIZED);
        order.setWalletApplied(new BigDecimal("190.00"));
        when(payments.findFirstByOrderIdOrderByCreatedAtDesc(order.getId())).thenReturn(Optional.of(new PaymentAuthorization()));
        assertEquals("PAID", service.capture(user, order.getId()).status());
        verify(gateway, never()).capture(any(), any());
    }
    @Test void confirmationSnapshotsSellingPricesAndDeliveryFee() {
        var result = service.approve(user, planId, request());
        assertEquals("FIXED_WEEKLY", result.pricingMode());
        assertEquals(new BigDecimal("151.00"), result.finalTotal());
        assertEquals(new BigDecimal("190.00"), result.amountPayable());
        var captured = ArgumentCaptor.forClass(OrderItem.class);
        verify(items).save(captured.capture());
        assertEquals(new BigDecimal("75.50"), captured.getValue().getActualRate());
        assertEquals(new BigDecimal("151.00"), captured.getValue().getFinalAmount());
        verify(gateway).authorize(any(), eq(new BigDecimal("190.00")));
    }
    @Test void highProcurementCostCannotRaiseConfirmedTotal() {
        var result = service.settleWithCapturedRates(order.getId(), Map.of(productId, new BigDecimal("999")));
        assertEquals(new BigDecimal("151.00"), result.finalTotal());
        assertEquals(new BigDecimal("190.00"), result.amountPayable());
        assertEquals("FINALIZED", result.status());
        verify(items, never()).save(any());
        verifyNoInteractions(exceptions, sellingPrices);
    }
    @Test void lowProcurementCostCannotRewriteConfirmedTotal() {
        var result = service.settleWithCapturedRates(order.getId(), Map.of(productId, BigDecimal.ONE));
        assertEquals(new BigDecimal("151.00"), result.finalTotal());
        verify(items, never()).save(any());
    }
    @Test void repeatedFinalizationCannotChangePaidOrder() {
        order.setStatus(Order.Status.PAID);
        var result = service.settleWithCapturedRates(order.getId(), Map.of());
        assertEquals("PAID", result.status());
        verify(orders, never()).save(any());
    }
    @Test void nextWeeksPriceRequiresAnotherReview() {
        ProductPrice next = new ProductPrice(); next.setSellingPrice(new BigDecimal("80"));
        when(sellingPrices.current(anyList())).thenReturn(Map.of(productId, next));
        assertThrows(ApiException.class, () -> service.approve(user, planId, request()));
        verify(orders, never()).save(any()); verifyNoInteractions(gateway);
    }
    @Test void approvedPlanCannotCreateDuplicateOrder() {
        plan.setStatus(WeeklyPlan.Status.APPROVED);
        assertThrows(ApiException.class, () -> service.approve(user, planId, request()));
        verify(orders, never()).save(any());
    }
    @Test void changedPlanVersionMustBeReviewedAgain() {
        plan.setVersion(3L);
        assertThrows(ApiException.class, () -> service.approve(user, planId, request()));
        verify(orders, never()).save(any());
    }
    @Test void noDefaultAddressCannotConfirm() {
        when(addresses.findByUserIdOrderByIsDefaultDescCreatedAtDesc(user)).thenReturn(List.of());
        assertThrows(ApiException.class, () -> service.approve(user, planId, request()));
        verify(orders, never()).save(any());
    }
    @Test void fixedOrderCannotUseCustomerSettlementDemo() {
        assertThrows(ApiException.class, () -> service.simulateSettlement(user, order.getId()));
        verify(orders, never()).save(any());
    }
    @Test void lockingCannotRegressPaidOrder() {
        order.setStatus(Order.Status.PAID);
        assertThrows(ApiException.class, () -> service.lock(user, order.getId()));
    }
}
