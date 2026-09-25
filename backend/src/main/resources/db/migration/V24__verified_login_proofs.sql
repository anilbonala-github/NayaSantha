-- Retain hashes only: provider proof must not mint multiple sessions.
CREATE TABLE used_login_proofs (
    token_hash VARCHAR(64) PRIMARY KEY,
    used_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
