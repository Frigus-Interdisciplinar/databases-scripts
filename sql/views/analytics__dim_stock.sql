CREATE OR REPLACE VIEW "analytics"."dim_stock" WITH (security_invoker=true) AS
 SELECT s.id AS stock_key,
    s.name AS stock_name,
    s.group_id,
    g.name AS group_name
   FROM stocks s
     LEFT JOIN groups g ON g.id = s.group_id
  WHERE s.deleted_at IS NULL;
