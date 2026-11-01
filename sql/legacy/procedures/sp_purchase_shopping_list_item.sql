-- ponytail: stock_products.id não é gerado pelo banco (INTEGER PK simples, sem SERIAL),
-- então quem chama precisa informar o id a usar caso vá criar uma linha nova.
CREATE OR REPLACE PROCEDURE sp_purchase_shopping_list_item(
    p_list_id           INTEGER,
    p_product_id        INTEGER,
    p_stock_id          INTEGER,
    p_stock_product_id  INTEGER,
    p_quantity          INTEGER,
    p_expire_date       DATE,
    p_user_id           INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE shopping_list_products
       SET status = 'Comprado'
     WHERE list_id = p_list_id
       AND product_id = p_product_id;

    INSERT INTO stock_products (id, product_id, stock_id, quantity, expire_date, category)
    SELECT p_stock_product_id, p_product_id, p_stock_id, 0, p_expire_date, category
    FROM products
    WHERE id = p_product_id
    ON CONFLICT (product_id, stock_id, expire_date) DO NOTHING;

    INSERT INTO stock_movements (stock_product_id, user_id, movement_type, quantity)
    VALUES (p_stock_product_id, p_user_id, 'Entrada', p_quantity);
    -- trg_stock_movements_apply soma p_quantity em stock_products.quantity
END;
$$;
