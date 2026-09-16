-- A checked-out basket can create only one order, including retries after a lost response.
ALTER TABLE orders ADD COLUMN basket_id UUID REFERENCES baskets(id);
CREATE UNIQUE INDEX uq_order_basket ON orders(basket_id) WHERE basket_id IS NOT NULL;
