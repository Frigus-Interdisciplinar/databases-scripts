CREATE OR REPLACE PROCEDURE public.sp_close_shopping_list(IN p_list_id uuid)
 LANGUAGE plpgsql
AS $procedure$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM shopping_lists WHERE id = p_list_id) THEN
        RAISE EXCEPTION 'lista % nao existe', p_list_id;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM shopping_list_products
                    WHERE list_id = p_list_id AND status NOT IN ('PURCHASED', 'REMOVED')) THEN
        UPDATE shopping_lists SET status = 'COMPLETED' WHERE id = p_list_id;
    END IF;
END $procedure$
