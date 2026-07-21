-- Phase 4: price consent, order lifecycle, Sunday settlement (Vol2A §10).

CREATE TABLE price_consents (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id             UUID NOT NULL REFERENCES weekly_plans(id) ON DELETE CASCADE,
    order_id            UUID,
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    max_payable         NUMERIC(12,2) NOT NULL,
    preference          VARCHAR(30) NOT NULL
                            CHECK (preference IN ('SMART_SUBSTITUTE','KEEP_EXACT_ITEMS',
                                                  'ASK_BEFORE_CHANGE','REMOVE_EXPENSIVE_ITEMS')),
    substitution_consent BOOLEAN NOT NULL DEFAULT true,
    consent_version     VARCHAR(20) NOT NULL DEFAULT 'v1',
    device_info         VARCHAR(255),
    consented_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_consents_plan ON price_consents(plan_id);

CREATE TABLE orders (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id          UUID REFERENCES weekly_plans(id),
    address_snapshot VARCHAR(500),
    price_preference VARCHAR(30) NOT NULL,
    estimated_total  NUMERIC(12,2) NOT NULL,
    maximum_payable  NUMERIC(12,2) NOT NULL,
    final_total      NUMERIC(12,2),
    delivery_slot    VARCHAR(60),
    status           VARCHAR(24) NOT NULL DEFAULT 'CONFIRMED'
                        CHECK (status IN ('CONFIRMED','LOCKED','PURCHASING','FINALIZED',
                                          'AWAITING_APPROVAL','PAID','DELIVERED','CANCELLED')),
    locked_at        TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    version          BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_orders_user ON orders(user_id);

-- Snapshot of the basket at confirmation, with Sunday actuals filled in later.
CREATE TABLE order_items (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id            UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id          UUID NOT NULL REFERENCES products(id),
    name                VARCHAR(180) NOT NULL,
    unit                VARCHAR(40),
    quantity            INT NOT NULL CHECK (quantity > 0),
    forecast_rate       NUMERIC(12,2) NOT NULL,
    estimated_amount    NUMERIC(12,2) NOT NULL,
    actual_rate         NUMERIC(12,2),
    final_qty           INT,
    final_amount        NUMERIC(12,2),
    substitution_reason VARCHAR(255),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    version             BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_order_items_order ON order_items(order_id);

CREATE TABLE payment_authorizations (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id          UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    provider          VARCHAR(40) NOT NULL DEFAULT 'UPI_AUTOPAY',
    authorized_amount NUMERIC(12,2) NOT NULL,
    captured_amount   NUMERIC(12,2),
    reference         VARCHAR(120),
    status            VARCHAR(20) NOT NULL DEFAULT 'AUTHORIZED'
                        CHECK (status IN ('AUTHORIZED','CAPTURED','REFUNDED','FAILED')),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    version           BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_payauth_order ON payment_authorizations(order_id);

CREATE TABLE price_exceptions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id          UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    reason            VARCHAR(255),
    estimated_total   NUMERIC(12,2) NOT NULL,
    final_total       NUMERIC(12,2) NOT NULL,
    max_payable       NUMERIC(12,2) NOT NULL,
    response_deadline TIMESTAMPTZ,
    resolution        VARCHAR(30),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_exceptions_order ON price_exceptions(order_id);
