-- Fulfillment layer (Vol2A §7.4 packing + Vol1 §14 delivery). Tracked separately
-- from the pricing/payment status so the money state machine is untouched.
ALTER TABLE orders ADD COLUMN fulfillment_stage VARCHAR(20) NOT NULL DEFAULT 'PENDING'
    CHECK (fulfillment_stage IN ('PENDING','PACKING','PACKED','OUT_FOR_DELIVERY','DELIVERED'));

-- Community/apartment snapshot for grouping orders into packing & delivery waves.
ALTER TABLE orders ADD COLUMN community VARCHAR(160);
