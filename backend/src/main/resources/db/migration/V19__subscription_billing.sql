-- Recurring subscription billing (Vol1 §9.1). Paid memberships are charged from
-- the customer's wallet: month 1 on subscribe, then monthly on renewal. Failed
-- renewals go PAST_DUE and are retried; after repeated failures they EXPIRE.
ALTER TABLE subscriptions ADD COLUMN last_billed_at   TIMESTAMPTZ;
ALTER TABLE subscriptions ADD COLUMN failed_attempts  INT NOT NULL DEFAULT 0;

CREATE TABLE subscription_payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id),
    plan_id         UUID NOT NULL REFERENCES subscription_plans(id),
    amount          NUMERIC(10,2) NOT NULL,
    status          VARCHAR(10) NOT NULL,             -- PAID | FAILED
    reason          VARCHAR(160),
    period_start    TIMESTAMPTZ NOT NULL,
    period_end      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    version         BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_subscription_payments_user ON subscription_payments(user_id);
CREATE INDEX idx_subscription_payments_sub  ON subscription_payments(subscription_id);
