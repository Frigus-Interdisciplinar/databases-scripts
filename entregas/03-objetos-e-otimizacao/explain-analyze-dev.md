# EXPLAIN ANALYZE — FrigusDB Dev

Executado em `2026-11-01` sobre consultas SELECT de Data Mart e estoque. Tempos dependem do estado/compute do Dev e nao sao benchmark de producao.

| Consulta | Indice relevante observado | Plano/resultado |
|---|---|---|
| Movimentos agregados por data | `ix_fact_mov_date(date_key)` | Index Scan; 2 linhas lidas, 3 shared buffers; 1.422 ms. |
| Historico por estoque e periodo | `ix_fact_mov_stock(stock_key, date_key)` | Index Scan com as duas colunas na condicao; 0 movimentos para o primeiro estoque escolhido; 3.992 ms incluindo subconsulta. |
| Movimentos operacionais por data/estoque | `idx_stock_movements_date`, PK de `stock_products` | Bitmap Index Scan na data, seguido por lookup via PK; 6 movimentos, 30 shared buffers; 6.843 ms. |
| DAU por acesso | PK `(user_id, access_date)` e `ix_user_daily_access_date_user(access_date, user_id)` | Index Only Scan; tabela vazia (0 linhas), logo o plano mede apenas o caso sem dados; 0.931 ms. |

Nao foi criado indice novo sem evidenciar gargalo. Consultas 1 e 3 usaram os indices existentes. A consulta 2 tambem usou o indice composto, embora a amostra escolhida nao tenha movimentos recentes. No DAU, a tabela esta vazia ate a Core API atualizada receber trafego; repetir o plano apos gerar amostra real. Revisar os planos com `BUFFERS` antes de propor indices adicionais.
