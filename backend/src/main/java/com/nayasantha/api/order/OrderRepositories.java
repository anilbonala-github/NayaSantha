package com.nayasantha.api.order;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

// Grouped in one file for brevity; each is a standard top-level Spring Data repo.
interface OrderRepository extends JpaRepository<Order, UUID> {
    Page<Order> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);
    List<Order> findByStatus(Order.Status status);
}

interface OrderItemRepository extends JpaRepository<OrderItem, UUID> {
    List<OrderItem> findByOrderId(UUID orderId);
}

interface PriceConsentRepository extends JpaRepository<PriceConsent, UUID> {}

interface PaymentAuthorizationRepository extends JpaRepository<PaymentAuthorization, UUID> {
    Optional<PaymentAuthorization> findFirstByOrderIdOrderByCreatedAtDesc(UUID orderId);
}

interface PriceExceptionRepository extends JpaRepository<PriceException, UUID> {
    Optional<PriceException> findFirstByOrderIdOrderByCreatedAtDesc(UUID orderId);
}
