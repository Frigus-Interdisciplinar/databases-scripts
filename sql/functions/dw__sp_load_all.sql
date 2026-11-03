CREATE OR REPLACE FUNCTION dw.sp_load_all()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'dw', 'public', 'pg_temp'
AS $function$
BEGIN
  INSERT INTO dw.dim_group (group_id, group_name)
  SELECT g.id, g.name
  FROM public.groups g
  WHERE g.deleted_at IS NULL
  ON CONFLICT (group_id) DO UPDATE
    SET group_name = EXCLUDED.group_name;

  INSERT INTO dw.dim_stock (stock_id, stock_name, group_key)
  SELECT s.id, s.name, dg.group_key
  FROM public.stocks s
  JOIN dw.dim_group dg ON dg.group_id = s.group_id
  WHERE s.deleted_at IS NULL
  ON CONFLICT (stock_id) DO UPDATE
    SET stock_name = EXCLUDED.stock_name,
        group_key  = EXCLUDED.group_key;

  INSERT INTO dw.dim_product (product_id, product_name, category, storage_place, unit_of_measure, brand)
  SELECT p.id, p.name, p.category::text, p.storage_place::text, p.unit_of_measure::text, p.brand
  FROM public.products p
  ON CONFLICT (product_id) DO UPDATE
    SET product_name    = EXCLUDED.product_name,
        category        = EXCLUDED.category,
        storage_place   = EXCLUDED.storage_place,
        unit_of_measure = EXCLUDED.unit_of_measure,
        brand           = EXCLUDED.brand;

  INSERT INTO dw.dim_user (user_id, user_name, account_type)
  SELECT u.id, u.name, u.account_type::text
  FROM public.users u
  WHERE u.deleted_at IS NULL
  ON CONFLICT (user_id) DO UPDATE
    SET user_name    = EXCLUDED.user_name,
        account_type = EXCLUDED.account_type;

  INSERT INTO dw.dim_date (date_key, year, month, week_start, day_of_week, is_weekend)
  SELECT
    d::date,
    EXTRACT(YEAR FROM d)::int,
    EXTRACT(MONTH FROM d)::int,
    DATE_TRUNC('week', d)::date,
    EXTRACT(ISODOW FROM d)::int,
    EXTRACT(ISODOW FROM d) IN (6, 7)
  FROM generate_series('2024-01-01'::date, (CURRENT_DATE + 365)::date, INTERVAL '1 day') AS d
  ON CONFLICT (date_key) DO NOTHING;

  TRUNCATE dw.fact_stock_movement;

  INSERT INTO dw.fact_stock_movement (
    movement_id, date_key, moved_at, product_key, stock_key, group_key,
    user_key, movement_type, quantity, balance_after_source, purpose
  )
  WITH src AS (
    SELECT
      sm.id,
      sm.date,
      sm.movement_type::text AS movement_type,
      sm.quantity,
      sm.balance_after,
      sm.purpose,
      sm.user_id,
      sp.product_id,
      sp.stock_id
    FROM public.stock_movements sm
    JOIN public.stock_products sp ON sp.id = sm.stock_product_id
    JOIN public.stocks s          ON s.id  = sp.stock_id
  )
  SELECT
    src.id,
    src.date::date,
    src.date,
    dp.product_key,
    ds.stock_key,
    ds.group_key,
    du.user_key,
    src.movement_type,
    src.quantity,
    src.balance_after,
    src.purpose
  FROM src
  JOIN dw.dim_product dp   ON dp.product_id = src.product_id
  JOIN dw.dim_stock   ds   ON ds.stock_id   = src.stock_id
  LEFT JOIN dw.dim_user du ON du.user_id    = src.user_id;
END;
$function$
