-- Consultas SELECT para EXPLAIN ANALYZE no FrigusDB Dev.
-- O comando executa a consulta para medir tempo; nao usar em DML sem revisar.

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT date_key, COUNT(*) AS movement_count, SUM(quantity) AS net_quantity
FROM dw.fact_stock_movement
WHERE date_key >= CURRENT_DATE - 30
GROUP BY date_key
ORDER BY date_key;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT date_key, movement_type, COUNT(*) AS movement_count, SUM(quantity) AS quantity
FROM dw.fact_stock_movement
WHERE stock_key = (SELECT stock_key FROM dw.dim_stock ORDER BY stock_key LIMIT 1)
  AND date_key >= CURRENT_DATE - 90
GROUP BY date_key, movement_type
ORDER BY date_key;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT sm.date::date AS movement_day, sp.stock_id, COUNT(*) AS movement_count
FROM public.stock_movements sm
JOIN public.stock_products sp ON sp.id = sm.stock_product_id
WHERE sm.date >= (now() - INTERVAL '30 days')::timestamp
GROUP BY sm.date::date, sp.stock_id
ORDER BY movement_day, sp.stock_id;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT * FROM dw.vw_dau
WHERE day >= CURRENT_DATE - 30
ORDER BY day;
