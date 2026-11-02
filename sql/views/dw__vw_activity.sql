CREATE OR REPLACE VIEW "dw"."vw_activity" AS
 SELECT messages.sender_id AS user_id,
    messages.created_at::date AS activity_date
   FROM messages
  WHERE messages.sender_id IS NOT NULL
UNION ALL
 SELECT stock_movements.user_id,
    stock_movements.date::date AS activity_date
   FROM stock_movements
  WHERE stock_movements.user_id IS NOT NULL
UNION ALL
 SELECT requests.user_id,
    requests.date AS activity_date
   FROM requests
  WHERE requests.user_id IS NOT NULL;
