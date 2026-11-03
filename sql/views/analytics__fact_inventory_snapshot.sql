CREATE OR REPLACE VIEW "analytics"."fact_inventory_snapshot" WITH (security_invoker=true) AS
 SELECT id AS inventory_row_key,
    stock_id AS stock_key,
    product_id AS product_key,
    quantity,
    minimal_quantity,
    expire_date,
    product_status,
    created_at::date AS created_date_key,
    updated_at::date AS updated_date_key
   FROM stock_products sp;
