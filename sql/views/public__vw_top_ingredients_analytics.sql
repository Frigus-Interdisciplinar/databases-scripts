CREATE OR REPLACE VIEW "public"."vw_top_ingredients_analytics" AS
 WITH ingredient_suggestions AS (
         SELECT ri.product_id,
            p.name,
            p.category,
            p.unit_price,
            count(DISTINCT rs.id) AS suggestion_count,
            count(DISTINCT rs.stock_id) AS unique_stocks,
            round(avg(rs.score), 2) AS avg_suggestion_score,
            max(rs.updated_at) AS last_suggested_date
           FROM recipe_ingredients ri
             JOIN products p ON ri.product_id = p.id
             LEFT JOIN recipe_suggestions rs ON rs.recipe_id = ri.recipe_id
          WHERE ri.required = true
          GROUP BY ri.product_id, p.name, p.category, p.unit_price
        )
 SELECT row_number() OVER (ORDER BY suggestion_count DESC) AS popularity_rank,
    rank() OVER (PARTITION BY category ORDER BY suggestion_count DESC) AS category_rank,
    product_id,
    name,
    category,
    suggestion_count,
    unique_stocks,
    avg_suggestion_score,
    unit_price,
    round(suggestion_count::numeric / sum(suggestion_count) OVER () * 100::numeric, 2) AS percentage_of_total_suggestions,
    first_value(name) OVER (PARTITION BY category ORDER BY suggestion_count DESC) AS top_ingredient_in_category,
    last_suggested_date,
    CURRENT_TIMESTAMP AS view_updated_at
   FROM ingredient_suggestions;
