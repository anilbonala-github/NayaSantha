-- Membership plans + subscriptions (Vol1 §9.1 optional membership, Vol2 §3.2).
CREATE TABLE subscription_plans (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(30) NOT NULL UNIQUE,
    name            VARCHAR(60) NOT NULL,
    badge           VARCHAR(30),
    price_per_month NUMERIC(10,2) NOT NULL DEFAULT 0,
    perks           TEXT NOT NULL DEFAULT '',   -- newline-separated
    sort_order      INT NOT NULL DEFAULT 0,
    active          BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO subscription_plans (code, name, badge, price_per_month, perks, sort_order) VALUES
 ('FREE',   'Basic',  NULL,      0,   E'Weekly AI plan\nStandard Sunday delivery\nEmail support', 0),
 ('PLUS',   'Plus',   'Popular', 99,  E'Free delivery every week\nPriority delivery slot\nEarly access to offers\nPriority support', 1),
 ('FAMILY', 'Family', NULL,      199, E'Everything in Plus\nLarger weekly budgets & bulk buys\nDedicated support\n2 delivery slots per week', 2);

CREATE TABLE subscriptions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id       UUID NOT NULL REFERENCES subscription_plans(id),
    status        VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',  -- ACTIVE | CANCELLED | EXPIRED
    billing_cycle VARCHAR(20) NOT NULL DEFAULT 'MONTHLY',
    started_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    renews_at     TIMESTAMPTZ,
    cancelled_at  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    version       BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_subscriptions_user ON subscriptions(user_id, created_at DESC);
