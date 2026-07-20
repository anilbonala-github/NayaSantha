-- Hyderabad pilot catalogue (Vol1 §18.1: produce, dairy, eggs, staples).
-- Seed/operational data loaded by the database, not embedded in the app.

INSERT INTO categories (name, slug, emoji, sort_order) VALUES
    ('Vegetables',       'vegetables',   '🥬', 1),
    ('Fruits',           'fruits',       '🍎', 2),
    ('Dairy & Eggs',     'dairy-eggs',   '🥛', 3),
    ('Staples & Grains', 'staples',      '🌾', 4),
    ('Spices & Masala',  'spices',       '🌶️', 5)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO products (sku, name, category_id, unit, emoji, origin, rating, rating_count, badges)
SELECT v.sku, v.name, c.id, v.unit, v.emoji, v.origin, v.rating, v.rc, v.badges
FROM (VALUES
    ('p_tomato',  'Tomato',            'vegetables', '1 kg',  '🍅', 'Telangana',      4.6, 120, 'Farm Fresh,No Chemicals'),
    ('p_onion',   'Onion',             'vegetables', '1 kg',  '🧅', 'Kurnool',        4.4, 98,  'Farm Fresh'),
    ('p_potato',  'Potato',            'vegetables', '1 kg',  '🥔', 'Local',          4.5, 76,  'Farm Fresh'),
    ('p_carrot',  'Carrot',            'vegetables', '500 g', '🥕', 'Ooty',           4.7, 54,  'Farm Fresh'),
    ('p_capsicum','Capsicum',          'vegetables', '500 g', '🫑', 'Local',          4.3, 41,  'No Chemicals'),
    ('p_spinach', 'Palak (Spinach)',   'vegetables', '250 g', '🥬', 'Local',          4.6, 63,  'Farm Fresh,No Chemicals'),
    ('p_banana',  'Banana',            'fruits',     '1 dozen','🍌','Cuddapah',       4.5, 88,  'Farm Fresh'),
    ('p_apple',   'Apple (Shimla)',    'fruits',     '1 kg',  '🍎', 'Himachal',       4.4, 70,  ''),
    ('p_milk',    'Full Cream Milk',   'dairy-eggs', '1 L',   '🥛', 'Local Dairy',    4.8, 210, 'Daily Fresh'),
    ('p_curd',    'Curd',              'dairy-eggs', '500 g', '🍶', 'Local Dairy',    4.6, 95,  'Daily Fresh'),
    ('p_eggs',    'Eggs',              'dairy-eggs', '6 pcs', '🥚', 'Local Farm',     4.7, 130, 'Farm Fresh'),
    ('p_paneer',  'Paneer',            'dairy-eggs', '200 g', '🧀', 'Local Dairy',    4.5, 60,  'Daily Fresh'),
    ('p_rice',    'Sona Masoori Rice', 'staples',    '5 kg',  '🍚', 'Telangana',      4.7, 180, 'Premium'),
    ('p_atta',    'Whole Wheat Atta',  'staples',    '5 kg',  '🌾', 'Local',          4.6, 150, 'Chakki Fresh'),
    ('p_toordal', 'Toor Dal',          'staples',    '1 kg',  '🫘', 'Maharashtra',    4.6, 110, ''),
    ('p_oil',     'Groundnut Oil',     'staples',    '1 L',   '🛢️', 'Local',          4.4, 90,  ''),
    ('p_chilli',  'Red Chilli Powder', 'spices',     '200 g', '🌶️', 'Guntur',         4.7, 140, 'Guntur Special'),
    ('p_turmeric','Turmeric Powder',   'spices',     '200 g', '🟡', 'Nizamabad',      4.6, 85,  '')
) AS v(sku, name, cat_slug, unit, emoji, origin, rating, rc, badges)
JOIN categories c ON c.slug = v.cat_slug
ON CONFLICT (sku) DO NOTHING;

INSERT INTO product_prices (product_id, mrp, forecast_price, selling_price, max_price)
SELECT p.id, v.mrp, v.forecast, v.selling, v.maxp
FROM (VALUES
    ('p_tomato',   50.00,  38.00,  40.00,  46.00),
    ('p_onion',    45.00,  34.00,  35.00,  42.00),
    ('p_potato',   40.00,  30.00,  32.00,  38.00),
    ('p_carrot',   40.00,  32.00,  34.00,  40.00),
    ('p_capsicum', 45.00,  36.00,  38.00,  46.00),
    ('p_spinach',  25.00,  18.00,  20.00,  24.00),
    ('p_banana',   60.00,  48.00,  50.00,  56.00),
    ('p_apple',   180.00, 150.00, 160.00, 180.00),
    ('p_milk',     72.00,  70.00,  70.00,  72.00),
    ('p_curd',     45.00,  42.00,  42.00,  45.00),
    ('p_eggs',     54.00,  48.00,  50.00,  54.00),
    ('p_paneer',   95.00,  88.00,  90.00,  96.00),
    ('p_rice',    420.00, 400.00, 405.00, 420.00),
    ('p_atta',    280.00, 245.00, 250.00, 265.00),
    ('p_toordal', 160.00, 145.00, 150.00, 165.00),
    ('p_oil',     220.00, 200.00, 205.00, 220.00),
    ('p_chilli',  120.00, 105.00, 110.00, 120.00),
    ('p_turmeric', 90.00,  78.00,  80.00,  88.00)
) AS v(sku, mrp, forecast, selling, maxp)
JOIN products p ON p.sku = v.sku
ON CONFLICT DO NOTHING;
