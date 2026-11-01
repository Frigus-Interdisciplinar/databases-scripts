CREATE OR REPLACE FUNCTION public.fn_compute_product_status_enum(p_expire_date date, p_warn_days integer DEFAULT 3)
 RETURNS product_status_enum
 LANGUAGE sql
 STABLE
AS $function$
    SELECT CASE
        WHEN p_expire_date < CURRENT_DATE THEN 'EXPIRED'::product_status_enum
        WHEN p_expire_date <= CURRENT_DATE + p_warn_days THEN 'NEAR_EXPIRATION'::product_status_enum
        ELSE 'FRESH'::product_status_enum
    END;
$function$
