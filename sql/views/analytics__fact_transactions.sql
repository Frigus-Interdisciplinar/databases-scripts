CREATE OR REPLACE VIEW "analytics"."fact_transactions" WITH (security_invoker=true) AS
 WITH base_transactions AS (
         SELECT t.id AS transaction_key,
            t.created_at,
            t.created_at::date AS date_key,
            t.plan_id AS plan_key,
            t.amount,
            t.status,
            t.payment_method,
                CASE
                    WHEN t.status = 'APPROVED'::transaction_status_enum THEN t.amount
                    ELSE 0::numeric
                END AS approved_amount
           FROM transactions t
        )
 SELECT transaction_key,
    date_key,
    plan_key,
    amount,
    status,
    payment_method,
    approved_amount,
    sum(approved_amount) OVER (ORDER BY created_at, transaction_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_approved_revenue,
    rank() OVER (PARTITION BY date_key ORDER BY approved_amount DESC) AS approved_amount_rank_for_day
   FROM base_transactions bt;
