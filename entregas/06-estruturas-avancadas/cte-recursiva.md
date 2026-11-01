# CTE recursiva e heranca de tabelas

O dominio atual nao apresenta hierarquia pai/filho persistida que justifique CTE recursiva. Grupos, usuarios e estoques se relacionam por titularidade e associacoes; interpretar essas associacoes como arvore criaria semantica incorreta. Heranca PostgreSQL tambem nao agrega valor ao modelo atual.

A decisao e documentar o item como **nao aplicavel ao dominio atual**. CTEs nao recursivas e Window Functions ja aparecem nas views analiticas. Se o produto introduzir taxonomia real (por exemplo, categorias com `parent_category_id`), a CTE recursiva passa a ter caso de uso claro.
