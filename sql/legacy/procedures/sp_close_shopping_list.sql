CREATE OR REPLACE PROCEDURE sp_close_shopping_list(p_list_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM shopping_list_products
        WHERE list_id = p_list_id
          AND status NOT IN ('Comprado', 'Removido')
    ) THEN
        UPDATE shopping_lists
           SET status = 'Concluída'
         WHERE id = p_list_id;
    END IF;
END;
$$;
