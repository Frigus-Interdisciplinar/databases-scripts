# Objetos lógicos, auditoria e otimização

Inventário do schema de Prod verificado em 2026-11-01: 15 functions, 3 procedures e 29 triggers não internos. As definições exportadas estão em `../../sql/functions/`, `../../sql/procedures/` e `../../sql/triggers/`.

## Regras de negócio

Correções desta entrega (migrations `20261102120000` e `20261102120100`): `fn_pair_key` passou a receber `uuid` e a usar `-` como separador, igual às conversas existentes; as três procedures passaram a receber `uuid` para usuário, lista e conversa, e `sp_purchase_shopping_list_item` soma a quantidade no estoque sem depender de trigger em `stock_movements`, que não existe no banco.

Exemplos de funções: `public.fn_compute_product_status`, `public.fn_low_stock_products`, `public.fn_suggest_recipes` e `public.fn_pair_key`. Procedures de negócio: `public.sp_close_shopping_list`, `public.sp_get_or_create_private_conversation` e `public.sp_purchase_shopping_list_item`. `dw.sp_load_all()` é uma function `RETURNS void`, não uma procedure, e executa a carga do Data Mart.

## Triggers de auditoria

`audit_products_row_changes` em `public.products` e `audit_stock_products_row_changes` em `public.stock_products` chamam `audit.capture_row_change()`. A função persiste schema, tabela, operação (`TG_OP`), `CURRENT_USER` e snapshots JSONB de `OLD` e `NEW` conforme o tipo da operação. O trigger da tabela de auditoria registra inserts no log; as duas tabelas de negócio atendem ao requisito de auditoria em pelo menos duas tabelas.

## Índices e análise

As consultas revisadas em `explain-analyze.sql` usam os índices já existentes `ix_fact_mov_date`, `ix_fact_mov_stock`, `idx_stock_movements_date` e `ix_user_daily_access_date_user`. Evidências e limites da amostra estão em `explain-analyze-dev.md`. Nenhum índice novo foi criado durante esta entrega: a amostra do DAU estava vazia e não havia evidência suficiente para justificar novos índices sem medir carga representativa.
