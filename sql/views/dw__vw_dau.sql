CREATE OR REPLACE VIEW "dw"."vw_dau" AS
 WITH daily AS (
         SELECT user_daily_access.access_date AS day,
            count(DISTINCT user_daily_access.user_id) AS dau
           FROM dw.user_daily_access
          GROUP BY user_daily_access.access_date
        ), wau AS (
         SELECT d_1.day,
            ( SELECT count(DISTINCT a.user_id) AS count
                   FROM dw.user_daily_access a
                  WHERE a.access_date >= (d_1.day - 6) AND a.access_date <= d_1.day) AS wau_7d
           FROM daily d_1
        ), mau AS (
         SELECT d_1.day,
            ( SELECT count(DISTINCT a.user_id) AS count
                   FROM dw.user_daily_access a
                  WHERE a.access_date >= (d_1.day - 29) AND a.access_date <= d_1.day) AS mau_30d
           FROM daily d_1
        )
 SELECT d.day,
    d.dau,
    w.wau_7d,
    m.mau_30d,
    round(100.0 * d.dau::numeric / NULLIF(m.mau_30d, 0)::numeric, 1) AS dau_mau_pct,
    d.dau - lag(d.dau) OVER (ORDER BY d.day) AS dau_change
   FROM daily d
     JOIN wau w ON w.day = d.day
     JOIN mau m ON m.day = d.day;
COMMENT ON VIEW "dw"."vw_dau" IS 'DAU/WAU/MAU de usuarios com acesso autenticado a Core API; depende do registro diario da aplicacao.';
