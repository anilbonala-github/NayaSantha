-- NayaSantha Phase 2: catalogue + basket (Vol2 §3.2, §6.3, §6.6).
-- Products/prices are the system of record; Flutter never hard-codes them.

CREATE TABLE categories (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(120) NOT NULL,
    slug       VARCHAR(120) NOT NULL UNIQUE,
    parent_id  UUID REFERENCES categories(id) ON DELETE SET NULL,
    emoji      VARCHAR(16),
    sort_order INT NOT NULL DEFAULT 0,
    active     BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version    BIGINT NOT NULL DEFAULT 0
);

CREATE TABLE products (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku          VARCHAR(60) NOT NULL UNIQUE,
    name         VARCHAR(180) NOT NULL,
    category_id  UUID NOT NULL REFERENCES categories(id),
    unit         VARCHAR(40) NOT NULL,          -- e.g. "1 kg", "500 g", "1 L"
    description  TEXT,
    emoji        VARCHAR(16),                   -- placeholder until CDN images
    image_url    VARCHAR(512),
    origin       VARCHAR(120) DEFAULT 'Telangana',
    farmer       VARCHAR(180),
    rating       NUMERIC(2,1),
    rating_count INT NOT NULL DEFAULT 0,
    badges       TEXT,                          -- comma-separated trust markers
    nutrition    JSONB,
    active       BOOLEAN NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    version      BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_name ON products(lower(name));

-- Zone/source prices with effective dates (Vol2 §3.2). estimate uses
-- selling_price; the basket's guaranteed maximum uses max_price.
CREATE TABLE product_prices (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id     UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    zone           VARCHAR(40) NOT NULL DEFAULT 'HYD_PILOT',
    mrp            NUMERIC(12,2),
    forecast_price NUMERIC(12,2) NOT NULL,
    selling_price  NUMERIC(12,2) NOT NULL,      -- estimate rate shown to customer
    max_price      NUMERIC(12,2) NOT NULL,      -- guaranteed ceiling (Vol1 §6)
    effective_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_to   TIMESTAMPTZ,
    active         BOOLEAN NOT NULL DEFAULT true,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    version        BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_prices_product_active ON product_prices(product_id, active);

-- One active editable basket per user (Vol2 §6.6).
CREATE TABLE baskets (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status         VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
                       CHECK (status IN ('ACTIVE','CHECKED_OUT','ABANDONED')),
    weekly_plan_id UUID,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    version        BIGINT NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX uq_active_basket_per_user
    ON baskets(user_id) WHERE status = 'ACTIVE';

CREATE TABLE basket_items (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    basket_id          UUID NOT NULL REFERENCES baskets(id) ON DELETE CASCADE,
    product_id         UUID NOT NULL REFERENCES products(id),
    quantity           INT NOT NULL CHECK (quantity > 0),
    unit_selling_price NUMERIC(12,2) NOT NULL,   -- snapshot at add time
    unit_max_price     NUMERIC(12,2) NOT NULL,
    price_version      BIGINT NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    version            BIGINT NOT NULL DEFAULT 0,
    UNIQUE (basket_id, product_id)
);
CREATE INDEX idx_basket_items_basket ON basket_items(basket_id);
