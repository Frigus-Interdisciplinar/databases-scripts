# Engenharia de dados e Data Mart

## ETL e camada analítica

O schema tem as dimensões `dw.dim_date`, `dim_group`, `dim_product`, `dim_stock`, `dim_user` e a fato `dw.fact_stock_movement`. A função `dw.sp_load_all()` faz upsert das dimensões, deriva chaves e recarrega a fato a partir de `public.stock_movements`, `stock_products` e entidades relacionadas. A fato tem uma linha por movimento.

As views `analytics.fact_transactions` e `dw.vw_dau` usam CTEs; `analytics.fact_transactions` calcula receita aprovada acumulada e ranking por dia com Window Functions. `dw.vw_dau` calcula DAU/WAU/MAU e variação diária a partir de `dw.user_daily_access`. As definições estão exportadas em `../../sql/views/`.

## Integridade e falhas

`dw.sp_load_all()` usa a transação PostgreSQL da chamada e `ON CONFLICT` para dimensões. A fato é recarregada com `TRUNCATE` seguido de `INSERT`; uma falha cancela a transação e reverte a operação. A rotina é idempotente para dimensões e reconstrói a fato a cada execução. A definição exportada está em `../../sql/functions/dw__sp_load_all.sql`.

## Integracao legada

O RPA está em outro repositório conforme escopo combinado. Seu comportamento atual é descrito em `../08-integracao-rpa/README.md`; não se deve confundir a implementação existente (carga periódica direta com transação por ciclo) com sugestões de evolução como staging/checkpoint.
