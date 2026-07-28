package com.nayasantha.api.wallet;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** One wallet ledger entry (Vol2 §3.2). Positive amount = credit, negative = debit. */
@Entity
@Table(name = "wallet_transactions")
@Getter
@Setter
public class WalletTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(updatable = false, nullable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(nullable = false)
    private String type;

    private String reason;

    @Column(name = "order_id")
    private UUID orderId;

    @Column(name = "balance_after", nullable = false)
    private BigDecimal balanceAfter;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    public enum Type { REFUND, PROMO, REFERRAL, TOPUP, ORDER_PAYMENT, SUBSCRIPTION, ADJUSTMENT }
}
