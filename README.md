# databases-scripts

Scripts PostgreSQL do Frigus e artefatos organizados para a entrega interdisciplinar.

- `entregas/` — documentos, dados de volume, DAU, auditoria, backup/recuperacao e evidencias da rubrica.
- `supabase/migrations/` — migrations aplicadas no FrigusDB Dev.
- `sql/schema/frigus_dev_base_schema.sql` — snapshot de referencia do schema Dev **anterior** as migrations desta entrega; nao reaplicar sozinho.
- `sql/functions/`, `sql/triggers/`, `sql/procedures/` — scripts por tipo de objeto.
- `sql/dataload/` — carga de dados.

O schema inicial em `sql/schema/schema.sql` e os scripts originais em `sql/` representam a modelagem anterior de 20 tabelas; nao sao a fonte de verdade para o estado atual do FrigusDB Dev. Para reconstruir o estado observado: usar o snapshot base e aplicar, em ordem, as migrations Supabase.

## Ambiente

As migrations desta entrega foram aplicadas somente ao **FrigusDB Dev** (`qskdjqqyuejeyzpkszyf`). Nao foram aplicadas a producao. RPA permanece em repositorio separado. Nenhuma nova policy RLS foi criada.

Para a matriz de evidencias e pendencias de deploy da Core API, consulte [`entregas/README.md`](entregas/README.md).
