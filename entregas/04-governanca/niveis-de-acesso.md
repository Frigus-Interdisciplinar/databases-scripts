# Níveis de acesso e classificação dos dados

O catálogo (`governance.data_catalog`) classifica cada tabela, view e coluna com um **nível de acesso** e uma **classificação**. Antes, os dois campos eram frases longas e diferentes por migration. Agora são valores controlados:

- `access_level` tem chave estrangeira para `governance.access_levels`.
- `data_classification` tem `CHECK` com seis valores.

Definido pela migration `20261102121000_niveis_de_acesso_catalogo.sql`.

## Níveis

| Nível | Ordem | O que é | Quem acessa | Em BI |
|---|---:|---|---|---|
| `PUBLICO` | 1 | Dado que pode ser lido sem autenticação. | Qualquer pessoa | Livre |
| `INTERNO` | 2 | Dado operacional do produto, sem dado pessoal, financeiro ou credencial. | Core API e equipe de dados | Livre nas camadas `dw` e `analytics` |
| `RESTRITO` | 3 | Dado pessoal (LGPD), financeiro, de auditoria ou de governança. | Core API e DBA; BI apenas agregado ou mascarado | Somente agregado ou mascarado |
| `CONFIDENCIAL` | 4 | Credenciais, hashes e tokens. | Somente a Core API, para validar; nunca lido por pessoas ou BI | Nunca exposto |

Hoje nenhum objeto é `PUBLICO`: o nível existe para completar a escala.

## Classificações

| Classificação | Quando se aplica | Nível resultante |
|---|---|---|
| `CREDENCIAL` | `hash_password`, `token_hash` | `CONFIDENCIAL` |
| `FINANCEIRO` | Cobranças, despesas, entradas e saídas de dinheiro, compras de alimentos, notas fiscais lidas, `total_spent` | `RESTRITO` |
| `PESSOAL` | Nome, e-mail, data de nascimento, foto, `google_id`, conteúdo de mensagens, restrições alimentares, assunto de suporte | `RESTRITO` |
| `AUDITORIA` | Tudo no schema `audit` | `RESTRITO` |
| `TECNICO` | Schema `governance` e `flyway_schema_history` | `RESTRITO` (governance) ou `INTERNO` |
| `NEGOCIO` | O restante | `INTERNO` |

A linha de cada objeto (`column_name = '__TABLE__'`) recebe o nível mais alto entre as suas colunas. Por isso `public.users` aparece como `CONFIDENCIAL` (por causa de `hash_password`), embora a maior parte das suas colunas seja `INTERNO` ou `RESTRITO`.

## Resultado no Dev (2026-11-02)

| Nível | Objetos | Colunas |
|---|---:|---:|
| `CONFIDENCIAL` | 3 | 3 |
| `RESTRITO` | 22 | 165 |
| `INTERNO` | 45 | 463 |

As três colunas `CONFIDENCIAL` são `users.hash_password`, `password_reset_tokens.token_hash` e `group_invitations.token_hash`.

Para consultar:

```sql
SELECT object_schema, object_name, column_name, access_level, data_classification
FROM governance.data_catalog
WHERE access_level IN ('RESTRITO', 'CONFIDENCIAL') AND column_name <> '__TABLE__'
ORDER BY access_level DESC, object_schema, object_name;
```

## O que isto não faz

Os níveis descrevem a **política pretendida**. Os grants e o RLS reais do schema `public` seguem os padrões do Supabase, e esta entrega decidiu não criar policies de RLS. Ou seja, o catálogo diz quem deveria acessar cada dado, mas o banco ainda não impede, por si só, que um papel com grant leia uma coluna `RESTRITO`. A aplicação deve acessar o banco só pela Core API.

## Como manter

- Tabela nova: registrar no catálogo (upsert da migration `20261101185253`) e ajustar as listas de `PESSOAL` e `FINANCEIRO` em uma migration nova. Sem isso, a coluna entra como `NEGOCIO` e `INTERNO`.
- As migrations `20261101185253`, `20261101185318` e `20261102120400` gravam `access_level` como texto livre e precisam rodar **antes** da `20261102121000`. Reexecutá-las depois da constraint falha.
- A classificação por coluna é por regra e nome. Revisar com o time de produto, principalmente os campos `PESSOAL`.
