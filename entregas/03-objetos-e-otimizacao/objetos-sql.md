# Objetos logicos e auditoria

## Regras de negocio

No Dev existem 13 functions e 3 procedures em `public`, alem de funcoes de auditoria e Data Mart. Exemplos implementados:

- Functions: `fn_compute_product_status`, `fn_low_stock_products`, `fn_suggest_recipes`.
- Procedures: `sp_close_shopping_list`, `sp_get_or_create_private_conversation`, `sp_purchase_shopping_list_item`.
- ETL do Data Mart: `dw.sp_load_all()` e uma function que retorna `void`.

As definicoes estao preservadas em `sql/schema/frigusdb_dev_snapshot.sql`.

## Auditoria

Triggers `audit_products_row_changes` e `audit_stock_products_row_changes` chamam `audit.capture_row_change()`. A funcao registra schema/tabela, `TG_OP`, `CURRENT_USER`, `OLD` e `NEW` em JSONB. O Dev tinha 33.551 linhas na tabela de auditoria quando foi verificado.

## Desempenho

`explain-analyze.sql` executa consultas de leitura com `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` nos indices existentes. Resultados/observacoes ficam em `explain-analyze-dev.md`. EXPLAIN ANALYZE executa a consulta; usar somente em SELECTs revisados.
