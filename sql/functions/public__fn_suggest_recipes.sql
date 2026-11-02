CREATE OR REPLACE FUNCTION public.fn_suggest_recipes(p_stock_id integer)
 RETURNS TABLE(recipe_id integer, matched_ingredients integer, missing_ingredients integer, nearest_expire_date date, score numeric)
 LANGUAGE sql
 STABLE
AS $function$
    WITH ingredient_match AS (
        SELECT
            ri.recipe_id,
            ri.product_id,
            bool_or(sp.id IS NOT NULL)  AS in_stock,
            MIN(sp.expire_date)          AS earliest_expire_date
        FROM recipe_ingredients ri
        LEFT JOIN stock_products sp
            ON sp.product_id = ri.product_id
           AND sp.stock_id = p_stock_id
        GROUP BY ri.recipe_id, ri.product_id
    )
    SELECT
        recipe_id,
        COUNT(*) FILTER (WHERE in_stock)::INTEGER      AS matched_ingredients,
        COUNT(*) FILTER (WHERE NOT in_stock)::INTEGER  AS missing_ingredients,
        MIN(earliest_expire_date)                       AS nearest_expire_date,
        ROUND(COUNT(*) FILTER (WHERE in_stock)::NUMERIC / NULLIF(COUNT(*), 0), 2) AS score
    FROM ingredient_match
    GROUP BY recipe_id;
$function$
