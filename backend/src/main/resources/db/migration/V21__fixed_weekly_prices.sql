-- Existing orders retain their legacy settlement rules. New orders opt in explicitly.
ALTER TABLE orders ADD COLUMN pricing_mode VARCHAR(24) NOT NULL DEFAULT 'LEGACY_VARIABLE'
    CHECK (pricing_mode IN ('LEGACY_VARIABLE', 'FIXED_WEEKLY'));
ALTER TABLE product_prices ADD COLUMN price_week_start DATE;
ALTER TABLE product_prices ADD COLUMN published_by UUID REFERENCES users(id);
CREATE UNIQUE INDEX uq_published_product_week ON product_prices(product_id, zone, price_week_start)
    WHERE price_week_start IS NOT NULL;
CREATE TABLE price_calendars (
    zone VARCHAR(40) PRIMARY KEY,
    last_published_week DATE
);
INSERT INTO price_calendars(zone) VALUES ('HYD_PILOT');

ALTER TABLE weekly_plans ADD COLUMN pricing_mode VARCHAR(24) NOT NULL DEFAULT 'LEGACY_VARIABLE'
    CHECK (pricing_mode IN ('LEGACY_VARIABLE', 'FIXED_WEEKLY'));
