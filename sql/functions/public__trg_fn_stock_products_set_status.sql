CREATE OR REPLACE FUNCTION public.trg_fn_stock_products_set_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- usa a versão que retorna o enum (valores em inglês), não a versão
    -- de exibição em português, já que a coluna é do tipo product_status_enum.
    NEW.product_status := fn_compute_product_status_enum(NEW.expire_date);
    RETURN NEW;
END;
$function$
