CREATE OR REPLACE VIEW analytics.vw_category_tree AS
WITH RECURSIVE tree AS (
    SELECT id, name, parent_id, 0 AS depth, name::text AS path
    FROM public.product_categories WHERE parent_id IS NULL
    UNION ALL
    SELECT c.id, c.name, c.parent_id, t.depth + 1, t.path || ' > ' || c.name
    FROM public.product_categories c JOIN tree t ON c.parent_id = t.id
),
closure AS (
    SELECT id AS leaf_id, id AS ancestor_id, parent_id FROM public.product_categories
    UNION ALL
    SELECT cl.leaf_id, p.id, p.parent_id
    FROM closure cl JOIN public.product_categories p ON p.id = cl.parent_id
),
rollup AS (
    SELECT cl.ancestor_id AS id, COUNT(pr.id) AS products
    FROM closure cl
    JOIN public.product_categories leaf ON leaf.id = cl.leaf_id
    LEFT JOIN public.products pr ON pr.category = leaf.enum_value
    GROUP BY cl.ancestor_id
)
SELECT t.id, t.name, t.parent_id, t.depth, t.path, COALESCE(r.products, 0) AS products_total,
       SUM(COALESCE(r.products, 0)) FILTER (WHERE t.depth = 0) OVER () AS products_all_roots
FROM tree t LEFT JOIN rollup r ON r.id = t.id;
