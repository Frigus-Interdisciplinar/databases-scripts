# Observacoes de seguranca — FrigusDB Dev

Consultas e advisors executados apos as migrations desta entrega, em `2026-11-01`.

- `governance` nao tem `USAGE` para `anon`, `authenticated` ou `service_role`; a tabela de catalogo tambem nao tem SELECT para esses papeis. `dw.user_daily_access` e `dw.vw_dau` igualmente nao concedem leitura a esses papeis. Nenhum RLS novo foi ativado.
- A conexao JDBC ativa observada para a Core API usa `postgres`. Esse papel e superuser e contorna grants e RLS; autenticacao/autorizacao da aplicacao protege rotas, mas o segredo de banco comprometido permite acesso administrativo total. Trocar para papel dedicado e least-privilege requer rotacao coordenada do segredo e deploy.
- Advisor existente: 23 tabelas publicas com RLS ativo sem policies. Para cliente direto via Data API, isso resulta em bloqueio; Core API como `postgres` continua tendo acesso. O Advisor tambem aponta 16 rotinas publicas com `search_path` mutavel. Sao itens pre-existentes, nao criados pelas migrations desta entrega.
- Advisor de performance sinaliza 21 FKs sem indice cobridor e 24 indices sem uso observado. Os quatro planos guardados em `03-objetos-e-otimizacao/explain-analyze-dev.md` mostram os indices escolhidos nas consultas avaliadas. Nao foi removido nem criado indice sem analise de workload.

O modelo de acesso do Supabase combina grants (quem pode acessar o objeto pela Data API) e RLS (quais linhas podem ser acessadas). Esta entrega mantem o caminho de acesso da Core API e nao abre tabelas novas para clientes diretos. Veja [Securing your API](https://supabase.com/docs/guides/api/securing-your-api).
