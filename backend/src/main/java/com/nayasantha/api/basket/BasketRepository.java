package com.nayasantha.api.basket;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface BasketRepository extends JpaRepository<Basket, UUID> {
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    Optional<Basket> findByUserIdAndStatus(UUID userId, Basket.Status status);
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select b from Basket b where b.id = :id")
    Optional<Basket> lockById(@org.springframework.data.repository.query.Param("id") UUID id);
}
