CREATE OR REPLACE VIEW "analytics"."dim_plan" WITH (security_invoker=true) AS
 SELECT id AS plan_key,
    plan_code,
    name AS plan_name,
    billing_interval,
    active
   FROM plans p
  WHERE deleted_at IS NULL;
