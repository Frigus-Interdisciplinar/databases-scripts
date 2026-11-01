CREATE OR REPLACE PROCEDURE public.sp_purchase_shopping_list_item(IN p_list_id integer, IN p_product_id integer, IN p_stock_id integer, IN p_stock_product_id integer, IN p_quantity integer, IN p_expire_date date, IN p_user_id integer)
 LANGUAGE plpgsql
AS $procedure$
BEGIN
    UPDATE shopping_list_products
       SET status = 'PURCHASED'
     WHERE list_id = p_list_id
       AND product_id = p_product_id;

    INSERT INTO stock_products (id, product_id, stock_id, quantity, expire_date, category)
    SELECT p_stock_product_id, p_product_id, p_stock_id, 0, p_expire_date, category
    FROM products
    WHERE id = p_product_id
    ON CONFLICT (product_id, stock_id, expire_date) DO NOTHING;

    INSERT INTO stock_movements (stock_product_id, user_id, movement_type, quantity)
    VALUES (p_stock_product_id, p_user_id, 'IN', p_quantity);
    -- trg_stock_movements_apply soma p_quantity em stock_products.quantity
END;
$procedure$
