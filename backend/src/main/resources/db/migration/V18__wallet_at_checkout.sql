-- Wallet-at-checkout (Vol2 §3.2): a settled order can apply wallet balance
-- before payment. The applied amount is held (debited) on the wallet ledger and
-- the gateway only charges the remainder.
ALTER TABLE orders ADD COLUMN wallet_applied NUMERIC(10,2) NOT NULL DEFAULT 0;
