# Modelagem de Dados: revisão e estado final (Frigus)

Revisão feita em 02/11/2026 no Postgres (Supabase), no RPA e nas queries. Este documento compara o banco com os requisitos da matéria e lista o que ainda está aberto. Os números foram medidos no **FrigusDB Dev**. A evidência de cada item está em `entregas/` (índice em `entregas/README.md`). A explicação do banco está em `docs/banco-de-dados.md`.

## 1. Placar contra os requisitos

| # | Requisito | Status | Evidência |
|---|---|---|---|
| 1a | Banco normalizado (3FN) | ✅ com ressalva | `users.senha` removida. `stock_products.category` continua como cópia mantida por trigger. Ver `entregas/01-modelagem/normalizacao-3fn.md` |
| 1b | PKs, FKs, cardinalidades | ✅ | 45 tabelas em `public` e 72 FKs, com 1:N, N:N e 1:1. Diagrama e SQL em `entregas/01-modelagem/` |
| 1c | Massa de dados ≥ 500 | ✅ | Milhares de linhas por tabela. A maior parte vem da massa sintética (`sql/dataload/`) |
| 2a | RPA legado → novo banco | ✅ com ressalvas | Transação por ciclo, rollback, retry, logs com loguru e recarga do DW a cada ciclo. Só insere e não guarda histórico de execuções |
| 2b | Camada BI (Star Schema) | ✅ | `dw.*` (estrela física) e `analytics.*` (estrela em views) |
| 2c | CTEs | ✅ | 9 views de BI usam CTE |
| 2d | Window Functions | ✅ | 5 views: soma acumulada, `RANK`, `DENSE_RANK`, `ROW_NUMBER`, `LAG`, `FIRST_VALUE` |
| 3a | Functions e procedures | ✅ | 3 functions de negócio e 3 procedures com `uuid`, testadas |
| 3b | Triggers de auditoria | ✅ | `products` e `stock_products` gravam em `audit.row_change_log` (`TG_OP`, `CURRENT_USER`, `OLD`, `NEW`) |
| 3c | EXPLAIN ANALYZE e índices | ✅ | `vw_user_engagement_analytics` caiu de ~1,7 s para ~60 ms. Ver `entregas/03-objetos-e-otimizacao/` |
| 4a | Catálogo de dados | ✅ com ressalva | 701 linhas e 70 objetos, com níveis de acesso formais. As descrições de colunas da migration `120600` são inferidas e precisam de revisão |
| 4b | Backup e recuperação | ✅ com ressalva | Procedimento em `entregas/04-governanca/backup-recuperacao.md`. Faltam RPO, RTO, responsáveis e um teste de restauração registrado |
| 5 | DAU | ✅ com ressalva | `dw.user_daily_access` e `dw.vw_dau` existem e coletam no Dev (68 acessos de 14 usuários em 7 dias, em 02/11). A gravação é feita pela Core API, não por um objeto do banco |
| 6 | CTE recursiva ou herança | ✅ | `product_categories` e `analytics.vw_category_tree` (`WITH RECURSIVE`) |

## 2. Como as peças se encaixam

```
dbFrigus (legado)  --RPA Python-->  public.* (3FN, usado pelo app)
                                        |
                  dw.sp_load_all()      |  (chamada pelo RPA a cada ciclo)
                                        v
                          dw.* (estrela: dim_* + fact_stock_movement)
                          analytics.* (estrela em views)
                          public.vw_dm_* (resumos por usuário, grupo e estoque)
                          dw.vw_dau (DAU/WAU/MAU) <-- dw.user_daily_access <-- Core API

audit.row_change_log  <-- triggers em products e stock_products
governance.data_catalog + governance.access_levels (catálogo e níveis de acesso)
```

## 3. O que a revisão corrigiu

Tudo no Dev, em migrations numeradas de `20261102120000` a `20261102121100` (pasta `supabase/migrations/`):

- **`pair_key` das conversas privadas:** o separador é `-`, igual ao das conversas existentes (`120000`).
- **Procedures:** as três usavam `integer` onde os ids são `uuid` e não funcionavam. Foram recriadas (`120100`).
- **CTE recursiva:** árvore de categorias com 22 nós (`120200`).
- **Desempenho:** a view de engajamento agrega cada tabela antes do join (`120300`).
- **Catálogo:** descrições de tabelas e colunas (`120400` a `120700`, `121100`).
- **`users.senha`:** removida. Guardava só o placeholder `VAZIO` e nenhum consumidor a usava (`120800`).
- **`stock_products.category`:** triggers mantêm a coluna igual a `products.category`, nos dois sentidos (`120900`).
- **Níveis de acesso:** quatro níveis e seis classificações, com FK e CHECK no catálogo (`121000`).

## 4. Pendências

1. **Prod.** Nenhuma migration `20261102120*` ou `121*` foi aplicada no FrigusDB Prod. Antes, conferir se a `20261102010908` já está lá e se conversas novas saíram com `_` no `pair_key`. Antes de aplicar a `120800`, conferir em `pg_stat_statements` se alguma consulta de Prod cita `senha`.
2. **Backup.** Definir RPO, RTO e responsáveis e registrar um teste de restauração. A sugestão do rascunho era RPO de 24 h e RTO de 4 h.
3. **DAU no banco.** O requisito pede registro automático no Postgres. Hoje a Core API faz o `INSERT ... ON CONFLICT DO NOTHING`. Para cumprir, o banco precisaria de uma função (por exemplo `dw.fn_register_access(uuid)`) que a API só chamasse.
4. **`stock_products.category`.** Para eliminar a redundância de vez, é preciso tirar a coluna da Core API, do `frigus-ai`, do RPA e da procedure `sp_purchase_shopping_list_item`, e só então executar `DROP COLUMN`.
5. **Catálogo.** Revisar com o backend as descrições inferidas das colunas.
6. **Segurança.** Os níveis de acesso são política, não bloqueio. A entrega decidiu não criar policies de RLS nem policies de Storage, então os grants padrão do Supabase continuam valendo para `anon` e `authenticated`. O acesso ao banco deve ser só pela Core API.
7. **RPA.** Não guarda histórico de execuções (só log em console) e só insere: alterações e exclusões na origem não chegam. Uma linha com problema derruba o ciclo inteiro. Confirmar que o `.env` está no `.gitignore`.
8. **DW.** A carga refaz a fato inteira (`TRUNCATE` + `INSERT`), o que não escala bem com muito mais dados.
9. **Tabelas sem uso.** `dm_stock_health_daily`, `dm_user_ltv` e `dm_recipe_performance` estão vazias. Ou carregar ou remover.
10. **Constraint.** `chk_stock_products_quantity` está `NOT VALID`, então não valida linhas antigas.
11. **Modelo no DrawDB.** O PNG em `entregas/01-modelagem/modelo-logico.png` ainda mostra `users.senha`. O `modelo-logico-drawdb.sql` está atualizado.
