-- Membership perks enforcement (Vol1 §9.1). Turn the free-text perks into
-- structured flags the backend actually enforces: free delivery (waive the
-- delivery fee), members-only offers, and a priority delivery slot.
ALTER TABLE subscription_plans ADD COLUMN free_delivery BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE subscription_plans ADD COLUMN member_offers BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE subscription_plans ADD COLUMN priority_slot BOOLEAN NOT NULL DEFAULT FALSE;

UPDATE subscription_plans SET free_delivery = TRUE, member_offers = TRUE, priority_slot = TRUE
 WHERE code IN ('PLUS', 'FAMILY');

-- Delivery fee (waived for members) + priority slot config on the single ops row.
ALTER TABLE ops_settings ADD COLUMN delivery_fee          NUMERIC(10,2) NOT NULL DEFAULT 29;
ALTER TABLE ops_settings ADD COLUMN priority_delivery_slot VARCHAR(60)  NOT NULL DEFAULT 'Sun 8:00-11:00 AM';

-- Orders carry the delivery fee applied at settlement.
ALTER TABLE orders ADD COLUMN delivery_fee NUMERIC(10,2) NOT NULL DEFAULT 0;

-- Coupons can be restricted to members; seed one to demonstrate enforcement.
ALTER TABLE coupons ADD COLUMN members_only BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO coupons (code, title, description, discount_type, discount_value, min_basket,
                     max_discount, valid_until, per_user_limit, new_users_only, members_only, tint, sort_order) VALUES
 ('MEMBER15', 'Members: 15% off your basket',
  'A Plus/Family perk — 15% off your settled order, up to Rs 250.',
  'PERCENT', 15, 0, 250, TIMESTAMPTZ '2027-12-31 23:59:59+05:30', 4, FALSE, TRUE, 'turmeric', 0);
