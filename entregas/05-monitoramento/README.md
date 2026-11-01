# DAU por acesso autenticado

A migration cria `dw.user_daily_access` com chave `(user_id, access_date)` e a view `dw.vw_dau` calcula DAU, WAU, MAU, DAU/MAU e variacao diaria. A Core API grava o primeiro acesso por usuario/dia apos validar JWT, usuario ativo e sessao.

## Privilegios

Nenhum grant foi dado a `PUBLIC`, `anon`, `authenticated` ou `service_role`, e nenhuma policy RLS foi criada. A API atualmente conecta ao banco como `postgres`, conforme sessao JDBC observada no Dev. `postgres` ja tem acesso por propriedade/superuser; o desenho funcional nao exige grant adicional. Recomenda-se migrar a API para um usuario dedicado de minimo privilegio em mudanca coordenada, fora desta entrega, com rotacao do segredo e deploy.

## Integracao e operacao

`core-api-dau.patch` e o patch portavel da alteracao local em `SecurityFilter.java`. Aplicar no repositorio da Core API e fazer deploy para iniciar a coleta. O registro e best-effort: falha da metrica gera log no servidor sem rejeitar requisicao autenticada. A chave primaria impede duplicacao diaria. O fuso para o dia de negocio e `America/Sao_Paulo`.
