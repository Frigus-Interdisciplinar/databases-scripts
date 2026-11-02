-- Procedures de negócio com ids uuid (users, shopping_lists e conversations são uuid).
-- As versões integer não funcionavam com os ids reais. Remove as antigas e cria as novas.
-- sp_purchase_shopping_list_item não depende de trigger em stock_movements (não existe no banco):
-- a própria procedure soma a quantidade no estoque.

DROP PROCEDURE IF EXISTS public.sp_close_shopping_list(integer);
DROP PROCEDURE IF EXISTS public.sp_get_or_create_private_conversation(integer, integer, integer);
DROP PROCEDURE IF EXISTS public.sp_purchase_shopping_list_item(integer, integer, integer, integer, integer, date, integer);

CREATE OR REPLACE PROCEDURE public.sp_close_shopping_list(IN p_list_id uuid)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM shopping_lists WHERE id = p_list_id) THEN
        RAISE EXCEPTION 'lista % nao existe', p_list_id;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM shopping_list_products
                    WHERE list_id = p_list_id AND status NOT IN ('PURCHASED', 'REMOVED')) THEN
        UPDATE shopping_lists SET status = 'COMPLETED' WHERE id = p_list_id;
    END IF;
END $$;

CREATE OR REPLACE PROCEDURE public.sp_get_or_create_private_conversation(
    IN p_user_a uuid, IN p_user_b uuid, INOUT p_conversation_id uuid DEFAULT NULL)
LANGUAGE plpgsql AS $$
DECLARE v_key varchar := fn_pair_key(p_user_a, p_user_b);
BEGIN
    IF p_user_a = p_user_b THEN RAISE EXCEPTION 'usuarios iguais'; END IF;
    SELECT id INTO p_conversation_id FROM conversations WHERE pair_key = v_key;
    IF p_conversation_id IS NULL THEN
        INSERT INTO conversations (conversation_type, pair_key) VALUES ('PRIVATE', v_key)
        RETURNING id INTO p_conversation_id;
        INSERT INTO conversation_participants (conversation_id, user_id)
        VALUES (p_conversation_id, p_user_a), (p_conversation_id, p_user_b);
    END IF;
END $$;

CREATE OR REPLACE PROCEDURE public.sp_purchase_shopping_list_item(
    IN p_list_id uuid, IN p_product_id integer, IN p_stock_id integer, IN p_quantity integer,
    IN p_expire_date date, IN p_user_id uuid, INOUT p_stock_product_id integer DEFAULT NULL)
LANGUAGE plpgsql AS $$
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
END $$;
