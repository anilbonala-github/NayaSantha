-- NayaSantha Phase 1 core schema (Vol2 §3.2).
-- Auth + profile/household + address. UUID PKs, UTC timestamps, optimistic
-- locking via `version`, FKs/constraints in the DB (not just Flutter).

CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()

-- ---------------------------------------------------------------------------
-- Identity
-- ---------------------------------------------------------------------------
CREATE TABLE users (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mobile                    VARCHAR(20)  NOT NULL UNIQUE,
    email                     VARCHAR(255) UNIQUE,
    name                      VARCHAR(120),
    status                    VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE'
                                  CHECK (status IN ('ACTIVE','SUSPENDED','DELETED')),
    profile_completion_status VARCHAR(20)  NOT NULL DEFAULT 'NEW'
                                  CHECK (profile_completion_status IN ('NEW','ONBOARDING','COMPLETE')),
    last_login_at             TIMESTAMPTZ,
    created_at                TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at                TIMESTAMPTZ  NOT NULL DEFAULT now(),
    version                   BIGINT       NOT NULL DEFAULT 0
);

CREATE TABLE user_devices (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token     VARCHAR(512),
    platform      VARCHAR(20) CHECK (platform IN ('ANDROID','IOS','WEB')),
    app_version   VARCHAR(40),
    last_active_at TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    version       BIGINT NOT NULL DEFAULT 0,
    UNIQUE (user_id, fcm_token)
);

-- Refresh-token sessions with rotation (Vol2 §5 token refresh rotation).
CREATE TABLE auth_sessions (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(128) NOT NULL UNIQUE,
    issued_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at         TIMESTAMPTZ NOT NULL,
    revoked_at         TIMESTAMPTZ,
    user_agent         VARCHAR(255),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_auth_sessions_user ON auth_sessions(user_id);

-- Short-lived OTP challenges (dev-stubbed until an SMS provider is wired).
CREATE TABLE otp_challenges (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mobile      VARCHAR(20) NOT NULL,
    code_hash   VARCHAR(128) NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    attempts    INT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_otp_mobile ON otp_challenges(mobile);

-- ---------------------------------------------------------------------------
-- Household + members
-- ---------------------------------------------------------------------------
CREATE TABLE households (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    weekly_budget  NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (weekly_budget >= 0),
    language       VARCHAR(10) NOT NULL DEFAULT 'en',
    default_price_consent VARCHAR(20) NOT NULL DEFAULT 'ASK'
                       CHECK (default_price_consent IN ('ASK','AUTO_WITHIN_MAX','NO_SUBSTITUTION')),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    version        BIGINT NOT NULL DEFAULT 0,
    UNIQUE (owner_user_id)
);

CREATE TABLE household_members (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id   UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    name           VARCHAR(120),
    age            INT CHECK (age >= 0 AND age < 130),
    dietary_type   VARCHAR(20) NOT NULL DEFAULT 'VEG'
                       CHECK (dietary_type IN ('VEG','NON_VEG','VEGAN','EGGETARIAN')),
    allergies      TEXT,                       -- comma-separated hard exclusions
    nutrition_notes TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    version        BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_members_household ON household_members(household_id);

-- ---------------------------------------------------------------------------
-- Addresses + serviceability
-- ---------------------------------------------------------------------------
CREATE TABLE addresses (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label         VARCHAR(60),
    line1         VARCHAR(255) NOT NULL,
    line2         VARCHAR(255),
    apartment     VARCHAR(120),
    city          VARCHAR(120) NOT NULL DEFAULT 'Hyderabad',
    pincode       VARCHAR(10)  NOT NULL,
    latitude      NUMERIC(9,6),
    longitude     NUMERIC(9,6),
    is_serviceable BOOLEAN NOT NULL DEFAULT false,
    is_default    BOOLEAN NOT NULL DEFAULT false,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    version       BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_addresses_user ON addresses(user_id);

-- Pincodes covered by the Hyderabad apartment-first pilot (Vol1 §7.1).
CREATE TABLE serviceable_pincodes (
    pincode     VARCHAR(10) PRIMARY KEY,
    area_name   VARCHAR(120),
    active      BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- Audit (Vol2 §3.2 audit_logs) — actor, entity, old/new, reason
-- ---------------------------------------------------------------------------
CREATE TABLE audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id UUID,
    entity_type VARCHAR(60) NOT NULL,
    entity_id   UUID,
    action      VARCHAR(40) NOT NULL,
    old_values  JSONB,
    new_values  JSONB,
    reason      VARCHAR(255),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
