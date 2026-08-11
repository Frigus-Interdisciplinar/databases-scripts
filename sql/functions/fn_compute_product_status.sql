CREATE OR REPLACE FUNCTION fn_compute_product_status(
    p_expire_date DATE,
    p_warn_days   INTEGER DEFAULT 3
) RETURNS product_status_enum
LANGUAGE sql
STABLE
AS $$
    SELECT CASE
        WHEN p_expire_date < CURRENT_DATE THEN 'Vencido'::product_status_enum
        WHEN p_expire_date <= CURRENT_DATE + p_warn_days THEN 'Próximo do vencimento'::product_status_enum
        ELSE 'Fresco'::product_status_enum
    END;
$$;
