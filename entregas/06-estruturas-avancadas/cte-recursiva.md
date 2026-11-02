# CTE recursiva e herança de tabelas

## Decisão

Implementada uma CTE recursiva sobre a hierarquia de categorias de produto. Herança de tabelas PostgreSQL não foi usada: as entidades do domínio não compartilham atributos em um modelo de especialização que justifique herança.

## Onde está

- Tabela `public.product_categories`: `parent_id` aponta para a própria tabela (auto-relacionamento 1:N). As folhas se ligam a `public.products.category` pelo `enum_value`, que tem UNIQUE.
- View `analytics.vw_category_tree`: usa `WITH RECURSIVE` para caminhar a árvore a partir das raízes e calcular, para cada nó, o caminho textual (`Alimentos > Hortifruti > Frutas`), a profundidade e o total de produtos dos descendentes.
- Migration: `supabase/migrations/20261102120200_arvore_categorias_cte_recursiva.sql`. Definição exportada em `../../sql/views/analytics__vw_category_tree.sql`.

## Segurança

A tabela segue a regra das tabelas novas: RLS habilitado e sem grants para `anon` e `authenticated`.

## Estado

Testada no FrigusDB Dev: 22 nós, e a raiz soma os 258 produtos do catálogo. Ainda não aplicada no Prod; ver `../README.md`.
