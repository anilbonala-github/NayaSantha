package com.nayasantha.api.order;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Raised when the Sunday final total exceeds the customer's maximum (Vol2A §6.4). */
@Entity
@Table(name = "price_exceptions")
@Getter
@Setter
public class PriceException {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "order_id", nullable = false)
    private UUID orderId;

    private String reason;

    @Column(name = "estimated_total", nullable = false)
    private BigDecimal estimatedTotal;

    @Column(name = "final_total", nullable = false)
    private BigDecimal finalTotal;

    @Column(name = "max_payable", nullable = false)
    private BigDecimal maxPayable;

    @Column(name = "response_deadline")
    private Instant responseDeadline;

    private String resolution;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();
}
