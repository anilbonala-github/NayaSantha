package com.nayasantha.api.wallet;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public final class WalletDtos {

    private WalletDtos() {}

    public record WalletDto(BigDecimal balance, List<TransactionDto> transactions) {}

    public record TransactionDto(UUID id, BigDecimal amount, String type, String reason,
                                 UUID orderId, BigDecimal balanceAfter, Instant createdAt) {
        static TransactionDto from(WalletTransaction w) {
            return new TransactionDto(w.getId(), w.getAmount(), w.getType(), w.getReason(),
                    w.getOrderId(), w.getBalanceAfter(), w.getCreatedAt());
        }
    }
}
