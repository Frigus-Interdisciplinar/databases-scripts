CREATE OR REPLACE VIEW "public"."vw_user_engagement_analytics" AS
 WITH user_activity AS (
         SELECT u_1.id,
            u_1.name,
            u_1.account_type,
            u_1.created_at AS user_created_at,
            count(DISTINCT m.id) AS total_messages,
            count(DISTINCT sm.id) AS total_stock_movements,
            count(DISTINCT r.id) AS total_requests,
            count(DISTINCT
                CASE
                    WHEN m.created_at >= (now() - '30 days'::interval) THEN m.id
                    ELSE NULL::integer
                END) AS messages_last_30d,
            count(DISTINCT
                CASE
                    WHEN sm.date >= (now() - '30 days'::interval) THEN sm.id
                    ELSE NULL::integer
                END) AS movements_last_30d,
            max(m.created_at) AS last_message_date,
            max(sm.date) AS last_movement_date,
            GREATEST(max(m.created_at), max(sm.date), max(r.date)::timestamp without time zone) AS overall_last_activity
           FROM users u_1
             LEFT JOIN messages m ON u_1.id = m.sender_id
             LEFT JOIN stock_movements sm ON u_1.id = sm.user_id
             LEFT JOIN requests r ON u_1.id = r.user_id
          GROUP BY u_1.id, u_1.name, u_1.account_type, u_1.created_at
        )
 SELECT id,
    name,
    account_type,
    user_created_at,
    total_messages,
    total_stock_movements,
    total_requests,
    messages_last_30d,
    movements_last_30d,
    total_messages::numeric * 0.4 + total_stock_movements::numeric * 0.35 + total_requests::numeric * 0.25 AS engagement_score,
    rank() OVER (ORDER BY total_messages DESC) AS message_rank,
    dense_rank() OVER (PARTITION BY account_type ORDER BY total_stock_movements DESC) AS movement_rank_by_type,
    row_number() OVER (ORDER BY overall_last_activity DESC NULLS LAST) AS activity_recency_rank,
    overall_last_activity,
    CURRENT_DATE - date(overall_last_activity) AS days_since_activity
   FROM user_activity u
  WHERE total_messages > 0 OR total_stock_movements > 0 OR total_requests > 0;
