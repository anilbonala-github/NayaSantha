package com.nayasantha.api.basket;

import com.nayasantha.api.basket.BasketDtos.*;
import com.nayasantha.api.catalogue.Product;
import com.nayasantha.api.catalogue.ProductPrice;
import com.nayasantha.api.catalogue.ProductPriceRepository;
import com.nayasantha.api.catalogue.ProductRepository;
import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.common.ErrorCode;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Persistent basket with server-recalculated estimate + guaranteed maximum
 *  (Vol1 §6, Vol2 §6.6). Totals are never trusted from the client. */
@Service
public class BasketService {

    private final BasketRepository baskets;
    private final BasketItemRepository items;
    private final ProductRepository products;
    private final ProductPriceRepository prices;

    public BasketService(BasketRepository baskets, BasketItemRepository items,
                         ProductRepository products, ProductPriceRepository prices) {
        this.baskets = baskets;
        this.items = items;
        this.products = products;
        this.prices = prices;
    }

    @Transactional
    public BasketDto getCurrent(UUID userId) {
        return toDto(currentBasket(userId));
    }

    @Transactional
    public BasketDto addItem(UUID userId, UUID productId, int quantity) {
        Basket basket = currentBasket(userId);
        Product product = products.findById(productId)
                .orElseThrow(() -> ApiException.notFound("Product"));
        ProductPrice price = prices.findFirstByProductIdAndActiveTrueOrderByEffectiveFromDesc(productId)
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "No active price for product"));

        BasketItem item = items.findByBasketIdAndProductId(basket.getId(), productId).orElse(null);
        if (item == null) {
            item = new BasketItem();
            item.setBasketId(basket.getId());
            item.setProductId(productId);
            item.setQuantity(quantity);
        } else {
            item.setQuantity(item.getQuantity() + quantity);
        }
        item.setUnitSellingPrice(price.getSellingPrice());
        item.setUnitMaxPrice(price.getMaxPrice());
        item.setPriceVersion(price.getVersion() == null ? 0 : price.getVersion());
        items.save(item);
        touch(basket);
        return toDto(basket);
    }

    @Transactional
    public BasketDto updateItem(UUID userId, UUID itemId, int quantity, Long expectedVersion) {
        Basket basket = currentBasket(userId);
        BasketItem item = items.findById(itemId)
                .filter(i -> i.getBasketId().equals(basket.getId()))
                .orElseThrow(() -> ApiException.notFound("Basket item"));
        if (expectedVersion != null && !expectedVersion.equals(item.getVersion())) {
            throw new ObjectOptimisticLockingFailureException(
                    "expected version " + item.getVersion() + " but received " + expectedVersion, null);
        }
        if (quantity <= 0) {
            items.delete(item);
        } else {
            item.setQuantity(quantity);
            items.save(item);
        }
        touch(basket);
        return toDto(basket);
    }

    @Transactional
    public BasketDto removeItem(UUID userId, UUID itemId) {
        Basket basket = currentBasket(userId);
        items.findById(itemId)
                .filter(i -> i.getBasketId().equals(basket.getId()))
                .ifPresent(items::delete);
        touch(basket);
        return toDto(basket);
    }

    // --- helpers -----------------------------------------------------------
    private Basket currentBasket(UUID userId) {
        return baskets.findByUserIdAndStatus(userId, Basket.Status.ACTIVE).orElseGet(() -> {
            Basket b = new Basket();
            b.setUserId(userId);
            return baskets.save(b);
        });
    }

    /** Bump the basket's updated_at/version so clients can detect changes. */
    private void touch(Basket basket) {
        baskets.save(basket);
    }

    private BasketDto toDto(Basket basket) {
        List<BasketItem> lines = items.findByBasketId(basket.getId());
        Map<UUID, Product> productById = new HashMap<>();
        if (!lines.isEmpty()) {
            products.findAllById(lines.stream().map(BasketItem::getProductId).toList())
                    .forEach(p -> productById.put(p.getId(), p));
        }

        BigDecimal estimate = BigDecimal.ZERO;
        BigDecimal maximum = BigDecimal.ZERO;
        int count = 0;
        var itemDtos = new java.util.ArrayList<BasketItemDto>();
        for (BasketItem li : lines) {
            BigDecimal lineEstimate = li.getUnitSellingPrice().multiply(BigDecimal.valueOf(li.getQuantity()));
            BigDecimal lineMax = li.getUnitMaxPrice().multiply(BigDecimal.valueOf(li.getQuantity()));
            estimate = estimate.add(lineEstimate);
            maximum = maximum.add(lineMax);
            count += li.getQuantity();
            Product p = productById.get(li.getProductId());
            itemDtos.add(new BasketItemDto(li.getId(), li.getProductId(),
                    p == null ? null : p.getName(), p == null ? null : p.getEmoji(),
                    p == null ? null : p.getUnit(), li.getQuantity(),
                    li.getUnitSellingPrice(), li.getUnitMaxPrice(), lineEstimate, lineMax, li.getVersion()));
        }
        return new BasketDto(basket.getId(), basket.getStatus().name(), count,
                estimate, maximum, itemDtos, basket.getVersion());
    }
}
