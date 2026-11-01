CREATE OR REPLACE VIEW "public"."vw_dm_user_summary" AS
 WITH msg AS (
         SELECT messages.sender_id AS user_id,
            count(*) AS messages,
            max(messages.created_at) AS last_msg_at
           FROM messages
          GROUP BY messages.sender_id
        ), mov AS (
         SELECT stock_movements.user_id,
            count(*) AS movements,
            max(stock_movements.date) AS last_mov_at
           FROM stock_movements
          GROUP BY stock_movements.user_id
        ), req AS (
         SELECT requests.user_id,
            count(*) AS requests
           FROM requests
          GROUP BY requests.user_id
        ), subs AS (
         SELECT DISTINCT ON (subscriptions.user_id) subscriptions.user_id,
            subscriptions.status
           FROM subscriptions
          WHERE subscriptions.deleted_at IS NULL
          ORDER BY subscriptions.user_id, subscriptions.started_at DESC
        )
 SELECT u.id AS user_id,
    u.name AS user_name,
    u.account_type,
    u.created_at::date AS signup_date,
    COALESCE(msg.messages, 0::bigint) AS messages,
    COALESCE(mov.movements, 0::bigint) AS movements,
    COALESCE(req.requests, 0::bigint) AS requests,
    GREATEST(msg.last_msg_at, mov.last_mov_at)::date AS last_activity_date,
    COALESCE(subs.status::text, 'NONE'::text) AS subscription_status,
    COALESCE(msg.messages, 0::bigint) + 2 * COALESCE(mov.movements, 0::bigint) + 3 * COALESCE(req.requests, 0::bigint) AS engagement_score
   FROM users u
     LEFT JOIN msg ON msg.user_id = u.id
     LEFT JOIN mov ON mov.user_id = u.id
     LEFT JOIN req ON req.user_id = u.id
     LEFT JOIN subs ON subs.user_id = u.id
  WHERE u.deleted_at IS NULL;
