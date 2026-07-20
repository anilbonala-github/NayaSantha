package com.nayasantha.api.basket;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface BasketRepository extends JpaRepository<Basket, UUID> {
    Optional<Basket> findByUserIdAndStatus(UUID userId, Basket.Status status);
}
