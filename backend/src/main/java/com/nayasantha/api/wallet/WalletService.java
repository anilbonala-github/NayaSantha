package com.nayasantha.api.wallet;

import com.nayasantha.api.common.ApiException;
import com.nayasantha.api.common.ErrorCode;
import com.nayasantha.api.wallet.WalletDtos.TransactionDto;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Wallet ledger: balance is always SUM(amount); each entry records balance_after. */
@Service
public class WalletService {

    private final WalletTransactionRepository repo;

    public WalletService(WalletTransactionRepository repo) {
        this.repo = repo;
    }

    @Transactional(readOnly = true)
    public BigDecimal balance(UUID userId) {
        return repo.balanceOf(userId);
    }

    /** Add a signed entry (positive credit / negative debit). Debits cannot overdraw. */
    @Transactional
    public WalletTransaction post(UUID userId, BigDecimal amount, WalletTransaction.Type type,
                                 String reason, UUID orderId) {
        BigDecimal current = repo.balanceOf(userId);
        BigDecimal after = current.add(amount);
        if (after.signum() < 0) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "Insufficient wallet balance");
        }
        WalletTransaction w = new WalletTransaction();
        w.setUserId(userId);
        w.setAmount(amount);
        w.setType(type.name());
        w.setReason(reason);
        w.setOrderId(orderId);
        w.setBalanceAfter(after);
        w.setCreatedAt(Instant.now());
        return repo.save(w);
    }

    public WalletTransaction credit(UUID userId, BigDecimal amount, WalletTransaction.Type type,
                                    String reason, UUID orderId) {
        return post(userId, amount.abs(), type, reason, orderId);
    }

    @Transactional(readOnly = true)
    public List<TransactionDto> list(UUID userId, int page, int size) {
        Page<WalletTransaction> p = repo.findByUserIdOrderByCreatedAtDesc(
                userId, PageRequest.of(page, Math.min(size, 50)));
        return p.getContent().stream().map(TransactionDto::from).toList();
    }
}
