CREATE OR REPLACE PROCEDURE public.sp_purchase_shopping_list_item(IN p_list_id uuid, IN p_product_id integer, IN p_stock_id integer, IN p_quantity integer, IN p_expire_date date, IN p_user_id uuid, INOUT p_stock_product_id integer DEFAULT NULL::integer)
 LANGUAGE plpgsql
AS $procedure$
BEGIN
    IF p_quantity IS NULL OR p_quantity <= 0 THEN RAISE EXCEPTION 'quantidade invalida'; END IF;

    UPDATE shopping_list_products SET status = 'PURCHASED'
     WHERE list_id = p_list_id AND product_id = p_product_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'item do produto % nao esta na lista %', p_product_id, p_list_id; END IF;

    SELECT id INTO p_stock_product_id FROM stock_products
     WHERE product_id = p_product_id AND stock_id = p_stock_id AND expire_date = p_expire_date;
    IF p_stock_product_id IS NULL THEN
        INSERT INTO stock_products (product_id, stock_id, quantity, expire_date, category)
        SELECT id, p_stock_id, 0, p_expire_date, category FROM products WHERE id = p_product_id
        RETURNING id INTO p_stock_product_id;
    END IF;

    INSERT INTO stock_movements (stock_product_id, user_id, movement_type, quantity)
    VALUES (p_stock_product_id, p_user_id, 'IN', p_quantity);
    UPDATE stock_products SET quantity = quantity + p_quantity WHERE id = p_stock_product_id;
END $procedure$
