CREATE OR REPLACE FUNCTION public.fn_compute_product_status(p_expire_date date, p_warn_days integer DEFAULT 3)
 RETURNS character varying
 LANGUAGE sql
 STABLE
AS $function$
    SELECT CASE fn_compute_product_status_enum(p_expire_date, p_warn_days)
        WHEN 'EXPIRED'::product_status_enum         THEN 'Vencido'
        WHEN 'NEAR_EXPIRATION'::product_status_enum THEN 'Próximo do vencimento'
        WHEN 'FRESH'::product_status_enum           THEN 'Fresco'
    END;
$function$
