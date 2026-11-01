CREATE OR REPLACE FUNCTION public.trg_fn_stock_products_set_initial_quantity()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.initial_quantity IS NULL THEN
        NEW.initial_quantity := COALESCE(NEW.quantity, 1);
    END IF;
    RETURN NEW;
END;
$function$
