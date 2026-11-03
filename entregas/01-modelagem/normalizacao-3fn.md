# Análise de normalização

## Escopo

A avaliação de normalização aplica-se ao modelo operacional de `public`, e não às tabelas deliberadamente analíticas. `analytics` e `dw` são modelos dimensionais; `audit.row_change_log` é um log de eventos; as tabelas `public.dm_*` são agregados materializados por aplicação e ficam fora do modelo transacional.

O desenho operacional separa usuários, grupos, estoques, produtos, listas, conversas, assinaturas e demais entidades em tabelas próprias. Relações muitos-para-muitos usam tabelas associativas, como `user_groups`, `conversation_participants`, `recipe_ingredients`, `recipe_favorites`, `shopping_list_products` e `message_reads`. Chaves estrangeiras documentam as dependências entre entidades; UNIQUEs impedem duplicidade nas associações e relações 1:1. O inventário completo está em `relacionamentos-pk-fk.csv` e no catálogo.

## Evidências de 1FN, 2FN e 3FN

- **1FN:** as colunas operacionais representam valores escalares; anexos, ingredientes, participantes, leituras e itens de listas são linhas em tabelas próprias, não listas repetidas numa coluna.
- **2FN:** nas associações com chave composta, atributos não-chave dependem da associação inteira. Exemplos: preferências do usuário são identificadas por `user_id`; participantes por `(conversation_id, user_id)`; leituras vinculam mensagem e participante.
- **3FN:** atributos de entidades são mantidos na entidade correspondente e as referências usam FKs. Produtos e estoques são entidades distintas; suas ocorrências em estoque ficam em `stock_products`. Relações de compra, receita, grupo e conversa também são decompostas em entidades e tabelas de junção.

## Exceções e decisões explícitas

- **`public.users.senha` (resolvida).** Guardava só o placeholder `VAZIO` (valor do `DEFAULT`) nos 3.356 usuários e duplicava o papel de `hash_password`. Em 2026-11-02, no Dev, nenhuma view, função, trigger ou índice a usava, e nenhuma consulta da Core API a lia ou escrevia: em `pg_stat_statements`, a Core API lê `hash_password` e não cita `senha`, e o `frigus-ai`, o RPA e o `dataload.sql` também não. A coluna foi removida na migration `20261102120800`, e `hash_password` é a única credencial.
- **`public.stock_products.category` (redundância controlada).** Replica `products.category` (dependência transitiva via `product_id`) em mais de 33 mil linhas, com 0 divergências. A Core API e o `frigus-ai` leem e gravam a coluna, então ela não pôde ser removida sem mudar o backend. A migration `20261102120900` impede a divergência: ao inserir ou alterar um item de estoque, a categoria é copiada de `products`, e ao alterar `products.category` a mudança é propagada aos itens. A violação de 3FN continua fisicamente, agora como cópia mantida pelo banco. Para eliminá-la: retirar o campo da Core API, do `frigus-ai`, do RPA e da procedure `sp_purchase_shopping_list_item`, e então executar `DROP COLUMN`.
- `public.transactions.plan_id` registra o plano associado à transação; se for exigido preservar preço/nome históricos, esses valores devem ser tratados como snapshot de negócio e documentados como tal.
- `public.dm_*` pode conter medidas e descrições desnormalizadas intencionalmente para consulta; não é fonte transacional.
- O modelo dimensional estrela repete atributos descritivos nas dimensões para facilitar BI e não deve ser avaliado pelas regras de normalização do OLTP.

Esta análise demonstra a decomposição aplicada e identifica dívidas semânticas que precisam de validação de produto; não substitui revisão de regras de negócio para cada coluna histórica.
