package com.nayasantha.api.order;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** A refund against a captured payment (Vol2A FR-015, §14). Amounts only. */
@Entity
@Table(name = "refunds")
@Getter
@Setter
public class Refund {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(name = "order_id", nullable = false)
    private UUID orderId;

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(nullable = false)
    private String type;

    private String reason;

    private String reference;

    @Column(nullable = false)
    private String status = "PROCESSED";

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    public enum Type { CANCELLATION, MISSING_ITEM, QUALITY_CLAIM, GOODWILL }
}
