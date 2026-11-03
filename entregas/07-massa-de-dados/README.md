# Massa de dados sintética

Em 2026-11-01, `sql/dataload/dataload.sql` foi executado em Frigus Prod por solicitação explícita e inseriu 171.726 registros em 22 tabelas. O manifesto com a contagem por tabela está em `seed-manifest.json`; a consulta de validação está em `../../sql/dataload/verify_volume.sql`.

Os dados são fictícios e destinados à demonstração acadêmica. As 3.000 contas geradas têm hashes aleatórios e não são contas reais nem credenciais válidas para autenticação. O script é de uso único em banco descartável. Inclui uma trava transacional que interrompe a carga se encontrar dados em `users`, `groups`, `stocks`, `products` ou `stock_products`.

## Procedimento de carga

Para reproduzir em outra base, use somente um banco descartável inicializado com o schema e sem dados de negócio. A carga gera 900 grupos e 1.500 conversas de grupo; não gera conversas privadas porque o trigger atual usa `integer` para IDs de usuário, enquanto `users.id` é UUID. Corrija e versione esse trigger antes de ampliar a massa privada.

Durante a carga, apenas os triggers que produzem notificações em `stock_products` e `shopping_list_products` são desativados dentro da transação e reativados antes do `COMMIT`. Isso evita fan-out de notificações sintéticas e o timeout observado em Prod. Auditoria e demais triggers permanecem ativos. Em Prod, a execução terminou com 32.516 linhas de auditoria e 7.671 eventos de transação.

O arquivo é gerado por `generate_dataload.py` com Python 3 e `Faker`. Para reproduzir:

```sh
python3 -m venv .venv
. .venv/bin/activate
pip install Faker
python3 entregas/07-massa-de-dados/generate_dataload.py > sql/dataload/dataload.sql
```

Antes de carregar, revise o destino. Após carga em uma base descartável, execute `psql ... -f sql/dataload/verify_volume.sql` e compare as contagens com `seed-manifest.json`. Não execute novamente em Prod.
