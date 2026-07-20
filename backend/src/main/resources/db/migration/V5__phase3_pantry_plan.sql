-- Phase 3: pantry + AI weekly plan (Vol2 §3.2, §6.4, §6.5).

CREATE TABLE pantry_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id      UUID REFERENCES products(id),   -- nullable: freeform items allowed
    name            VARCHAR(180) NOT NULL,          -- snapshot so history survives catalogue edits
    quantity        NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    unit            VARCHAR(40),
    low_stock_threshold NUMERIC(10,2) NOT NULL DEFAULT 1,
    purchase_date   DATE,
    expiry_date     DATE,
    source          VARCHAR(40) NOT NULL DEFAULT 'MANUAL'
                        CHECK (source IN ('MANUAL','ORDER','SCAN')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    version         BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_pantry_user ON pantry_items(user_id);

-- One generated weekly plan (estimate + guaranteed max + AI explanation), versioned.
CREATE TABLE weekly_plans (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id     UUID REFERENCES households(id),
    week_start       DATE NOT NULL,
    estimated_total  NUMERIC(12,2) NOT NULL DEFAULT 0,
    maximum_payable  NUMERIC(12,2) NOT NULL DEFAULT 0,
    ai_explanation   TEXT,
    ai_model         VARCHAR(80),        -- observability: which model produced it
    ai_prompt_version VARCHAR(40),
    ai_source        VARCHAR(20) NOT NULL DEFAULT 'FALLBACK'
                        CHECK (ai_source IN ('GEMINI','FALLBACK')),
    status           VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
                        CHECK (status IN ('DRAFT','APPROVED','CONFIRMED','EXPIRED')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    version          BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_weekly_plans_user ON weekly_plans(user_id);

CREATE TABLE weekly_plan_items (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id            UUID NOT NULL REFERENCES weekly_plans(id) ON DELETE CASCADE,
    product_id         UUID NOT NULL REFERENCES products(id),
    quantity           INT NOT NULL CHECK (quantity > 0),
    unit_forecast_price NUMERIC(12,2) NOT NULL,
    unit_max_price     NUMERIC(12,2) NOT NULL,
    reason             VARCHAR(255),       -- why the planner picked it
    substitution_group VARCHAR(60),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    version            BIGINT NOT NULL DEFAULT 0,
    UNIQUE (plan_id, product_id)
);
CREATE INDEX idx_plan_items_plan ON weekly_plan_items(plan_id);
