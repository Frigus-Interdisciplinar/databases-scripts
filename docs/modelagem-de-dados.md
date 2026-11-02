# Modelagem de Dados — revisão e explicação (Frigus)

Revisão feita em 02/11/2026 direto no Postgres (Supabase) em modo somente leitura, mais o RPA (`Inter/rpa`) e as queries (`Obsidian_Queries_Frigus`). Nada foi alterado no banco.

## 1. Placar contra os requisitos

| # | Requisito | Status | Resumo |
|---|---|---|---|
| 1a | Banco normalizado (3FN) | ⚠️ Quase | Estrutura sólida, 2 desvios pequenos de 3FN |
| 1b | PKs, FKs, cardinalidades | ✅ | Todas as tabelas têm PK; dezenas de FKs; 1:N, N:N e 1:1 presentes |
| 1c | Massa de dados ≥ 500 | ✅ | Tabelas com milhares de linhas. Parte é de QA (ver 4.7) |
| 2a | RPA legado → novo banco | ✅ com ressalvas | Transação única, rollback, retry. Sem log de execução e só insere |
| 2b | Camada BI (Star Schema) | ✅ | `dw.*` (estrela física) e `analytics.*` (estrela em views) |
| 2c | CTEs | ✅ | Em todas as views BI e queries |
| 2d | Window Functions | ✅ | Running total, RANK, LAG, ROW_NUMBER |
| 3a | 2 Functions + 2 Procedures | ✅ | Procedures recriadas com `uuid` e testadas em 02/11 (ver 4.1) |
| 3b | Triggers de auditoria (2 tabelas) | ✅ | `products` e `stock_products` → `audit.row_change_log` |
| 3c | EXPLAIN ANALYZE + índices | ✅ | Análise registrada em 02/11: view de engajamento de 1,7 s para ~60 ms (ver seção 8 de banco-de-dados.md) |
| 4a | Catálogo de dados | ✅ com ressalva | 693 linhas; tabelas descritas, colunas ainda genéricas |
| 4b | Backup e recuperação documentados | ❌ | Não existe documento. Rascunho na seção 6 |
| 5 | DAU automático no Postgres | ⚠️ | Tabela e view existem; o INSERT vem do backend, não de objeto do banco |
| 6 | CTE Recursiva ou Herança | ✅ | `product_categories` + `analytics.vw_category_tree` (WITH RECURSIVE) |

## 2. Como as peças se encaixam

```
dbFrigus (legado)  --RPA Python-->  public.* (3FN, usado pelo app)
                                        |
                       dw.sp_load_all() |  (manual hoje)
                                        v
                          dw.* (estrela: dim_* + fact_stock_movement)
                          analytics.* (estrela em views)
                          public.vw_dm_* (resumos por usuário/grupo/estoque)
                          dw.vw_dau (DAU/WAU/MAU) <-- dw.user_daily_access <-- backend

audit.row_change_log  <-- triggers em products e stock_products
governance.data_catalog (metadados)
```

## 3. Explicação por requisito

**Modelo e relacionamentos.** O núcleo é `users → user_groups ← groups → stocks → stock_products → products`.
- N:N: `users`↔`groups` via `user_groups`; `recipes`↔`products` via `recipe_ingredients`; `conversations`↔`users` via `conversation_participants`.
- 1:N: `stocks → stock_products`, `stock_products → stock_movements`, `plans → subscriptions`, `subscriptions → transactions → transaction_events`.
- 1:1: `user_preferences` e `user_app_settings` (a PK é o próprio `user_id`).
- Regras no próprio banco: enums (`product_status_enum`, `movement_type_enum`…), `CHECK` (quantidade ≥ 0, preço > 0, `member_role`), `UNIQUE (product_id, stock_id, expire_date)`.

**RPA.** `main.py` roda em loop (ou `--once`, `--dry-run`). Cada ciclo abre conexões novas, lê a origem (conexão `readonly`), grava no destino numa transação só e faz `commit`. Qualquer erro vira `rollback`. Queda de rede repete até 3 vezes com espera crescente (`tenacity`). Valor desconhecido na origem para o ciclo com erro claro. Cada passo é idempotente (não duplica ao rodar de novo).

**BI.**
- `dw.*`: dimensões `dim_date/group/stock/product/user` e fato `fact_stock_movement` (41.391 linhas), carregados por `dw.sp_load_all()`.
- `analytics.*`: `dim_date/plan/product/stock` e fatos `fact_inventory_snapshot`, `fact_transactions` (esta traz `SUM() OVER` como *running total* de receita e `RANK()` por dia).
- Window functions também em `vw_top_ingredients_analytics` (`ROW_NUMBER`, `RANK`, `FIRST_VALUE`, `SUM OVER`), `vw_user_engagement_analytics` (`RANK`, `DENSE_RANK`) e `dw.vw_dau` (`LAG`).

**Functions e procedures.** Functions: `fn_compute_product_status_enum`, `fn_low_stock_products`, `fn_suggest_recipes` (e `dw.sp_load_all`). Procedures: `sp_close_shopping_list`, `sp_purchase_shopping_list_item`, `sp_get_or_create_private_conversation`.

**Auditoria.** `audit.capture_row_change()` grava `TG_TABLE_SCHEMA`, `TG_TABLE_NAME`, `TG_OP`, `CURRENT_USER`, `to_jsonb(OLD)` e `to_jsonb(NEW)` em `audit.row_change_log` (33.578 linhas; 31.862 UPDATE de `stock_products`). Atende o pedido (NEW, OLD, TG_OP, CURRENT_USER).

**Catálogo.** `governance.data_catalog` descreve objeto, coluna, tipo, regra de negócio, nível de acesso e classificação.

**DAU.** `dw.user_daily_access (user_id, access_date)` com PK composta; o backend faz `INSERT ... ON CONFLICT DO NOTHING` (1.109 chamadas vistas). `dw.vw_dau` calcula DAU, WAU, MAU e %DAU/MAU.

## 4. O que está faltando ou errado (por prioridade)

1. **[CORRIGIDO em 02/11] As 3 procedures estavam quebradas.** Declaram `p_list_id integer`, `p_user_a integer`, `p_user_b integer`, mas `shopping_lists.id`, `conversations.id` e `users.id` são `uuid`. Chamar com ids reais dá erro de tipo. `sp_purchase_shopping_list_item` ainda comenta que `trg_stock_movements_apply` atualiza o estoque, mas essa trigger **não existe** no banco (`stock_movements` não tem trigger). `fn_pair_key(int,int)` tem o mesmo problema. **Feito** (`correcoes-procedures-e-categorias.sql`): procedures recriadas com `uuid`, a `sp_purchase_shopping_list_item` agora atualiza a quantidade sozinha (não criei a trigger para não somar em dobro com o app), `fn_pair_key(uuid,uuid)` criada e a trigger de `pair_key` corrigida. Testado com `CALL` em transação com ROLLBACK antes de aplicar.
2. **[CORRIGIDO em 02/11] Sem CTE recursiva (req. 6).** Criada `public.product_categories` (22 nós, auto-referência, RLS ligado) e `analytics.vw_category_tree` com `WITH RECURSIVE` (caminho, profundidade e total de produtos por nó). Texto original: Não há hierarquia no modelo hoje. Candidatos naturais: categorias de produto em árvore (`categories.parent_id`) consultadas com `WITH RECURSIVE`, ou herança entre tabelas de movimentação. Hoje o requisito está sem entrega.
3. **Backup/recuperação sem documento (req. 4b).** Rascunho na seção 6 para o time validar.
4. **DAU não é totalmente "no banco".** O requisito pede registro automático diretamente no Postgres. O banco só recebe o INSERT do backend. Para cumprir, pode-se criar a função `dw.fn_register_access(uuid)` e o backend só a chama, ou uma trigger em `auth.sessions`/`users.last_login`. Como está, depende do app.
5. **[CORRIGIDO em 02/11] O DW não era recarregado sozinho.** O RPA agora chama `dw.sp_load_all()` ao fim de cada ciclo (commit `ce97cb6` na `main` do `frigus-rpa`); falta só confirmar rodando `python main.py --once`. Texto original: Último `loaded_at`: 16/10/2026; a origem já tem 8 movimentos a mais. Não há `pg_cron` instalado (extensões: só `pg_stat_statements`, `pgcrypto`, `uuid-ossp`, `plpgsql`, `supabase_vault`). Opções: ligar `pg_cron` ou fazer o RPA chamar `SELECT dw.sp_load_all()` ao fim do ciclo. Além disso, o `TRUNCATE` + reinserção da fato não é incremental.
6. **EXPLAIN ANALYZE sem registro (req. 3c).** Há ~100 índices bem escolhidos (parciais, compostos, GIN para busca em mensagens), e o `pg_stat_statements` mostra que alguém já rodou `EXPLAIN ANALYZE`, mas falta o antes/depois documentado. Exemplo que fiz agora (resultado, não alteração): `dw.vw_dau` roda em 2,3 ms usando `Index Only Scan` em `ix_user_daily_access_date_user`; a fato filtra por data com `Bitmap Index Scan` em `ix_fact_mov_date`. Com poucos dados o plano é trivial; para a apresentação, medir uma consulta pesada (ex.: `vw_user_engagement_analytics`, que faz 3 `LEFT JOIN` e `COUNT(DISTINCT)`) antes e depois de um índice.
7. **Massa de dados é parte de QA.** Há usuários `Frigus QA…@example.test/.invalid`. Os 500+ registros existem, mas "verossímeis" fica mais fácil de defender se o `dataload.sql` existir. Hoje `databases-scripts/sql/dataload/dataload.sql` está **vazio (0 linhas)**.
8. **Normalização, desvios pontuais:**
   - `stock_products.category` repete `products.category` (dependência transitiva via `product_id`; 0 divergências hoje). Também `stock_products.product_status` é derivado da validade (mantido por trigger).
   - `users` tem `senha` e `hash_password` ao mesmo tempo.
   - `dm_stock_health_daily`, `dm_user_ltv`, `dm_recipe_performance` são desnormalizadas e estão **vazias** (0 linhas). Ou carregar ou remover.
   - `chk_stock_products_quantity` está `NOT VALID` (não valida linhas antigas).
9. **[PARCIAL em 02/11] Catálogo raso.** Adicionadas as 2 tabelas que faltavam e os 2 objetos novos (693 linhas, 66 objetos) e escritas descrições de negócio em 32 tabelas; as descrições das colunas continuam genéricas. Texto original: 654 de 658 linhas têm descrição genérica ("Coluna X de public.Y"). `support_requests` e `user_app_settings` estão fora do catálogo. A coluna de nível de acesso traz texto longo igual para quase tudo e a classificação diz "revisar classificacao funcional" em 575 linhas. Falta uma descrição de negócio real, pelo menos nas tabelas principais.
10. **Segurança.** 30 tabelas sem RLS, entre elas `password_reset_tokens`, `notifications`, `business_expenses`, `dw.*` e `governance.data_catalog`. Os papéis `anon` e `authenticated` têm grants em `public` (padrão do Supabase). Se a API de dados do Supabase estiver exposta, isso é risco. Conferir se essas tabelas só são acessadas pelo backend. O catálogo cita que o backend conecta como `postgres`; usar um papel com menos privilégio é melhor.
11. **Arquivos locais defasados.** `databases-scripts/sql/schema/schema.sql` ainda usa ids inteiros e enums em português (`'Entrada'`, `'Saída'`), diferente do banco real (uuid, enums em inglês). `datamart/04…` e `05…` dizem "PENDENTE", mas já estão aplicados. `fn_compute_product_status.sql` local retorna o enum antigo ('Vencido'); o banco tem duas versões (`..._enum` e a de texto). `rpa/docs/tabelas.md` cita `produtosgeladeira`/`frigorificos`, mas o código lê `itemgeladeira`/`frigorifico`. Sugestão: exportar o DDL real e atualizar os arquivos.
12. **RPA, melhorias:** não grava histórico de execuções (qual ciclo, quantas linhas, falhou por quê) em tabela; só loga em console. Só insere (atualização e exclusão na origem não chegam). Linhas problemáticas fazem o ciclo inteiro falhar em vez de ir para uma tabela de rejeitados. A pasta `rpa/.env` tem credenciais: confirmar que está no `.gitignore`.

## 5. Plano de correção sugerido (ordem)

1. Corrigir procedures (uuid) e a trigger de movimentação, com um teste `CALL` em transação com `ROLLBACK`.
2. Criar uma estrutura recursiva: `categories` com `parent_id` + view com `WITH RECURSIVE` (cumpre o item 6).
3. Registrar 2 análises `EXPLAIN ANALYZE` (antes/depois) em um `.md`.
4. Fechar o ciclo do DW: chamar `dw.sp_load_all()` ao fim do RPA.
5. Aprovar o documento de backup (seção 6) e testar uma restauração.
6. Enriquecer o catálogo nas tabelas principais.

## 6. Backup e recuperação (rascunho para validar com o time)

> Rascunho: confirmar no painel do Supabase qual plano o projeto usa (backups diários e PITR dependem do plano) antes de assinar este procedimento.

**Backup**
1. Automático do Supabase: backup diário gerenciado (verificar retenção do plano). PITR se o plano tiver.
2. Lógico semanal (e antes de qualquer migração): 
   ```bash
   pg_dump "$DB_URL" --format=custom --no-owner --file=frigus_$(date +%F).dump
   ```
   Guardar fora do projeto (ex.: drive da equipe), com retenção definida (ex.: 4 semanas).
3. Antes de mudanças de schema: migração versionada (Flyway já é usado, versões 003 a 019 em `flyway_schema_history`).

**Recuperação**
1. Falha de dados (DELETE/UPDATE errado): usar `audit.row_change_log`, que guarda `old_row` de `products` e `stock_products`, para reconstruir a linha; se for grande, restaurar o ponto no tempo (PITR) em projeto novo e copiar as linhas.
2. Perda do banco: criar projeto novo e restaurar:
   ```bash
   pg_restore --no-owner --dbname="$NEW_DB_URL" frigus_AAAA-MM-DD.dump
   ```
3. Depois de restaurar: rodar `SELECT dw.sp_load_all();`, conferir contagens (`users`, `stock_products`, `stock_movements`) e testar login e uma consulta de BI.
4. Teste de restauração: fazer 1 vez por período e anotar data, duração e resultado.

**Responsáveis e RTO/RPO:** definir (sugestão: RPO 24 h, RTO 4 h).
