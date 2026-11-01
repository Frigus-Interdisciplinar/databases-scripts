CREATE OR REPLACE VIEW "analytics"."dim_product" WITH (security_invoker=true) AS
 SELECT id AS product_key,
    name AS product_name,
    category,
    storage_place,
    unit_of_measure,
    unit_price
   FROM products p;
