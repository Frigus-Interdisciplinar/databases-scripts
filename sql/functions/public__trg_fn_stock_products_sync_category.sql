CREATE OR REPLACE FUNCTION public.trg_fn_stock_products_sync_category()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
DECLARE
    v_category public.category_enum;
BEGIN
    SELECT p.category INTO v_category FROM public.products AS p WHERE p.id = NEW.product_id;
    IF FOUND THEN
        NEW.category := v_category;
    END IF;
    RETURN NEW;
END;
$function$
