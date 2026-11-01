# Análise de normalização

## Escopo

A avaliação de normalização aplica-se ao modelo operacional de `public`, e não às tabelas deliberadamente analíticas. `analytics` e `dw` são modelos dimensionais; `audit.row_change_log` é um log de eventos; as tabelas `public.dm_*` são agregados materializados por aplicação e ficam fora do modelo transacional.

O desenho operacional separa usuários, grupos, estoques, produtos, listas, conversas, assinaturas e demais entidades em tabelas próprias. Relações muitos-para-muitos usam tabelas associativas, como `user_groups`, `conversation_participants`, `recipe_ingredients`, `recipe_favorites`, `shopping_list_products` e `message_reads`. Chaves estrangeiras documentam as dependências entre entidades; UNIQUEs impedem duplicidade nas associações e relações 1:1. O inventário completo está em `relacionamentos-pk-fk.csv` e no catálogo.

## Evidências de 1FN, 2FN e 3FN

- **1FN:** as colunas operacionais representam valores escalares; anexos, ingredientes, participantes, leituras e itens de listas são linhas em tabelas próprias, não listas repetidas numa coluna.
- **2FN:** nas associações com chave composta, atributos não-chave dependem da associação inteira. Exemplos: preferências do usuário são identificadas por `user_id`; participantes por `(conversation_id, user_id)`; leituras vinculam mensagem e participante.
- **3FN:** atributos de entidades são mantidos na entidade correspondente e as referências usam FKs. Produtos e estoques são entidades distintas; suas ocorrências em estoque ficam em `stock_products`. Relações de compra, receita, grupo e conversa também são decompostas em entidades e tabelas de junção.

## Exceções e decisões explícitas

- `public.users.senha` é coluna legada, além de `hash_password`; não está no modelo de autenticação usado pela Core API. Deve ser removida numa migração compatível após confirmar dependências em todos os consumidores.
- `public.stock_products.category` replica uma classificação do produto no registro do estoque. Pode representar um snapshot da classificação no momento de inclusão, mas o significado histórico não foi confirmado; por isso não se declara formalmente que essa coluna satisfaz 3FN sem regra temporal explícita.
- `public.transactions.plan_id` registra o plano associado à transação; se for exigido preservar preço/nome históricos, esses valores devem ser tratados como snapshot de negócio e documentados como tal.
- `public.dm_*` pode conter medidas e descrições desnormalizadas intencionalmente para consulta; não é fonte transacional.
- O modelo dimensional estrela repete atributos descritivos nas dimensões para facilitar BI e não deve ser avaliado pelas regras de normalização do OLTP.

Esta análise demonstra a decomposição aplicada e identifica dívidas semânticas que precisam de validação de produto; não substitui revisão de regras de negócio para cada coluna histórica.
