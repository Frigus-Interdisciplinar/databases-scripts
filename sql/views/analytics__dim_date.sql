CREATE OR REPLACE VIEW "analytics"."dim_date" WITH (security_invoker=true) AS
 WITH source_dates AS (
         SELECT transactions.created_at::date AS d
           FROM transactions
          WHERE transactions.created_at IS NOT NULL
        UNION ALL
         SELECT stock_movements.date::date AS date
           FROM stock_movements
          WHERE stock_movements.date IS NOT NULL
        UNION ALL
         SELECT stock_products.created_at::date AS created_at
           FROM stock_products
          WHERE stock_products.created_at IS NOT NULL
        ), bounds AS (
         SELECT LEAST(COALESCE(min(source_dates.d), CURRENT_DATE), CURRENT_DATE) AS start_date,
            GREATEST(COALESCE(max(source_dates.d), CURRENT_DATE), CURRENT_DATE) AS end_date
           FROM source_dates
        )
 SELECT generated.day::date AS date_key,
    EXTRACT(year FROM generated.day)::integer AS calendar_year,
    EXTRACT(quarter FROM generated.day)::integer AS calendar_quarter,
    EXTRACT(month FROM generated.day)::integer AS calendar_month,
    EXTRACT(day FROM generated.day)::integer AS day_of_month,
    EXTRACT(isodow FROM generated.day)::integer AS iso_day_of_week,
    EXTRACT(isodow FROM generated.day)::integer = ANY (ARRAY[6, 7]) AS is_weekend
   FROM bounds
     CROSS JOIN LATERAL generate_series(bounds.start_date::timestamp without time zone, bounds.end_date::timestamp without time zone, '1 day'::interval) generated(day);
