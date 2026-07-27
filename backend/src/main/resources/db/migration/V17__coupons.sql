-- Coupons / offers (Vol1 offers module). A coupon applies a discount to a
-- settled order's payable amount; redemptions enforce usage limits and give an
-- audit trail. The order carries the applied code + discount so capture (mock
-- or Razorpay) charges the net amount.

CREATE TABLE coupons (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code           VARCHAR(40) NOT NULL UNIQUE,
    title          VARCHAR(120) NOT NULL,
    description    TEXT,
    discount_type  VARCHAR(10) NOT NULL,              -- PERCENT | FLAT
    discount_value NUMERIC(10,2) NOT NULL,
    min_basket     NUMERIC(10,2) NOT NULL DEFAULT 0,
    max_discount   NUMERIC(10,2),                     -- cap for PERCENT (null = uncapped)
    valid_from     TIMESTAMPTZ,
    valid_until    TIMESTAMPTZ,
    usage_limit    INT,                               -- global cap (null = unlimited)
    per_user_limit INT NOT NULL DEFAULT 1,
    new_users_only BOOLEAN NOT NULL DEFAULT FALSE,
    tint           VARCHAR(16),                       -- UI accent hint
    sort_order     INT NOT NULL DEFAULT 0,
    active         BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE coupon_redemptions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    coupon_id       UUID NOT NULL REFERENCES coupons(id),
    user_id         UUID NOT NULL REFERENCES users(id),
    order_id        UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    discount_amount NUMERIC(10,2) NOT NULL,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    version         BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_coupon_redemptions_coupon ON coupon_redemptions(coupon_id);
CREATE INDEX idx_coupon_redemptions_user   ON coupon_redemptions(user_id);

-- Order carries the applied coupon + discount so payment charges the net.
ALTER TABLE orders ADD COLUMN discount_amount NUMERIC(10,2) NOT NULL DEFAULT 0;
ALTER TABLE orders ADD COLUMN coupon_code     VARCHAR(40);

INSERT INTO coupons (code, title, description, discount_type, discount_value, min_basket,
                     max_discount, valid_until, per_user_limit, new_users_only, tint, sort_order) VALUES
 ('WELCOME150', 'Rs 150 off your first weekly basket',
  'Applies to settled baskets over Rs 799. New households only.',
  'FLAT', 150, 799, NULL, TIMESTAMPTZ '2027-12-31 23:59:59+05:30', 1, TRUE, 'leaf', 1),
 ('FRESH20', '20% off your weekly basket',
  'Save 20% on your settled order, up to Rs 200 off.',
  'PERCENT', 20, 0, 200, TIMESTAMPTZ '2027-12-31 23:59:59+05:30', 3, FALSE, 'carrot', 2),
 ('SAVE50', 'Rs 50 off baskets over Rs 500',
  'A little something on every qualifying weekly order.',
  'FLAT', 50, 500, NULL, TIMESTAMPTZ '2027-12-31 23:59:59+05:30', 5, FALSE, 'info', 3);
