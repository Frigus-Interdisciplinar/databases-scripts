# Entregas do Projeto Interdisciplinar

Este pacote separa os artefatos pela rubrica e registra o que foi aplicado em **FrigusDB Dev**. As migrations versionadas em `supabase/migrations/` sao a fonte das mudancas de banco desta entrega. O arquivo `sql/schema/frigus_dev_base_schema.sql` e o estado-base anterior a elas; nao reaplicar sozinho.

| Rubrica | Pasta / evidencia |
|---|---|
| Modelo relacional, PK/FK e cardinalidades | `01-modelagem/` |
| Massa de dados e modelo dimensional/ETL | `02-engenharia-de-dados/`, `07-massa-de-dados/` |
| Functions, procedures, auditoria, indices e planos | `03-objetos-e-otimizacao/` |
| Catalogo, niveis de acesso e recuperacao | `04-governanca/` |
| Registro de DAU | `05-monitoramento/` |
| CTE recursiva/heranca | `06-estruturas-avancadas/` |
| RPA | `08-integracao-rpa/README.md` (integracao mantida no repositorio separado, fora deste escopo) |

## Estado aplicado

- Catalogo tecnico em `governance.data_catalog`, com 658 linhas cobrindo 65 objetos e suas colunas apos a carga do catalogo; schema privado, sem USAGE para `anon`, `authenticated` ou `service_role`.
- Tabela `dw.user_daily_access`, indice para consultas por dia e `dw.vw_dau` recalculada sobre os acessos autenticados registrados pela Core API.
- Core API local registra no maximo um acesso por usuario/dia apos validar token, usuario e sessao. O codigo e o patch correspondente estao em `05-monitoramento/`; o patch precisa ser revisado/integrado e implantado no repositorio/runtime da API para iniciar a coleta.
- Nenhuma policy nova de RLS foi criada.
- A Core API do Dev conecta atualmente como `postgres`, confirmado em `pg_stat_activity`; isso permite a gravacao, mas e uma credencial superprivilegiada. Trocar por papel de minimo privilegio requer rotacao coordenada de `DATABASE_USERNAME`/`DATABASE_PASSWORD` e deploy, fora desta migration.
- A view de DAU e a tabela de acesso nao tem grants para `PUBLIC`, `anon`, `authenticated` ou `service_role`. A tabela ainda esta vazia ate o deploy da API com o registro.

## Validacao

`03-objetos-e-otimizacao/explain-analyze-dev.md` guarda os planos e tempos obtidos no Dev. A carga existente ja excede 500 registros em varias entidades; o gerador reproducivel esta em `07-massa-de-dados/generate_dataload.py`.
