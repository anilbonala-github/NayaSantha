-- Wallet ledger (Vol2 §3.2: credit/debit ledger, never store only a balance).
-- amount: positive = credit, negative = debit. Balance = SUM(amount).
CREATE TABLE wallet_transactions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount        NUMERIC(12,2) NOT NULL,
    type          VARCHAR(30) NOT NULL,   -- REFUND | PROMO | REFERRAL | TOPUP | ORDER_PAYMENT | ADJUSTMENT
    reason        VARCHAR(300),
    order_id      UUID,
    balance_after NUMERIC(12,2) NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_wallet_tx_user ON wallet_transactions(user_id, created_at DESC);
