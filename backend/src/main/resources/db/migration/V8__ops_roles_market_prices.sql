-- Vol3 ops: admin role + captured Sunday market prices.

ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'CUSTOMER'
    CHECK (role IN ('CUSTOMER','ADMIN'));

-- Actual market rate captured by the procurement team for a product/week.
CREATE TABLE market_prices (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id  UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    week_start  DATE NOT NULL,
    actual_rate NUMERIC(12,2) NOT NULL CHECK (actual_rate >= 0),
    captured_by UUID,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    version     BIGINT NOT NULL DEFAULT 0,
    UNIQUE (product_id, week_start)
);
CREATE INDEX idx_market_prices_week ON market_prices(week_start);
