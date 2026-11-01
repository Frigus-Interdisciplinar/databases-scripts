# Engenharia de dados e Data Mart

## ETL existente

O Dev tem as dimensoes `dw.dim_date`, `dim_group`, `dim_product`, `dim_stock`, `dim_user` e a fato `dw.fact_stock_movement`. A funcao `dw.sp_load_all()` faz o upsert das dimensoes, deriva chaves e recarrega a fato a partir de `public.stock_movements`, `stock_products` e das entidades relacionadas. A fato e uma linha por movimento.

As views `analytics.fact_transactions` e `dw.vw_dau` usam CTEs; `analytics.fact_transactions` calcula receita aprovada acumulada e ranking por dia com Window Functions. A definicao completa esta no snapshot do schema.

## Integridade e falhas

`dw.sp_load_all()` usa transacao PostgreSQL da chamada e `ON CONFLICT` para dimensoes. A fato e recarregada com `TRUNCATE` seguido de `INSERT`; qualquer falha na mesma transacao reverte a operacao, preservando a carga anterior. A rotina e idempotente para as dimensoes e reconstroi o fato a cada execucao.

## Integracao legada

O orquestrador RPA esta em outro repositorio conforme escopo combinado. Este pacote documenta apenas o contrato: extracao com checkpoint, carga em staging, validacao de contagens/FKs, transacao de promocao, log de lote e retentativa segura. Ver `08-integracao-rpa/README.md`.
