CREATE OR REPLACE FUNCTION public.fn_low_stock_products(p_stock_id integer)
 RETURNS TABLE(stock_product_id integer, product_id integer, product_name character varying, quantity integer, minimal_quantity integer)
 LANGUAGE sql
 STABLE
AS $function$
    SELECT sp.id, sp.product_id, p.name, sp.quantity, sp.minimal_quantity
    FROM stock_products sp
    JOIN products p ON p.id = sp.product_id
    WHERE sp.stock_id = p_stock_id
      AND sp.minimal_quantity IS NOT NULL
      AND sp.quantity < sp.minimal_quantity;
$function$
