-- Completa o catalogo com os objetos criados pela migration anterior.
-- Idempotente: permite atualizar metadados sem duplicar linhas.
INSERT INTO governance.data_catalog (
    object_schema, object_name, object_type, column_name, ordinal_position,
    data_type, description, business_rules, access_level, data_classification
)
SELECT t.table_schema,
       t.table_name,
       CASE t.table_type WHEN 'BASE TABLE' THEN 'BASE TABLE' ELSE 'VIEW' END,
       '__TABLE__', 0, NULL,
       COALESCE(obj_description(to_regclass(format('%I.%I', t.table_schema, t.table_name)), 'pg_class'),
                format('Objeto relacional %I.%I.', t.table_schema, t.table_name)),
       COALESCE(rules.rule_text, 'Sem constraints declaradas no catalogo PostgreSQL.'),
       CASE WHEN t.table_schema = 'audit' THEN 'Restrito: auditoria e operacao do banco'
            WHEN t.table_schema = 'governance' THEN 'Restrito: proprietario do banco'
            WHEN t.table_schema IN ('dw', 'analytics') THEN 'Interno: API/BI conforme grants do ambiente'
            ELSE 'Operacional: Core API; acesso direto deve ser revisado por grants' END,
       CASE WHEN t.table_schema = 'audit' THEN 'Auditoria'
            WHEN t.table_schema = 'governance' THEN 'Metadados tecnicos'
            ELSE 'Uso interno; classificar colunas sensiveis' END
FROM information_schema.tables t
LEFT JOIN LATERAL (
    SELECT string_agg(pg_get_constraintdef(con.oid), '; ' ORDER BY con.conname) AS rule_text
    FROM pg_constraint con
    WHERE con.conrelid = to_regclass(format('%I.%I', t.table_schema, t.table_name))
) rules ON true
WHERE t.table_schema IN ('public', 'analytics', 'audit', 'dw', 'governance')
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
       c.column_name, c.ordinal_position, c.data_type,
       COALESCE(col_description(to_regclass(format('%I.%I', c.table_schema, c.table_name)), c.ordinal_position),
                format('Coluna %I de %I.%I.', c.column_name, c.table_schema, c.table_name)),
       concat_ws('; ', format('tipo %s', c.data_type),
           CASE WHEN c.is_nullable = 'NO' THEN 'NOT NULL' ELSE 'NULL permitido' END,
           CASE WHEN c.column_default IS NOT NULL THEN 'DEFAULT ' || c.column_default END,
           NULLIF(rules.rule_text, '')),
       CASE WHEN c.table_schema = 'audit' THEN 'Restrito: auditoria e operacao do banco'
            WHEN c.table_schema = 'governance' THEN 'Restrito: proprietario do banco'
            WHEN c.table_schema IN ('dw', 'analytics') THEN 'Interno: API/BI conforme grants do ambiente'
            ELSE 'Operacional: Core API; acesso direto deve ser revisado por grants' END,
       CASE WHEN c.column_name ~* '(password|token|secret|email|phone|birth|picture)'
                 THEN 'Potencial dado pessoal/credencial; acesso restrito'
            WHEN c.table_schema = 'audit' THEN 'Auditoria'
            ELSE 'Uso interno; revisar classificacao funcional' END
FROM information_schema.columns c
JOIN information_schema.tables t ON t.table_schema = c.table_schema AND t.table_name = c.table_name
LEFT JOIN LATERAL (
    SELECT string_agg(DISTINCT pg_get_constraintdef(con.oid), '; ' ORDER BY pg_get_constraintdef(con.oid)) AS rule_text
    FROM pg_constraint con
    JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = ANY(con.conkey)
    WHERE con.conrelid = to_regclass(format('%I.%I', c.table_schema, c.table_name))
      AND a.attname = c.column_name
) rules ON true
WHERE c.table_schema IN ('public', 'analytics', 'audit', 'dw', 'governance')
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
