-- Define formalmente os níveis de acesso e a classificação dos dados no catálogo.
-- Antes: access_level e data_classification eram frases longas e diferentes por migration.
-- Agora: 4 níveis em governance.access_levels (FK) e 6 classificações (CHECK), aplicados por regra.
--
-- Os níveis descrevem a política pretendida. Os grants e o RLS reais de public seguem os padrões do Supabase;
-- esta entrega decidiu não criar policies de RLS.
-- Esta migration deve rodar depois das que gravam access_level como texto livre (20261101185253, 20261101185318, 20261102120400).

CREATE TABLE IF NOT EXISTS governance.access_levels (
    level          text PRIMARY KEY,
    rank           integer NOT NULL UNIQUE,
    description    text NOT NULL,
    who_can_access text NOT NULL,
    bi_exposure    text NOT NULL
);

INSERT INTO governance.access_levels (level, rank, description, who_can_access, bi_exposure) VALUES
 ('PUBLICO',      1, 'Dado que pode ser lido sem autenticação.', 'Qualquer pessoa', 'Livre'),
 ('INTERNO',      2, 'Dado operacional do produto, sem dado pessoal, financeiro ou credencial.', 'Core API e equipe de dados', 'Livre nas camadas dw e analytics'),
 ('RESTRITO',     3, 'Dado pessoal (LGPD), financeiro, de auditoria ou de governança.', 'Core API e DBA; BI apenas agregado ou mascarado', 'Somente agregado ou mascarado'),
 ('CONFIDENCIAL', 4, 'Credenciais, hashes e tokens.', 'Somente a Core API, para validar; nunca lido por pessoas ou BI', 'Nunca exposto')
ON CONFLICT (level) DO UPDATE
   SET rank = EXCLUDED.rank, description = EXCLUDED.description,
       who_can_access = EXCLUDED.who_can_access, bi_exposure = EXCLUDED.bi_exposure;

ALTER TABLE governance.access_levels ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON governance.access_levels FROM anon, authenticated;

ALTER TABLE governance.data_catalog DROP CONSTRAINT IF EXISTS data_catalog_access_level_fk;
ALTER TABLE governance.data_catalog DROP CONSTRAINT IF EXISTS data_catalog_classification_check;

-- 1) colunas: classificação por regra e nível derivado dela
WITH cls AS (
    SELECT d.object_schema, d.object_name, d.column_name,
           CASE
               WHEN d.column_name IN ('hash_password', 'token_hash') THEN 'CREDENCIAL'
               WHEN d.object_schema = 'audit' THEN 'AUDITORIA'
               WHEN d.object_schema = 'governance'
                 OR (d.object_schema = 'public' AND d.object_name = 'flyway_schema_history') THEN 'TECNICO'
               WHEN (d.object_schema, d.object_name) IN (
                        ('public', 'transactions'), ('public', 'transaction_events'), ('public', 'business_expenses'),
                        ('public', 'money_supplies'), ('public', 'money_exits'), ('public', 'money_allocations'),
                        ('public', 'food_purchases'), ('public', 'food_purchase_lines'), ('public', 'receipt_drafts'),
                        ('public', 'receipt_draft_lines'), ('analytics', 'fact_transactions'))
                    THEN 'FINANCEIRO'
               WHEN (d.object_schema, d.object_name, d.column_name) IN (
                        ('public', 'dm_user_ltv', 'total_spent'), ('public', 'dm_user_ltv', 'total_transactions'))
                    THEN 'FINANCEIRO'
               WHEN (d.object_schema, d.object_name, d.column_name) IN (
                        ('public', 'users', 'name'), ('public', 'users', 'email'), ('public', 'users', 'birth_date'),
                        ('public', 'users', 'profile_picture_url'), ('public', 'users', 'google_id'),
                        ('public', 'group_invitations', 'email'), ('public', 'support_requests', 'subject'),
                        ('public', 'support_requests', 'description'), ('public', 'messages', 'content'),
                        ('public', 'user_app_settings', 'dietary_preferences'),
                        ('public', 'user_app_settings', 'dietary_restrictions'), ('dw', 'dim_user', 'user_name'),
                        ('public', 'dm_user_ltv', 'user_name'), ('public', 'vw_dm_user_summary', 'user_name'),
                        ('public', 'vw_user_engagement_analytics', 'name'), ('public', 'message_attachments', 'file_url'))
                    THEN 'PESSOAL'
               ELSE 'NEGOCIO'
           END AS classification
      FROM governance.data_catalog d
     WHERE d.column_name <> '__TABLE__'
), lvl AS (
    SELECT c.*,
           CASE
               WHEN c.classification = 'CREDENCIAL' THEN 'CONFIDENCIAL'
               WHEN c.classification IN ('FINANCEIRO', 'PESSOAL', 'AUDITORIA') OR c.object_schema = 'governance' THEN 'RESTRITO'
               ELSE 'INTERNO'
           END AS access_level
      FROM cls c
)
UPDATE governance.data_catalog d
   SET access_level = l.access_level, data_classification = l.classification, metadata_updated_at = now()
  FROM lvl l
 WHERE d.object_schema = l.object_schema AND d.object_name = l.object_name AND d.column_name = l.column_name;

-- 2) linha do objeto: o nível mais alto entre as colunas; classificação pela precedência
WITH ranked AS (
    SELECT d.object_schema, d.object_name, d.access_level, d.data_classification, a.rank AS level_rank,
           CASE d.data_classification
               WHEN 'CREDENCIAL' THEN 6 WHEN 'FINANCEIRO' THEN 5 WHEN 'PESSOAL' THEN 4
               WHEN 'AUDITORIA' THEN 3 WHEN 'TECNICO' THEN 2 ELSE 1
           END AS class_rank
      FROM governance.data_catalog d
      JOIN governance.access_levels a ON a.level = d.access_level
     WHERE d.column_name <> '__TABLE__'
), top AS (
    SELECT DISTINCT ON (object_schema, object_name) object_schema, object_name, access_level, data_classification
      FROM ranked
     ORDER BY object_schema, object_name, level_rank DESC, class_rank DESC
)
UPDATE governance.data_catalog d
   SET access_level = t.access_level, data_classification = t.data_classification, metadata_updated_at = now()
  FROM top t
 WHERE d.object_schema = t.object_schema AND d.object_name = t.object_name AND d.column_name = '__TABLE__';

COMMENT ON TABLE governance.access_levels IS 'Níveis de acesso do catálogo de dados, do menos ao mais sensível.';

INSERT INTO governance.data_catalog (object_schema, object_name, object_type, column_name, ordinal_position,
                                     data_type, description, business_rules, access_level, data_classification)
SELECT 'governance', 'access_levels', 'BASE TABLE', '__TABLE__', 0, NULL,
       'Níveis de acesso do catálogo de dados, do menos ao mais sensível.', 'PRIMARY KEY (level); rank único',
       'RESTRITO', 'TECNICO'
UNION ALL
SELECT 'governance', 'access_levels', 'BASE TABLE', c.column_name, c.ordinal_position, c.data_type,
       CASE c.column_name
           WHEN 'level' THEN 'Nome do nível (PUBLICO, INTERNO, RESTRITO ou CONFIDENCIAL).'
           WHEN 'rank' THEN 'Ordem de sensibilidade; maior significa mais sensível.'
           WHEN 'description' THEN 'Que tipo de dado pertence ao nível.'
           WHEN 'who_can_access' THEN 'Quem pode acessar dados do nível.'
           WHEN 'bi_exposure' THEN 'Como o dado do nível pode aparecer em BI.'
       END,
       concat_ws('; ', 'tipo ' || c.data_type, CASE WHEN c.is_nullable = 'NO' THEN 'NOT NULL' ELSE 'NULL permitido' END),
       'RESTRITO', 'TECNICO'
  FROM information_schema.columns c
 WHERE c.table_schema = 'governance' AND c.table_name = 'access_levels'
ON CONFLICT (object_schema, object_name, column_name) DO UPDATE
   SET description = EXCLUDED.description, access_level = EXCLUDED.access_level,
       data_classification = EXCLUDED.data_classification, metadata_updated_at = now();

ALTER TABLE governance.data_catalog
    ADD CONSTRAINT data_catalog_access_level_fk
    FOREIGN KEY (access_level) REFERENCES governance.access_levels (level);

ALTER TABLE governance.data_catalog
    ADD CONSTRAINT data_catalog_classification_check
    CHECK (data_classification IN ('NEGOCIO', 'PESSOAL', 'FINANCEIRO', 'CREDENCIAL', 'AUDITORIA', 'TECNICO'));
