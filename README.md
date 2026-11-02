# databases-scripts

Scripts PostgreSQL do Frigus e pacote organizado para a entrega interdisciplinar.

## Estrutura

- `entregas/` — documentos e evidências organizados pela rubrica.
- `supabase/migrations/` — migrations versionadas aplicadas em FrigusDB Dev e Prod.
- `sql/schema/frigus_dev_base_schema.sql` — snapshot do schema Dev anterior às migrations desta entrega.
- `sql/schema/frigus_prod_schema.sql` — dump schema-only dos schemas da aplicação (`public`, `analytics`, `audit`, `dw`, `governance`) obtido em 2026-11-01; sem dados, grants/roles ou schemas gerenciados do Supabase.
- `sql/functions/`, `sql/procedures/`, `sql/triggers/`, `sql/views/` — definições exportadas do schema atual observado em Prod.
- `sql/roles/frigus_core_api.sql` — grants e privilégios padrão do papel da Core API, sem senha.
- `supabase/storage/` — configuração e inventário dos buckets/objetos copiados.
- `sql/dataload/` — massa sintética reproduzível para ambiente descartável de teste.
- `sql/legacy/` — scripts anteriores de 20 tabelas, preservados como histórico e não como fonte atual.

## Estado dos ambientes em 2026-11-01

O bootstrap de schema e objetos foi aplicado ao FrigusDB Prod (`orucfmpyvbrfldvvqtus`), e as três migrations estão registradas no histórico remoto. Foram conferidos 15 functions, 3 procedures, 29 triggers, 658 linhas no catálogo técnico e os objetos de Storage copiados a partir do Dev.

Em 2026-11-01 foi carregada em Prod massa sintética de 171.726 registros em 22 tabelas para a entrega acadêmica; os usuários gerados não são contas reais e não devem ser usados para autenticação. A divergência conhecida em relação ao Dev é de um índice e uma constraint; consulte `entregas/README.md`. Nenhuma policy RLS nova foi criada. O manifesto de Storage registra zero políticas de Storage; validar permissões de leitura/escrita antes do tráfego real. O RPA está em [repositório separado](https://github.com/Frigus-Interdisciplinar/frigus-rpa).

O snapshot de Prod é uma fotografia de referência, não uma migration. O snapshot base Dev e migrations registram a evolução do schema; exports por objeto facilitam consulta. Não reaplique exports individuais num ambiente já inicializado; use migrations na ordem registrada para mudanças futuras. O SQL de role é uma configuração privilegiada de execução única e não contém senha. A carga em Prod foi uma exceção explícita para gerar volume acadêmico; o arquivo inclui uma trava que aborta se detectar dados de negócio e deve ser tratado como script de uso único em banco descartável.

## Entrega

Consulte [`entregas/README.md`](entregas/README.md) para a matriz de requisitos, evidências verificadas e pendências operacionais, incluindo o deploy da Core API que inicia a coleta de DAU.
