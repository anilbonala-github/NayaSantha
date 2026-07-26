-- Recipes (Vol1/2 recipes module). Ingredients link to catalogue products so a
-- recipe can drop straight into the basket.
CREATE TABLE recipes (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code         VARCHAR(40) NOT NULL UNIQUE,
    title        VARCHAR(120) NOT NULL,
    description  TEXT,
    emoji        VARCHAR(12),
    cuisine      VARCHAR(40),
    servings     INT NOT NULL DEFAULT 4,
    prep_minutes INT NOT NULL DEFAULT 30,
    sort_order   INT NOT NULL DEFAULT 0,
    active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE recipe_ingredients (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id  UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity   INT NOT NULL DEFAULT 1,
    note       VARCHAR(120)
);
CREATE INDEX idx_recipe_ingredients_recipe ON recipe_ingredients(recipe_id);

INSERT INTO recipes (code, title, description, emoji, cuisine, servings, prep_minutes, sort_order) VALUES
 ('palak_paneer', 'Palak Paneer', 'Creamy spinach with soft paneer cubes — a weeknight favourite.', '🥬', 'North Indian', 4, 30, 1),
 ('dal_tadka',    'Dal Tadka',    'Comforting toor dal tempered with onion, tomato and spices.',      '🫘', 'North Indian', 4, 35, 2),
 ('egg_curry',    'Egg Curry',    'Boiled eggs simmered in a spiced onion-tomato gravy.',             '🥚', 'South Indian', 3, 30, 3),
 ('veg_pulao',    'Veg Pulao',    'Fragrant rice with carrot and capsicum — one-pot and quick.',      '🍚', 'Indian',       4, 25, 4),
 ('aloo_curry',   'Aloo Curry',   'Everyday potato curry, great with rice or roti.',                  '🥔', 'South Indian', 4, 25, 5);

-- Ingredients (product_id resolved from SKU).
INSERT INTO recipe_ingredients (recipe_id, product_id, quantity)
SELECT r.id, p.id, x.qty FROM (VALUES
  ('palak_paneer','p_spinach',2), ('palak_paneer','p_paneer',1), ('palak_paneer','p_onion',1),
  ('palak_paneer','p_tomato',1), ('palak_paneer','p_oil',1), ('palak_paneer','p_turmeric',1), ('palak_paneer','p_chilli',1),
  ('dal_tadka','p_toordal',1), ('dal_tadka','p_onion',1), ('dal_tadka','p_tomato',1),
  ('dal_tadka','p_oil',1), ('dal_tadka','p_turmeric',1), ('dal_tadka','p_chilli',1),
  ('egg_curry','p_eggs',2), ('egg_curry','p_onion',1), ('egg_curry','p_tomato',1),
  ('egg_curry','p_oil',1), ('egg_curry','p_chilli',1),
  ('veg_pulao','p_rice',1), ('veg_pulao','p_carrot',1), ('veg_pulao','p_capsicum',1),
  ('veg_pulao','p_onion',1), ('veg_pulao','p_oil',1),
  ('aloo_curry','p_potato',2), ('aloo_curry','p_onion',1), ('aloo_curry','p_tomato',1),
  ('aloo_curry','p_oil',1), ('aloo_curry','p_turmeric',1), ('aloo_curry','p_chilli',1)
) AS x(rcode, sku, qty)
JOIN recipes r  ON r.code = x.rcode
JOIN products p ON p.sku  = x.sku;
