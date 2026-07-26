-- Referrals (Vol2 §6 referral module). Bonus credited to both wallets.
ALTER TABLE users ADD COLUMN referral_code VARCHAR(12) UNIQUE;

CREATE TABLE referrals (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referee_user_id  UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,  -- one referral per new user
    code             VARCHAR(12) NOT NULL,
    bonus_amount     NUMERIC(10,2) NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_referrals_referrer ON referrals(referrer_user_id);
