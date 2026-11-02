CREATE OR REPLACE VIEW "public"."vw_dm_group_summary" AS
 WITH stock_agg AS (
         SELECT s.group_id,
            count(DISTINCT s.id) AS stocks,
            count(sp.id) FILTER (WHERE sp.deleted_at IS NULL AND sp.quantity > 0) AS active_items,
            count(sp.id) FILTER (WHERE sp.deleted_at IS NULL AND sp.quantity > 0 AND sp.expire_date >= CURRENT_DATE AND sp.expire_date <= (CURRENT_DATE + 7)) AS expiring_7d,
            count(sp.id) FILTER (WHERE sp.deleted_at IS NULL AND sp.quantity > 0 AND sp.product_status = 'EXPIRED'::product_status_enum) AS expired_items
           FROM stocks s
             LEFT JOIN stock_products sp ON sp.stock_id = s.id
          WHERE s.deleted_at IS NULL
          GROUP BY s.group_id
        ), members AS (
         SELECT user_groups.group_id,
            count(*) AS members
           FROM user_groups
          GROUP BY user_groups.group_id
        )
 SELECT g.id AS group_id,
    g.name AS group_name,
    g.created_at::date AS created_date,
    COALESCE(m.members, 0::bigint) AS members,
    COALESCE(sa.stocks, 0::bigint) AS stocks,
    COALESCE(sa.active_items, 0::bigint) AS active_items,
    COALESCE(sa.expiring_7d, 0::bigint) AS expiring_7d,
    COALESCE(sa.expired_items, 0::bigint) AS expired_items
   FROM groups g
     LEFT JOIN stock_agg sa ON sa.group_id = g.id
     LEFT JOIN members m ON m.group_id = g.id
  WHERE g.deleted_at IS NULL;
