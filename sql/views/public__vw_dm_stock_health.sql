CREATE OR REPLACE VIEW "public"."vw_dm_stock_health" AS
 WITH stock_items AS (
         SELECT sp.stock_id,
            count(*) FILTER (WHERE sp.deleted_at IS NULL AND sp.quantity > 0) AS active_items,
            COALESCE(sum(sp.quantity) FILTER (WHERE sp.deleted_at IS NULL), 0::bigint) AS total_qty,
            count(*) FILTER (WHERE sp.deleted_at IS NULL AND sp.quantity > 0 AND sp.product_status = 'EXPIRED'::product_status_enum) AS expired_items,
            count(*) FILTER (WHERE sp.deleted_at IS NULL AND sp.quantity > 0 AND sp.expire_date >= CURRENT_DATE AND sp.expire_date <= (CURRENT_DATE + 7)) AS expiring_7d,
            count(*) FILTER (WHERE sp.deleted_at IS NULL AND sp.minimal_quantity IS NOT NULL AND sp.quantity < sp.minimal_quantity) AS below_minimal
           FROM stock_products sp
          GROUP BY sp.stock_id
        ), stock_moves AS (
         SELECT sp.stock_id,
            COALESCE(sum(sm_1.quantity) FILTER (WHERE sm_1.movement_type = 'IN'::movement_type_enum AND sm_1.date >= (CURRENT_DATE - 30)), 0::bigint) AS in_30d,
            COALESCE(sum(sm_1.quantity) FILTER (WHERE sm_1.movement_type = 'OUT'::movement_type_enum AND sm_1.date >= (CURRENT_DATE - 30)), 0::bigint) AS out_30d
           FROM stock_movements sm_1
             JOIN stock_products sp ON sp.id = sm_1.stock_product_id
          GROUP BY sp.stock_id
        )
 SELECT s.id AS stock_id,
    s.name AS stock_name,
    g.id AS group_id,
    g.name AS group_name,
    COALESCE(si.active_items, 0::bigint) AS active_items,
    COALESCE(si.total_qty, 0::bigint) AS total_qty,
    COALESCE(si.expired_items, 0::bigint) AS expired_items,
    COALESCE(si.expiring_7d, 0::bigint) AS expiring_7d,
    COALESCE(si.below_minimal, 0::bigint) AS below_minimal,
    COALESCE(sm.in_30d, 0::bigint) AS in_30d,
    COALESCE(sm.out_30d, 0::bigint) AS out_30d
   FROM stocks s
     JOIN groups g ON g.id = s.group_id
     LEFT JOIN stock_items si ON si.stock_id = s.id
     LEFT JOIN stock_moves sm ON sm.stock_id = s.id
  WHERE s.deleted_at IS NULL;
