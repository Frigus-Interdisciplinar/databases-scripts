CREATE OR REPLACE FUNCTION public.trg_fn_products_propagate_category()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
BEGIN
    UPDATE public.stock_products SET category = NEW.category WHERE product_id = NEW.id;
    RETURN NEW;
END;
$function$
