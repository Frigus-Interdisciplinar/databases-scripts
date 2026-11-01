CREATE OR REPLACE FUNCTION fn_low_stock_products(p_stock_id INTEGER)
RETURNS TABLE (
    stock_product_id INTEGER,
    product_id       INTEGER,
    product_name     VARCHAR,
    quantity         INTEGER,
    minimal_quantity INTEGER
)
LANGUAGE sql
STABLE
AS $$
    SELECT sp.id, sp.product_id, p.name, sp.quantity, sp.minimal_quantity
    FROM stock_products sp
    JOIN products p ON p.id = sp.product_id
    WHERE sp.stock_id = p_stock_id
      AND sp.minimal_quantity IS NOT NULL
      AND sp.quantity < sp.minimal_quantity;
$$;
