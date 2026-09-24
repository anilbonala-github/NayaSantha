package com.nayasantha.api.order;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nayasantha.api.address.*;
import com.nayasantha.api.basket.*;
import com.nayasantha.api.catalogue.*;
import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.settings.SettingsService;
import com.nayasantha.api.subscription.SubscriptionService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.security.*;
import java.util.*;

/** Review and confirm the same server-owned basket snapshot. No client money is trusted. */
@Service
public class CheckoutService {
    private final BasketService basketService;
    private final BasketRepository baskets;
    private final BasketItemRepository items;
    private final ProductRepository products;
    private final WeeklyPricingService pricing;
    private final AddressRepository addresses;
    private final SettingsService settings;
    private final SubscriptionService subscriptions;
    private final OrderRepository orders;
    private final OrderService orderService;
    private final ObjectMapper json;

    public CheckoutService(BasketService basketService, BasketRepository baskets, BasketItemRepository items,
            ProductRepository products, WeeklyPricingService pricing, AddressRepository addresses,
            SettingsService settings, SubscriptionService subscriptions, OrderRepository orders,
            OrderService orderService, ObjectMapper json) {
        this.basketService=basketService; this.baskets=baskets; this.items=items; this.products=products;
        this.pricing=pricing; this.addresses=addresses; this.settings=settings; this.subscriptions=subscriptions;
        this.orders=orders; this.orderService=orderService; this.json=json;
    }
    public record Line(UUID productId, UUID priceId, String name, String unit, String emoji,
                       int quantity, BigDecimal unitPrice, BigDecimal amount) {}
    public record Preview(UUID basketId, List<Line> items, BigDecimal subtotal, BigDecimal deliveryFee,
                          BigDecimal total, String deliveryAddress, String deliverySlot, String community, String quoteToken) {}
    private record Snapshot(UUID basketId, List<Line> items, UUID addressId, String deliveryAddress,
                            String deliverySlot, BigDecimal deliveryFee, String community) {}

    @Transactional
    public Preview preview(UUID user) {
        UUID id = basketService.getCurrent(user).id();
        Basket basket = baskets.lockById(id).orElseThrow(() -> ApiException.notFound("Basket"));
        return review(user, basket);
    }

    @Transactional
    public OrderDtos.OrderDto checkout(UUID user, UUID basketId, String quoteToken) {
        Basket basket = baskets.lockById(basketId).filter(b -> user.equals(b.getUserId()))
                .orElseThrow(() -> ApiException.notFound("Basket"));
        if (basket.getStatus() == Basket.Status.CHECKED_OUT) {
            Order existing = orders.findByBasketIdAndUserId(basketId, user)
                    .orElseThrow(() -> ApiException.userError("This basket was already checked out. Open Orders."));
            return orderService.get(user, existing.getId());
        }
        if (basket.getStatus() != Basket.Status.ACTIVE) throw ApiException.userError("This basket is no longer active.");
        Preview preview = review(user, basket);
        if (!Objects.equals(quoteToken, preview.quoteToken())) {
            throw ApiException.userError("Your items, prices or delivery details changed. Refresh the review before confirming.");
        }
        OrderDtos.OrderDto result = orderService.confirmBasket(user, basketId, preview);
        basket.setStatus(Basket.Status.CHECKED_OUT);
        baskets.save(basket);
        return result;
    }

    private Preview review(UUID user, Basket basket) {
        if (!user.equals(basket.getUserId())) throw ApiException.forbidden("Not your basket");
        List<BasketItem> stored = items.findByBasketId(basket.getId());
        if (stored.isEmpty()) throw ApiException.userError("Your basket is empty. Add items before checkout.");
        List<UUID> ids = stored.stream().map(BasketItem::getProductId).toList();
        var rates = pricing.current(ids);
        Map<UUID, Product> catalogue = new HashMap<>();
        products.findAllById(ids).forEach(p -> catalogue.put(p.getId(), p));
        List<Line> lines = new ArrayList<>();
        for (BasketItem item : stored) {
            Product product = catalogue.get(item.getProductId());
            ProductPrice price = rates.get(item.getProductId());
            if (product == null || !product.isActive() || !product.isAvailable() || price == null || item.getQuantity() < 1) {
                throw ApiException.userError("An item is no longer available. Remove it from your basket before checkout.");
            }
            BigDecimal rate = price.getSellingPrice().setScale(2);
            lines.add(new Line(product.getId(), price.getId(), product.getName(), product.getUnit(), product.getEmoji(),
                    item.getQuantity(), rate, rate.multiply(BigDecimal.valueOf(item.getQuantity()))));
        }
        lines.sort(Comparator.comparing(line -> line.productId().toString()));
        Address address = addresses.findByUserIdOrderByIsDefaultDescCreatedAtDesc(user).stream()
                .filter(a -> a.isDefault() && a.isServiceable()).findFirst()
                .orElseThrow(() -> ApiException.userError("Choose a serviceable delivery address before checkout."));
        String destination = String.join(", ", java.util.stream.Stream.of(address.getLine1(), address.getLine2(),
                address.getApartment(), address.getCity(), address.getPincode()).filter(s -> s != null && !s.isBlank()).toList());
        var perks = subscriptions.perksOf(user);
        BigDecimal fee = (perks.freeDelivery() ? BigDecimal.ZERO : settings.deliveryFee()).setScale(2);
        String slot = perks.prioritySlot() ? settings.priorityDeliverySlot() : settings.deliverySlot();
        BigDecimal subtotal = lines.stream().map(Line::amount).reduce(BigDecimal.ZERO, BigDecimal::add);
        String community = address.getApartment() != null && !address.getApartment().isBlank()
                ? address.getApartment() : address.getLabel();
        String token = fingerprint(new Snapshot(basket.getId(), lines, address.getId(), destination, slot, fee, community));
        return new Preview(basket.getId(), lines, subtotal, fee, subtotal.add(fee), destination, slot, community, token);
    }

    private String fingerprint(Snapshot snapshot) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(json.writeValueAsBytes(snapshot)));
        } catch (NoSuchAlgorithmException | JsonProcessingException e) {
            throw new IllegalStateException("Could not prepare checkout review", e);
        }
    }
}
