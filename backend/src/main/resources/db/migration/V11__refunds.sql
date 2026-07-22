-- Refunds (Vol2A FR-015 auto-refund + §14 quality/missing-item claims).
-- Money-only; never any raw payment credential.
ALTER TABLE payment_authorizations
    ADD COLUMN refunded_amount NUMERIC(12,2) NOT NULL DEFAULT 0;

CREATE TABLE refunds (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id   UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    amount     NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    type       VARCHAR(30) NOT NULL,       -- CANCELLATION | MISSING_ITEM | QUALITY_CLAIM | GOODWILL
    reason     VARCHAR(300),
    reference  VARCHAR(80),                -- gateway/reconciliation reference
    status     VARCHAR(20) NOT NULL DEFAULT 'PROCESSED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_refunds_order ON refunds(order_id);
