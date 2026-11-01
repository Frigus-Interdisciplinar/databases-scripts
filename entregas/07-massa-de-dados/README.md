# Massa de dados

`generate_dataload.py` gera massa sintetica em portugues usando Faker, com carga em lotes e IDs/FKs coerentes. O script pode gerar milhares de registros; execute somente em banco de desenvolvimento vazio/restauravel, pois nao e um upsert e pode colidir com dados existentes.

O FrigusDB Dev ja supera 500 registros em entidades como `users`, `groups`, `stocks`, `stock_products`, `stock_movements`, `messages` e `transactions`, verificado por `COUNT(*)`. O snapshot do banco nao inclui dados.

## Geracao

Instale `Faker` em ambiente virtual e rode `python generate_dataload.py > initial_volume_seed.sql`. Revise o SQL e o projeto alvo antes de carga. O script cria uma carga sintetica, nao e migracao estrutural.
