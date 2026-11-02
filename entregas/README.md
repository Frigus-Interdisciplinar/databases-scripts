# Entregas do Projeto Interdisciplinar

Esta pasta mapeia os requisitos da rubrica aos artefatos e registra o que foi observado nos bancos em 2026-11-01.

| Requisito | Evidências |
|---|---|
| Modelo relacional, chaves e cardinalidades | [`01-modelagem/modelo-relacional.md`](01-modelagem/modelo-relacional.md), [`01-modelagem/relacionamentos-pk-fk.csv`](01-modelagem/relacionamentos-pk-fk.csv) e [`01-modelagem/normalizacao-3fn.md`](01-modelagem/normalizacao-3fn.md) |
| Massa verossímil de pelo menos 500 registros | [`07-massa-de-dados/README.md`](07-massa-de-dados/README.md), gerador, [`seed-manifest.json`](07-massa-de-dados/seed-manifest.json), [`../sql/dataload/dataload.sql`](../sql/dataload/dataload.sql) e verificação SQL |
| ETL, Data Mart, CTEs e Window Functions | [`02-engenharia-de-dados/data-mart-etl.md`](02-engenharia-de-dados/data-mart-etl.md), definições em `../sql/views/` e rotina em `../sql/functions/dw__sp_load_all.sql` |
| RPA legado → Frigus | [`08-integracao-rpa/README.md`](08-integracao-rpa/README.md) e [repositório RPA](https://github.com/Frigus-Interdisciplinar/frigus-rpa), mantido fora deste repositório |
| Functions, procedures, auditoria e índices | [`03-objetos-e-otimizacao/objetos-sql.md`](03-objetos-e-otimizacao/objetos-sql.md), `../sql/functions/`, `../sql/procedures/`, `../sql/triggers/` e `03-objetos-e-otimizacao/explain-analyze-dev.md` |
| Catálogo, segurança, backup e recuperação | [`04-governanca/catalogo-de-dados.csv`](04-governanca/catalogo-de-dados.csv), [`04-governanca/seguranca-dev.md`](04-governanca/seguranca-dev.md) e [`04-governanca/backup-recuperacao.md`](04-governanca/backup-recuperacao.md) |
| DAU | [`05-monitoramento/README.md`](05-monitoramento/README.md), migration e patch da Core API |
| Estruturas avançadas | [`06-estruturas-avancadas/cte-recursiva.md`](06-estruturas-avancadas/cte-recursiva.md) e migration `20261102120200` |

## Estado verificado

As migrations `20261102120000` a `20261102120400` corrigem o separador do `pair_key`, as procedures com `uuid`, a árvore de categorias (CTE recursiva), a otimização da view de engajamento e as descrições do catálogo. Foram aplicadas no Dev. A `20261102120500` acrescenta descrições de negócio para os 36 objetos que faltavam e para colunas-chave; 607 das 693 colunas do catálogo ainda têm descrição genérica. **Nada foi aplicado em Prod.** Aplicar em Prod exige aprovação, e a aplicação precisa acontecer antes de a Core API usar as procedures.

- O schema e objetos necessários foram inicializados em Prod; as três migrations do pacote aparecem aplicadas no histórico remoto.
- Na última inspeção de Prod: 15 functions, 3 procedures, 29 triggers, 163 índices, 185 constraints, 24 tabelas com RLS habilitado e uma policy. A divergência observada em relação ao inventário de Dev foi um índice e uma constraint. Não foram feitas alterações para forçar igualdade; revisar antes de qualquer replicação adicional.
- O catálogo `governance.data_catalog` contém 658 linhas referentes a 65 objetos; o CSV nesta pasta é o export dessa tabela.
- Storage: os buckets e sete objetos presentes no escopo copiado foram transferidos. A cópia de objetos não faz parte de backup do PostgreSQL.
- A fotografia de schema Prod está em `../sql/schema/frigus_prod_schema.sql`; configurações e inventário de Storage em `../supabase/storage/`; script de grants sem senha em `../sql/roles/frigus_core_api.sql`.
- O Storage foi copiado, mas o manifesto registra zero políticas de Storage. Confirmar as permissões necessárias à aplicação antes de abrir tráfego real; detalhes em `../supabase/storage/README.md`.
- Em 2026-11-01 foi carregada massa sintética de 171.726 registros em 22 tabelas. As tabelas principais incluem 3.000 usuários, 900 grupos, 32.436 itens de estoque, 42.166 movimentos, 19.377 mensagens e 7.671 transações. Os usuários têm credenciais fictícias e não autenticam na Core API.
- A carga desativou dentro da transação apenas os triggers que geram notificações e reativou ambos antes do `COMMIT`; triggers de auditoria e integridade permaneceram ativos. Foram registrados 32.516 eventos de auditoria e 7.671 eventos de transação.
- A massa usa conversas de grupo; conversas privadas foram omitidas porque o trigger atual chama `fn_pair_key(integer, integer)` embora `users.id` e `conversation_participants.user_id` sejam UUID. O gerador contém uma trava contra segunda carga em base com dados.
- `dw.user_daily_access` existe, mas está vazia. A alteração local da Core API registra um acesso diário por usuário após autenticação; o patch não foi implantado no runtime. A coleta só começa após integrar e publicar essa alteração.
- O papel `frigus_core_api` foi criado em Prod com `BYPASSRLS`; o Core API ainda precisa de configuração/deploy coordenado para utilizar esse usuário em vez de `postgres`. A credencial deve ser configurada por secret manager, nunca neste repositório.
- Nenhuma policy RLS nova foi criada nesta entrega. O inventário existente inclui tabelas com RLS e uma policy de auditoria; veja a revisão de segurança para limitações do modelo.

Os exports em `../sql/functions`, `../sql/procedures`, `../sql/triggers` e `../sql/views` são documentação reproduzível do estado observado. Não os aplique por cima de um banco inicializado; para alterações futuras, crie migrations versionadas.
