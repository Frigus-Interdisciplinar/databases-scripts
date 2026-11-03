-- Descrições de negócio para o catálogo, via COMMENT (o catálogo lê obj_description).
-- Depois registra no catálogo os objetos novos (product_categories, vw_category_tree, support_requests, user_app_settings).
-- O bloco de upsert é o mesmo da migration 20261101185253, que é idempotente.

COMMENT ON TABLE public.users IS 'Pessoas que usam o app (conta doméstica, empresarial ou comercial). Exclusão lógica por deleted_at.';
COMMENT ON TABLE public.groups IS 'Casa ou empresa. Todo grupo ativo tem um dono (owner_id).';
COMMENT ON TABLE public.user_groups IS 'Participação de usuários em grupos (N:N) com papel EDITOR ou VIEWER.';
COMMENT ON TABLE public.stocks IS 'Estoque físico de um grupo (geladeira, freezer, despensa).';
COMMENT ON TABLE public.products IS 'Catálogo de produtos: nome, marca, categoria, local de armazenamento, unidade e preço.';
COMMENT ON TABLE public.stock_products IS 'Produto dentro de um estoque, com quantidade, validade, lote e status calculado por trigger. Único por produto, estoque e validade.';
COMMENT ON TABLE public.stock_movements IS 'Histórico de entradas (IN), saídas (OUT) e ajustes (ADJUSTMENT) de itens de estoque.';
COMMENT ON TABLE public.discard IS 'Descartes de itens de estoque com motivo.';
COMMENT ON TABLE public.recipes IS 'Receitas cadastradas.';
COMMENT ON TABLE public.recipe_ingredients IS 'Ingredientes de cada receita (N:N entre receitas e produtos).';
COMMENT ON TABLE public.recipe_suggestions IS 'Receitas sugeridas por estoque, com nota (score) e validade mais próxima dos ingredientes.';
COMMENT ON TABLE public.shopping_lists IS 'Lista de compras de um estoque (OPEN, COMPLETED, CANCELED).';
COMMENT ON TABLE public.shopping_list_products IS 'Itens da lista de compras (PENDING, PURCHASED, REMOVED).';
COMMENT ON TABLE public.plans IS 'Planos de assinatura (código, preço e periodicidade).';
COMMENT ON TABLE public.subscriptions IS 'Assinatura de um usuário a um plano.';
COMMENT ON TABLE public.transactions IS 'Cobranças das assinaturas, com status e forma de pagamento.';
COMMENT ON TABLE public.transaction_events IS 'Histórico de mudanças de status de cada cobrança.';
COMMENT ON TABLE public.conversations IS 'Conversas do chat: PRIVATE (par de usuários, pair_key único) ou GROUP (ligada a um grupo).';
COMMENT ON TABLE public.conversation_participants IS 'Participantes de cada conversa (N:N).';
COMMENT ON TABLE public.messages IS 'Mensagens do chat.';
COMMENT ON TABLE public.requests IS 'Pedidos feitos dentro de conversas.';
COMMENT ON TABLE public.notifications IS 'Notificações para usuários (validade próxima, estoque baixo, convites etc.).';
COMMENT ON TABLE public.business_expenses IS 'Despesas de grupos comerciais.';
COMMENT ON TABLE public.product_categories IS 'Árvore de categorias de produto (parent_id aponta para a própria tabela). Folhas ligam em products.category via enum_value.';
COMMENT ON TABLE public.user_preferences IS 'Preferências do usuário (relação 1:1).';
COMMENT ON TABLE public.user_app_settings IS 'Configurações do app mobile por usuário (relação 1:1).';
COMMENT ON TABLE public.support_requests IS 'Chamados de suporte abertos por usuários.';
COMMENT ON TABLE audit.row_change_log IS 'Auditoria: operação, usuário do banco, linha antiga e nova (JSON) de products e stock_products.';
COMMENT ON TABLE dw.user_daily_access IS 'Um registro por usuário por dia de acesso; base do DAU.';
COMMENT ON TABLE dw.fact_stock_movement IS 'Fato do DW: um registro por movimento de estoque.';
COMMENT ON VIEW dw.vw_dau IS 'DAU, WAU, MAU e razão DAU/MAU por dia.';
COMMENT ON VIEW analytics.vw_category_tree IS 'Árvore de categorias via CTE recursiva, com caminho, profundidade e total de produtos por nó.';

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
