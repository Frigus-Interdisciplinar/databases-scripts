-- Requisitos de Governanca e Monitoramento (DAU por acesso autenticado).
-- Aplicada no FrigusDB Dev; nao habilita nem altera politicas de RLS.

CREATE SCHEMA IF NOT EXISTS governance;
REVOKE ALL ON SCHEMA governance FROM PUBLIC, anon, authenticated, service_role;

CREATE TABLE IF NOT EXISTS governance.data_catalog (
    object_schema       text NOT NULL,
    object_name         text NOT NULL,
    object_type         text NOT NULL CHECK (object_type IN ('BASE TABLE', 'VIEW', 'MATERIALIZED VIEW')),
    column_name         text NOT NULL,
    ordinal_position    integer NOT NULL DEFAULT 0,
    data_type           text,
    description         text NOT NULL,
    business_rules      text NOT NULL,
    access_level        text NOT NULL,
    data_classification text NOT NULL,
    metadata_updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT data_catalog_pk PRIMARY KEY (object_schema, object_name, column_name)
);

COMMENT ON TABLE governance.data_catalog IS
    'Catalogo tecnico de objetos e colunas PostgreSQL, com regras estruturais, acesso e classificacao; nao substitui autorizacao da API.';

-- Uma linha especial registra o objeto; as demais descrevem as colunas.
INSERT INTO governance.data_catalog (
    object_schema, object_name, object_type, column_name, ordinal_position,
    data_type, description, business_rules, access_level, data_classification
)
SELECT t.table_schema,
       t.table_name,
       CASE t.table_type WHEN 'BASE TABLE' THEN 'BASE TABLE' ELSE 'VIEW' END,
       '__TABLE__',
       0,
       NULL,
       COALESCE(obj_description(to_regclass(format('%I.%I', t.table_schema, t.table_name)), 'pg_class'),
                format('Objeto relacional %I.%I.', t.table_schema, t.table_name)),
       COALESCE(rules.rule_text, 'Sem constraints declaradas no catalogo PostgreSQL.'),
       CASE
           WHEN t.table_schema = 'audit' THEN 'Restrito: auditoria e operacao do banco'
           WHEN t.table_schema = 'governance' THEN 'Restrito: proprietario do banco'
           WHEN t.table_schema IN ('dw', 'analytics') THEN 'Interno: API/BI conforme grants do ambiente'
           ELSE 'Operacional: Core API; acesso direto deve ser revisado por grants'
       END,
       CASE WHEN t.table_schema = 'audit' THEN 'Auditoria'
            WHEN t.table_schema = 'governance' THEN 'Metadados tecnicos'
            ELSE 'Uso interno; classificar colunas sensiveis' END
FROM information_schema.tables t
LEFT JOIN LATERAL (
    SELECT string_agg(pg_get_constraintdef(con.oid), '; ' ORDER BY con.conname) AS rule_text
    FROM pg_constraint con
    WHERE con.conrelid = to_regclass(format('%I.%I', t.table_schema, t.table_name))
) rules ON true
WHERE t.table_schema IN ('public', 'analytics', 'audit', 'dw')
  AND t.table_type IN ('BASE TABLE', 'VIEW')
ON CONFLICT (object_schema, object_name, column_name) DO UPDATE
SET object_type = EXCLUDED.object_type,
    description = EXCLUDED.description,
    business_rules = EXCLUDED.business_rules,
    access_level = EXCLUDED.access_level,
    data_classification = EXCLUDED.data_classification,
    metadata_updated_at = now();

INSERT INTO governance.data_catalog (
    object_schema, object_name, object_type, column_name, ordinal_position,
    data_type, description, business_rules, access_level, data_classification
)
SELECT c.table_schema,
       c.table_name,
       CASE t.table_type WHEN 'BASE TABLE' THEN 'BASE TABLE' ELSE 'VIEW' END,
       c.column_name,
       c.ordinal_position,
       c.data_type,
       COALESCE(col_description(to_regclass(format('%I.%I', c.table_schema, c.table_name)), c.ordinal_position),
                format('Coluna %I de %I.%I.', c.column_name, c.table_schema, c.table_name)),
       concat_ws('; ',
           format('tipo %s', c.data_type),
           CASE WHEN c.is_nullable = 'NO' THEN 'NOT NULL' ELSE 'NULL permitido' END,
           CASE WHEN c.column_default IS NOT NULL THEN 'DEFAULT ' || c.column_default END,
           NULLIF(rules.rule_text, '')
       ),
       CASE
           WHEN c.table_schema = 'audit' THEN 'Restrito: auditoria e operacao do banco'
           WHEN c.table_schema = 'governance' THEN 'Restrito: proprietario do banco'
           WHEN c.table_schema IN ('dw', 'analytics') THEN 'Interno: API/BI conforme grants do ambiente'
           ELSE 'Operacional: Core API; acesso direto deve ser revisado por grants'
       END,
       CASE
           WHEN c.column_name ~* '(password|token|secret|email|phone|birth|picture)' THEN 'Potencial dado pessoal/credencial; acesso restrito'
           WHEN c.table_schema = 'audit' THEN 'Auditoria'
           ELSE 'Uso interno; revisar classificacao funcional'
       END
FROM information_schema.columns c
JOIN information_schema.tables t
  ON t.table_schema = c.table_schema AND t.table_name = c.table_name
LEFT JOIN LATERAL (
    SELECT string_agg(DISTINCT pg_get_constraintdef(con.oid), '; ' ORDER BY pg_get_constraintdef(con.oid)) AS rule_text
    FROM pg_constraint con
    JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = ANY(con.conkey)
    WHERE con.conrelid = to_regclass(format('%I.%I', c.table_schema, c.table_name))
      AND a.attname = c.column_name
) rules ON true
WHERE c.table_schema IN ('public', 'analytics', 'audit', 'dw')
  AND t.table_type IN ('BASE TABLE', 'VIEW')
ON CONFLICT (object_schema, object_name, column_name) DO UPDATE
SET object_type = EXCLUDED.object_type,
    ordinal_position = EXCLUDED.ordinal_position,
    data_type = EXCLUDED.data_type,
    description = EXCLUDED.description,
    business_rules = EXCLUDED.business_rules,
    access_level = EXCLUDED.access_level,
    data_classification = EXCLUDED.data_classification,
    metadata_updated_at = now();

REVOKE ALL ON ALL TABLES IN SCHEMA governance FROM PUBLIC, anon, authenticated, service_role;

CREATE TABLE IF NOT EXISTS dw.user_daily_access (
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    access_date date NOT NULL,
    first_access_at timestamptz NOT NULL,
    CONSTRAINT user_daily_access_pk PRIMARY KEY (user_id, access_date)
);

CREATE INDEX IF NOT EXISTS ix_user_daily_access_date_user
    ON dw.user_daily_access (access_date, user_id);

COMMENT ON TABLE dw.user_daily_access IS
    'Um registro por usuario autenticado por dia; Core API registra apos validar token e sessao.';
COMMENT ON COLUMN dw.user_daily_access.access_date IS
    'Data local do primeiro acesso autenticado no fuso America/Sao_Paulo.';

REVOKE ALL ON TABLE dw.user_daily_access FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE VIEW dw.vw_dau AS
WITH daily AS (
    SELECT access_date AS day, COUNT(DISTINCT user_id) AS dau
    FROM dw.user_daily_access
    GROUP BY access_date
), wau AS (
    SELECT d.day,
           (SELECT COUNT(DISTINCT a.user_id)
            FROM dw.user_daily_access a
            WHERE a.access_date BETWEEN d.day - 6 AND d.day) AS wau_7d
    FROM daily d
), mau AS (
    SELECT d.day,
           (SELECT COUNT(DISTINCT a.user_id)
            FROM dw.user_daily_access a
            WHERE a.access_date BETWEEN d.day - 29 AND d.day) AS mau_30d
    FROM daily d
)
SELECT d.day,
       d.dau,
       w.wau_7d,
       m.mau_30d,
       ROUND(100.0 * d.dau / NULLIF(m.mau_30d, 0), 1) AS dau_mau_pct,
       d.dau - LAG(d.dau) OVER (ORDER BY d.day) AS dau_change
FROM daily d
JOIN wau w ON w.day = d.day
JOIN mau m ON m.day = d.day;

REVOKE ALL ON TABLE dw.vw_dau FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON VIEW dw.vw_dau IS
    'DAU/WAU/MAU de usuarios com acesso autenticado a Core API; depende do registro diario da aplicacao.';
