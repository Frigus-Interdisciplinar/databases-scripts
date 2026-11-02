CREATE OR REPLACE FUNCTION public.trg_fn_notify_shopping_list_product_added()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_group_id UUID;
BEGIN
    SELECT s.group_id INTO v_group_id
      FROM shopping_lists sl
      JOIN stocks s ON s.id = sl.stock_id
      JOIN groups g ON g.id = s.group_id
      JOIN users u ON u.id = g.owner_id
     WHERE sl.id = NEW.list_id
       AND u.account_type IN ('DOMESTIC', 'COMMERCIAL');

    IF v_group_id IS NULL THEN
        RETURN NEW;
    END IF;

    INSERT INTO notifications (
        recipient_user_id, group_id, type, title, body, reference_id, deduplication_key
    )
    SELECT ug.user_id, v_group_id, 'SHOPPING_LIST_PRODUCT_ADDED',
           'Item adicionado à lista de compras',
           'Um novo item foi adicionado à lista de compras do grupo.',
           NEW.id::VARCHAR,
           'shopping-list-product:' || NEW.id::VARCHAR || ':' || ug.user_id::VARCHAR
      FROM user_groups ug
     WHERE ug.group_id = v_group_id
    ON CONFLICT (deduplication_key) WHERE deduplication_key IS NOT NULL DO NOTHING;

    RETURN NEW;
END;
$function$
