package com.nayasantha.api.basket;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BasketItemRepository extends JpaRepository<BasketItem, UUID> {
    List<BasketItem> findByBasketId(UUID basketId);
    Optional<BasketItem> findByBasketIdAndProductId(UUID basketId, UUID productId);
}
