# Massa de dados sintética

`generate_dataload.py` gera `sql/dataload/dataload.sql` com dados fictícios em português, IDs e FKs coerentes, seed dos cinco planos e 165.052 registros em 22 tabelas. O manifesto com a contagem gerada está em `seed-manifest.json`.

Use apenas num banco descartável de teste já inicializado com o schema e as migrations. A carga é `INSERT`, não sincroniza nem substitui dados existentes; não execute em Prod ou em Dev com dados que devam ser preservados. Usuários, emails e credenciais gerados são sintéticos e não servem para autenticação real.

## Gerar novamente

Requer Python 3 e `Faker`. A partir da raiz do repositório:

```sh
python3 -m venv .venv
. .venv/bin/activate
pip install Faker
python3 entregas/07-massa-de-dados/generate_dataload.py > sql/dataload/dataload.sql
```

Revise o SQL e o destino antes de executar. Para carregar em uma base de teste, use a URL desse banco e `psql -X -v ON_ERROR_STOP=1 -f sql/dataload/dataload.sql`. Ao concluir, execute `psql ... -f sql/dataload/verify_volume.sql` e compare os totais com o manifesto.
