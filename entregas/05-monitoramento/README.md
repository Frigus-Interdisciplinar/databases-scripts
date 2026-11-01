# DAU por acesso autenticado

A migration cria `dw.user_daily_access` com chave `(user_id, access_date)` e a view `dw.vw_dau`, que calcula DAU, WAU, MAU, DAU/MAU e variação diária. A Core API grava o primeiro acesso por usuário/dia depois de validar token, usuário ativo e sessão. A chave primária impede duplicação diária; o dia de negócio usa `America/Sao_Paulo`.

## Estado de implantação

O schema está em Dev e Prod. A tabela de Prod existe e estava vazia na última consulta. A mudança de código está representada em `core-api-dau.patch` e já aparece no working tree local do repositório da Core API, mas ainda não foi publicada no runtime. A coleta começa após integrar a alteração, configurar o acesso e implantar a API.

O papel `frigus_core_api` foi criado em Prod com `BYPASSRLS` e grants para operação da API; a aplicação ainda precisa mudar da credencial `postgres` para esse papel em uma implantação coordenada. A senha deve ser armazenada em secret manager e nunca versionada neste pacote.

Nenhuma policy RLS nova foi adicionada. O registro de métrica é best-effort: falha ao gravar DAU não rejeita requisição autenticada. A função de escrita e a view ficam no schema `dw`.
