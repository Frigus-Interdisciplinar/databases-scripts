-- Descrições para os objetos que ainda não tinham, e para colunas-chave de tabelas centrais.
-- Descrições de colunas foram inferidas pelo nome e pelos valores observados; confirmar com o backend.
-- Ao fim, copia os comentários para governance.data_catalog (sem reprocessar o catálogo inteiro).

COMMENT ON TABLE public.advertisements IS 'Anúncios de anunciantes exibidos no app, com período de exibição e contadores de impressões e cliques.';
COMMENT ON TABLE public.dm_recipe_performance IS 'Resumo desnormalizado do desempenho das receitas (sugestões e nota média). Hoje sem linhas.';
COMMENT ON TABLE public.dm_stock_health_daily IS 'Snapshot diário da saúde de cada estoque. Hoje sem linhas.';
COMMENT ON TABLE public.dm_user_ltv IS 'Resumo desnormalizado de engajamento e gasto por usuário. Hoje sem linhas.';
COMMENT ON TABLE public.flyway_schema_history IS 'Histórico das migrations de schema executadas pelo Flyway.';
COMMENT ON TABLE public.food_purchases IS 'Compras de alimentos registradas por um grupo.';
COMMENT ON TABLE public.food_purchase_lines IS 'Itens de cada compra de alimentos, ligados ao produto e, se houver, ao item de estoque gerado.';
COMMENT ON TABLE public.food_purchase_revisions IS 'Histórico de revisões de uma compra de alimentos, com quem alterou.';
COMMENT ON TABLE public.group_invitations IS 'Convites enviados para entrar em um grupo.';
COMMENT ON TABLE public.message_attachments IS 'Anexos de mensagens do chat.';
COMMENT ON TABLE public.message_reactions IS 'Reações de usuários a mensagens.';
COMMENT ON TABLE public.message_reads IS 'Registro de leitura de cada mensagem por cada participante da conversa.';
COMMENT ON TABLE public.money_allocations IS 'Vínculo entre uma saída de dinheiro e a entrada (fornecimento) que a cobre.';
COMMENT ON TABLE public.money_exits IS 'Saídas de dinheiro do grupo, ligadas a um movimento de estoque quando houver.';
COMMENT ON TABLE public.money_supplies IS 'Entradas de dinheiro (fornecimentos) disponíveis para cobrir saídas.';
COMMENT ON TABLE public.password_reset_tokens IS 'Tokens de recuperação de senha, com validade e data de uso.';
COMMENT ON TABLE public.receipt_drafts IS 'Rascunhos de nota fiscal lida pelo app, antes de virarem compra ou estoque.';
COMMENT ON TABLE public.receipt_draft_lines IS 'Itens de cada rascunho de nota fiscal, com o produto encontrado na classificação, se houver.';
COMMENT ON TABLE public.recipe_favorites IS 'Receitas marcadas como favoritas por um usuário.';
COMMENT ON VIEW public.vw_dm_group_summary IS 'Resumo por grupo: membros, estoques, itens ativos, itens a vencer e vencidos.';
COMMENT ON VIEW public.vw_dm_stock_health IS 'Saúde de cada estoque: itens ativos, vencidos, a vencer em 7 dias, abaixo do mínimo e movimentos de 30 dias.';
COMMENT ON VIEW public.vw_dm_user_summary IS 'Resumo por usuário: mensagens, movimentos, pedidos, última atividade e assinatura.';
COMMENT ON VIEW public.vw_top_ingredients_analytics IS 'Ingredientes obrigatórios das receitas, com quantas sugestões aparecem e ranking por categoria.';
COMMENT ON VIEW public.vw_user_engagement_analytics IS 'Engajamento por usuário (mensagens, movimentos, pedidos), score ponderado e rankings.';
COMMENT ON VIEW analytics.dim_date IS 'Dimensão de datas do BI, do primeiro ao último dia com movimento.';
COMMENT ON VIEW analytics.dim_plan IS 'Dimensão de planos de assinatura para BI.';
COMMENT ON VIEW analytics.dim_product IS 'Dimensão de produtos para BI.';
COMMENT ON VIEW analytics.dim_stock IS 'Dimensão de estoques para BI, com o nome do grupo.';
COMMENT ON VIEW analytics.fact_inventory_snapshot IS 'Fato de inventário: uma linha por item de estoque, com quantidade e validade.';
COMMENT ON VIEW analytics.fact_transactions IS 'Fato de transações: valor, status e receita aprovada acumulada e ranking do dia.';
COMMENT ON TABLE dw.dim_date IS 'Dimensão de datas do Data Mart (2024 até um ano à frente).';
COMMENT ON TABLE dw.dim_group IS 'Dimensão de grupos do Data Mart.';
COMMENT ON TABLE dw.dim_product IS 'Dimensão de produtos do Data Mart.';
COMMENT ON TABLE dw.dim_stock IS 'Dimensão de estoques do Data Mart.';
COMMENT ON TABLE dw.dim_user IS 'Dimensão de usuários do Data Mart.';
COMMENT ON VIEW dw.vw_activity IS 'Atividade de usuários por dia (mensagens, movimentos e pedidos), base do DAU.';

COMMENT ON COLUMN public.stock_products.quantity IS 'Quantidade atual do item no estoque. Não pode ser negativa; alterada pelos movimentos.';
COMMENT ON COLUMN public.stock_products.minimal_quantity IS 'Quantidade mínima desejada. Nulo quando o item não tem alerta de mínimo.';
COMMENT ON COLUMN public.stock_products.expire_date IS 'Data de validade do lote do item.';
COMMENT ON COLUMN public.stock_products.product_status IS 'Situação da validade (FRESH, NEAR_EXPIRATION, EXPIRED). Calculada por trigger.';
COMMENT ON COLUMN public.stock_products.initial_quantity IS 'Quantidade na entrada do item. Preenchida por trigger quando não informada.';
COMMENT ON COLUMN public.stock_products.deleted_at IS 'Exclusão lógica do item de estoque.';
COMMENT ON COLUMN public.stock_movements.movement_type IS 'Tipo do movimento: IN (entrada), OUT (saída) ou ADJUSTMENT (ajuste).';
COMMENT ON COLUMN public.stock_movements.purpose IS 'Motivo do movimento: INVENTORY, CONSUMPTION ou DISCARD.';
COMMENT ON COLUMN public.stock_movements.balance_after IS 'Saldo após o movimento, quando registrado. Nulo em parte da origem; não usar como saldo oficial.';
COMMENT ON COLUMN public.subscriptions.status IS 'Situação da assinatura (TRIAL, ACTIVE, CANCELED, EXPIRED, DELINQUENT).';
COMMENT ON COLUMN public.transactions.idempotency_key IS 'Chave que impede cobrar duas vezes a mesma operação quando a requisição é repetida.';
COMMENT ON COLUMN public.transactions.status IS 'Situação da cobrança (PENDING, PROCESSING, APPROVED, REJECTED, CANCELED, ERROR).';
COMMENT ON COLUMN public.users.senha IS 'Coluna de senha, preenchida para todos os usuários. Coexiste com hash_password; ver normalizacao-3fn.md.';
COMMENT ON COLUMN public.users.hash_password IS 'Hash de senha, preenchido só para parte dos usuários. Coexiste com senha; ver normalizacao-3fn.md.';
COMMENT ON COLUMN public.users.token_version IS 'Versão do token de sessão. Aumentar invalida tokens antigos.';
COMMENT ON COLUMN public.users.email_verified IS 'Indica se o e-mail foi verificado.';
COMMENT ON COLUMN public.shopping_list_products.status IS 'Situação do item na lista (PENDING, PURCHASED, REMOVED).';
COMMENT ON COLUMN public.shopping_list_products.purchased_unit_price IS 'Preço unitário pago na compra do item.';

UPDATE governance.data_catalog d
   SET description = obj_description(to_regclass(format('%I.%I', d.object_schema, d.object_name)), 'pg_class'),
       metadata_updated_at = now()
 WHERE d.column_name = '__TABLE__'
   AND obj_description(to_regclass(format('%I.%I', d.object_schema, d.object_name)), 'pg_class') IS NOT NULL;

UPDATE governance.data_catalog d
   SET description = col_description(to_regclass(format('%I.%I', d.object_schema, d.object_name)), d.ordinal_position),
       metadata_updated_at = now()
 WHERE d.column_name <> '__TABLE__'
   AND col_description(to_regclass(format('%I.%I', d.object_schema, d.object_name)), d.ordinal_position) IS NOT NULL;
