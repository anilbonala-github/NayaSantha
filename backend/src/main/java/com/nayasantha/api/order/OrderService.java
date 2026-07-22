package com.nayasantha.api.order;

import com.nayasantha.api.catalogue.Product;
import com.nayasantha.api.catalogue.ProductRepository;
import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.common.ErrorCode;
import com.nayasantha.api.order.OrderDtos.*;
import com.nayasantha.api.plan.WeeklyPlan;
import com.nayasantha.api.plan.WeeklyPlanItem;
import com.nayasantha.api.plan.WeeklyPlanItemRepository;
import com.nayasantha.api.plan.WeeklyPlanRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * Phase 4 pricing lifecycle (Vol2A): approve with consent → lock → Sunday
 * settlement → capture within cap, or raise an exception above cap. All money
 * math is deterministic and server-owned; never trust the client (Vol2A §20).
 */
@Service
public class OrderService {

    private static final Set<String> PREFERENCES = Set.of(
            "SMART_SUBSTITUTE", "KEEP_EXACT_ITEMS", "ASK_BEFORE_CHANGE", "REMOVE_EXPENSIVE_ITEMS");

    private final OrderRepository orders;
    private final OrderItemRepository items;
    private final PriceConsentRepository consents;
    private final PaymentAuthorizationRepository payments;
    private final PriceExceptionRepository exceptions;
    private final WeeklyPlanRepository plans;
    private final WeeklyPlanItemRepository planItems;
    private final ProductRepository products;
    private final com.nayasantha.api.notification.NotificationService notifications;

    public OrderService(OrderRepository orders, OrderItemRepository items, PriceConsentRepository consents,
                        PaymentAuthorizationRepository payments, PriceExceptionRepository exceptions,
                        WeeklyPlanRepository plans, WeeklyPlanItemRepository planItems, ProductRepository products,
                        com.nayasantha.api.notification.NotificationService notifications) {
        this.orders = orders;
        this.items = items;
        this.consents = consents;
        this.payments = payments;
        this.exceptions = exceptions;
        this.plans = plans;
        this.planItems = planItems;
        this.products = products;
        this.notifications = notifications;
    }

    private static String money(BigDecimal v) {
        return v == null ? "₹0" : String.format("₹%,.0f", v);
    }

    // --- 1. Approve (before Saturday cutoff): consent + order + authorization -----
    @Transactional
    public OrderDto approve(UUID userId, UUID planId, ApproveRequest req) {
        if (!PREFERENCES.contains(req.pricePreference())) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Invalid price preference");
        }
        WeeklyPlan plan = plans.findById(planId).filter(p -> p.getUserId().equals(userId))
                .orElseThrow(() -> ApiException.notFound("Weekly plan"));
        List<WeeklyPlanItem> lines = planItems.findByPlanId(planId);
        if (lines.isEmpty()) throw new ApiException(ErrorCode.VALIDATION_ERROR, "Plan has no items");

        BigDecimal maxPayable = req.maxPayable() != null ? req.maxPayable() : plan.getMaximumPayable();

        Order order = new Order();
        order.setUserId(userId);
        order.setPlanId(planId);
        order.setPricePreference(req.pricePreference());
        order.setEstimatedTotal(plan.getEstimatedTotal());
        order.setMaximumPayable(maxPayable);
        order.setDeliverySlot("Sun 2:00-8:00 PM");
        order = orders.save(order);

        Map<UUID, Product> byId = new HashMap<>();
        products.findAllById(lines.stream().map(WeeklyPlanItem::getProductId).toList())
                .forEach(p -> byId.put(p.getId(), p));
        for (WeeklyPlanItem li : lines) {
            Product p = byId.get(li.getProductId());
            OrderItem oi = new OrderItem();
            oi.setOrderId(order.getId());
            oi.setProductId(li.getProductId());
            oi.setName(p == null ? "Item" : p.getName());
            oi.setUnit(p == null ? null : p.getUnit());
            oi.setQuantity(li.getQuantity());
            oi.setForecastRate(li.getUnitForecastPrice());
            oi.setEstimatedAmount(li.getUnitForecastPrice().multiply(BigDecimal.valueOf(li.getQuantity())));
            items.save(oi);
        }

        PriceConsent consent = new PriceConsent();
        consent.setPlanId(planId);
        consent.setOrderId(order.getId());
        consent.setUserId(userId);
        consent.setMaxPayable(maxPayable);
        consent.setPreference(req.pricePreference());
        consent.setSubstitutionConsent(req.substitutionConsent() == null || req.substitutionConsent());
        consent.setDeviceInfo(req.deviceInfo());
        consents.save(consent);

        PaymentAuthorization auth = new PaymentAuthorization();
        auth.setOrderId(order.getId());
        auth.setAuthorizedAmount(maxPayable);      // authorize the cap; capture only final (Vol2A §14)
        auth.setReference("auth_" + UUID.randomUUID().toString().substring(0, 12));
        payments.save(auth);

        plan.setStatus(WeeklyPlan.Status.APPROVED);
        plans.save(plan);

        notifications.create(userId,
                com.nayasantha.api.notification.NotificationService.ORDER_CONFIRMED,
                "Order confirmed",
                "Your weekly order is locked. You'll never be charged more than "
                        + money(maxPayable) + " without your approval.",
                order.getId());
        return toDto(order);
    }

    @Transactional
    public OrderDto lock(UUID userId, UUID orderId) {
        Order order = owned(userId, orderId);
        order.setStatus(Order.Status.LOCKED);
        order.setLockedAt(Instant.now());
        return toDto(orders.save(order));
    }

    // --- 2. Sunday settlement --------------------------------------------------------
    /** DEV simulation of ops price-capture: random actual -3%..+8% of forecast. */
    @Transactional
    public OrderDto simulateSettlement(UUID userId, UUID orderId) {
        Order order = owned(userId, orderId);
        Random rnd = new Random();
        return settle(order, oi -> oi.getForecastRate()
                .multiply(BigDecimal.valueOf(1 + (-0.03 + rnd.nextDouble() * 0.11)))
                .setScale(2, RoundingMode.HALF_UP));
    }

    /**
     * Vol3 ops finalize: settle a locked order using the real market rates captured
     * on Sunday ({@code productId -> actual rate}). Missing rates fall back to forecast.
     */
    @Transactional
    public OrderDto settleWithCapturedRates(UUID orderId, Map<UUID, BigDecimal> ratesByProduct) {
        Order order = orders.findById(orderId).orElseThrow(() -> ApiException.notFound("Order"));
        OrderDto dto = settle(order, oi -> {
            BigDecimal r = oi.getProductId() == null ? null : ratesByProduct.get(oi.getProductId());
            return (r != null ? r : oi.getForecastRate()).setScale(2, RoundingMode.HALF_UP);
        });
        if ("FINALIZED".equals(dto.status())) {
            String body = "Market purchase complete. Final total " + money(dto.finalTotal())
                    + (dto.savings() != null && dto.savings().signum() > 0
                        ? " — you saved " + money(dto.savings()) + "." : ".");
            notifications.create(order.getUserId(),
                    com.nayasantha.api.notification.NotificationService.MARKET_UPDATE,
                    "Sunday market update", body, order.getId());
        } else if ("AWAITING_APPROVAL".equals(dto.status())) {
            notifications.create(order.getUserId(),
                    com.nayasantha.api.notification.NotificationService.PRICE_EXCEPTION,
                    "Your approval is needed",
                    "Sunday prices pushed your basket above your maximum. Choose an option before delivery.",
                    order.getId());
        }
        return dto;
    }

    /** Shared settlement core: apply per-line actual rates, then enforce the cap (Vol2A). */
    private OrderDto settle(Order order, java.util.function.Function<OrderItem, BigDecimal> rateFn) {
        List<OrderItem> lines = items.findByOrderId(order.getId());
        BigDecimal finalTotal = BigDecimal.ZERO;
        for (OrderItem oi : lines) {
            BigDecimal actual = rateFn.apply(oi);
            oi.setActualRate(actual);
            oi.setFinalQty(oi.getQuantity());
            oi.setFinalAmount(actual.multiply(BigDecimal.valueOf(oi.getQuantity())));
            items.save(oi);
            finalTotal = finalTotal.add(oi.getFinalAmount());
        }

        if (finalTotal.compareTo(order.getMaximumPayable()) <= 0) {
            order.setFinalTotal(finalTotal);
            order.setStatus(Order.Status.FINALIZED);
        } else if (order.getPricePreference().equals("REMOVE_EXPENSIVE_ITEMS")
                || order.getPricePreference().equals("SMART_SUBSTITUTE")) {
            finalTotal = reduceUnderCap(lines, order.getMaximumPayable(),
                    order.getPricePreference().equals("SMART_SUBSTITUTE") ? "Substituted to stay under your limit"
                                                                          : "Removed: price above your limit");
            if (finalTotal.compareTo(order.getMaximumPayable()) <= 0) {
                order.setFinalTotal(finalTotal);
                order.setStatus(Order.Status.FINALIZED);
            } else {
                raiseException(order, finalTotal);
            }
        } else {
            raiseException(order, finalTotal);   // KEEP_EXACT / ASK_BEFORE_CHANGE
        }
        return toDto(orders.save(order));
    }

    // --- 3. Exception decision (customer) -----------------------------------------
    @Transactional
    public OrderDto decide(UUID userId, UUID orderId, String decision) {
        Order order = owned(userId, orderId);
        if (order.getStatus() != Order.Status.AWAITING_APPROVAL) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Order is not awaiting approval");
        }
        PriceException ex = exceptions.findFirstByOrderIdOrderByCreatedAtDesc(orderId).orElse(null);
        switch (decision) {
            case "ACCEPT" -> {                       // extra consent to charge above cap
                order.setStatus(Order.Status.FINALIZED);
                if (ex != null) { ex.setResolution("ACCEPTED"); exceptions.save(ex); }
            }
            case "REMOVE_EXPENSIVE" -> {
                BigDecimal ft = reduceUnderCap(items.findByOrderId(orderId), order.getMaximumPayable(),
                        "Removed at your request: over your limit");
                order.setFinalTotal(ft);
                order.setStatus(Order.Status.FINALIZED);
                if (ex != null) { ex.setResolution("REMOVED"); exceptions.save(ex); }
            }
            case "CANCEL" -> {
                order.setStatus(Order.Status.CANCELLED);
                payments.findFirstByOrderIdOrderByCreatedAtDesc(orderId).ifPresent(pa -> {
                    pa.setStatus(PaymentAuthorization.Status.FAILED);
                    payments.save(pa);
                });
                if (ex != null) { ex.setResolution("CANCELLED"); exceptions.save(ex); }
            }
            default -> throw new ApiException(ErrorCode.VALIDATION_ERROR, "Unknown decision");
        }
        return toDto(orders.save(order));
    }

    // --- 4. Capture the final amount ----------------------------------------------
    @Transactional
    public OrderDto capture(UUID userId, UUID orderId) {
        Order order = owned(userId, orderId);
        if (order.getStatus() == Order.Status.PAID) return toDto(order);   // idempotent
        if (order.getStatus() != Order.Status.FINALIZED) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Order is not ready for capture");
        }
        PaymentAuthorization auth = payments.findFirstByOrderIdOrderByCreatedAtDesc(orderId)
                .orElseThrow(() -> ApiException.notFound("Payment authorization"));
        auth.setCapturedAmount(order.getFinalTotal());          // capture only the final amount
        auth.setStatus(PaymentAuthorization.Status.CAPTURED);
        payments.save(auth);
        order.setStatus(Order.Status.PAID);
        Order saved = orders.save(order);
        notifications.create(order.getUserId(),
                com.nayasantha.api.notification.NotificationService.PAYMENT_COMPLETE,
                "Payment complete",
                money(order.getFinalTotal()) + " charged. Your final invoice and savings summary are ready.",
                order.getId());
        return toDto(saved);
    }

    // --- ops gateway (Vol3): expose order data to the ops module without leaking repos --
    @Transactional(readOnly = true)
    public List<Order> ordersByStatus(Order.Status status) {
        return orders.findByStatus(status);
    }

    /** Saturday 10 PM cutoff: lock every confirmed order for procurement. Returns count locked. */
    @Transactional
    public int lockAllConfirmed() {
        List<Order> confirmed = orders.findByStatus(Order.Status.CONFIRMED);
        Instant now = Instant.now();
        for (Order o : confirmed) {
            o.setStatus(Order.Status.LOCKED);
            o.setLockedAt(now);
            orders.save(o);
        }
        return confirmed.size();
    }

    @Transactional(readOnly = true)
    public List<OrderItem> itemsOf(UUID orderId) {
        return items.findByOrderId(orderId);
    }

    // --- reads --------------------------------------------------------------------
    @Transactional(readOnly = true)
    public List<OrderDto> list(UUID userId, int page, int size) {
        Page<Order> p = orders.findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(page, Math.min(size, 50)));
        return p.getContent().stream().map(this::toDto).toList();
    }

    @Transactional(readOnly = true)
    public OrderDto get(UUID userId, UUID orderId) {
        return toDto(owned(userId, orderId));
    }

    @Transactional(readOnly = true)
    public PriceComparisonDto priceComparison(UUID userId, UUID orderId) {
        Order order = owned(userId, orderId);
        List<PriceComparisonLine> lines = new ArrayList<>();
        for (OrderItem oi : items.findByOrderId(orderId)) {
            BigDecimal diff = oi.getFinalAmount() == null ? null
                    : oi.getFinalAmount().subtract(oi.getEstimatedAmount());
            lines.add(new PriceComparisonLine(oi.getName(), oi.getQuantity(), oi.getForecastRate(),
                    oi.getActualRate(), oi.getEstimatedAmount(), oi.getFinalAmount(), diff));
        }
        BigDecimal savings = order.getFinalTotal() == null ? null
                : order.getEstimatedTotal().subtract(order.getFinalTotal());
        boolean withinCap = order.getFinalTotal() != null
                && order.getFinalTotal().compareTo(order.getMaximumPayable()) <= 0;
        return new PriceComparisonDto(order.getEstimatedTotal(), order.getFinalTotal(), savings, withinCap, lines);
    }

    // --- helpers ------------------------------------------------------------------
    private Order owned(UUID userId, UUID orderId) {
        Order o = orders.findById(orderId).orElseThrow(() -> ApiException.notFound("Order"));
        if (!o.getUserId().equals(userId)) throw ApiException.forbidden("Not your order");
        return o;
    }

    private void raiseException(Order order, BigDecimal finalTotal) {
        order.setFinalTotal(finalTotal);
        order.setStatus(Order.Status.AWAITING_APPROVAL);
        PriceException ex = new PriceException();
        ex.setOrderId(order.getId());
        ex.setReason("Final market total exceeds your maximum payable");
        ex.setEstimatedTotal(order.getEstimatedTotal());
        ex.setFinalTotal(finalTotal);
        ex.setMaxPayable(order.getMaximumPayable());
        ex.setResponseDeadline(Instant.now().plus(2, ChronoUnit.HOURS));
        exceptions.save(ex);
    }

    /** Drop items with the biggest actual-vs-forecast increase until under cap; returns new final. */
    private BigDecimal reduceUnderCap(List<OrderItem> lines, BigDecimal cap, String reason) {
        List<OrderItem> active = new ArrayList<>(lines.stream()
                .filter(i -> i.getFinalAmount() != null && i.getFinalAmount().signum() > 0).toList());
        active.sort((a, b) -> variance(b).compareTo(variance(a)));   // most-inflated first
        BigDecimal total = active.stream().map(OrderItem::getFinalAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        for (OrderItem oi : active) {
            if (total.compareTo(cap) <= 0) break;
            total = total.subtract(oi.getFinalAmount());
            oi.setFinalQty(0);
            oi.setFinalAmount(BigDecimal.ZERO);
            oi.setSubstitutionReason(reason);
            items.save(oi);
        }
        return total;
    }

    private BigDecimal variance(OrderItem oi) {
        if (oi.getActualRate() == null || oi.getForecastRate().signum() == 0) return BigDecimal.ZERO;
        return oi.getActualRate().subtract(oi.getForecastRate())
                .divide(oi.getForecastRate(), 4, RoundingMode.HALF_UP);
    }

    private OrderDto toDto(Order order) {
        List<OrderItemDto> itemDtos = items.findByOrderId(order.getId()).stream()
                .map(i -> new OrderItemDto(i.getId(), i.getProductId(), i.getName(), i.getUnit(),
                        i.getQuantity(), i.getForecastRate(), i.getEstimatedAmount(), i.getActualRate(),
                        i.getFinalQty(), i.getFinalAmount(), i.getSubstitutionReason())).toList();
        String paymentStatus = payments.findFirstByOrderIdOrderByCreatedAtDesc(order.getId())
                .map(pa -> pa.getStatus().name()).orElse(null);
        ExceptionDto exDto = null;
        if (order.getStatus() == Order.Status.AWAITING_APPROVAL) {
            exDto = exceptions.findFirstByOrderIdOrderByCreatedAtDesc(order.getId())
                    .map(e -> new ExceptionDto(e.getId(), e.getReason(), e.getFinalTotal(), e.getMaxPayable(),
                            e.getResponseDeadline(), e.getResolution())).orElse(null);
        }
        BigDecimal savings = order.getFinalTotal() == null ? null
                : order.getEstimatedTotal().subtract(order.getFinalTotal());
        return new OrderDto(order.getId(), order.getStatus().name(), order.getPricePreference(),
                order.getEstimatedTotal(), order.getMaximumPayable(), order.getFinalTotal(), savings,
                order.getDeliverySlot(), paymentStatus, itemDtos, exDto, order.getCreatedAt(), order.getVersion());
    }
}
