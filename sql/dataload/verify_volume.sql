SELECT 'groups' AS table_name, COUNT(*) AS row_count FROM public.groups
UNION ALL SELECT 'users', COUNT(*) FROM public.users
UNION ALL SELECT 'user_groups', COUNT(*) FROM public.user_groups
UNION ALL SELECT 'stocks', COUNT(*) FROM public.stocks
UNION ALL SELECT 'products', COUNT(*) FROM public.products
UNION ALL SELECT 'stock_products', COUNT(*) FROM public.stock_products
UNION ALL SELECT 'recipes', COUNT(*) FROM public.recipes
UNION ALL SELECT 'recipe_ingredients', COUNT(*) FROM public.recipe_ingredients
UNION ALL SELECT 'recipe_suggestions', COUNT(*) FROM public.recipe_suggestions
UNION ALL SELECT 'shopping_lists', COUNT(*) FROM public.shopping_lists
UNION ALL SELECT 'shopping_list_products', COUNT(*) FROM public.shopping_list_products
UNION ALL SELECT 'stock_movements', COUNT(*) FROM public.stock_movements
UNION ALL SELECT 'messages', COUNT(*) FROM public.messages
UNION ALL SELECT 'transactions', COUNT(*) FROM public.transactions
ORDER BY table_name;

DO $$
DECLARE
    generated_rows bigint;
BEGIN
    SELECT SUM(row_count)
      INTO generated_rows
      FROM (
          SELECT COUNT(*) AS row_count FROM public.groups
          UNION ALL SELECT COUNT(*) FROM public.users
          UNION ALL SELECT COUNT(*) FROM public.user_groups
          UNION ALL SELECT COUNT(*) FROM public.stocks
          UNION ALL SELECT COUNT(*) FROM public.products
          UNION ALL SELECT COUNT(*) FROM public.stock_products
          UNION ALL SELECT COUNT(*) FROM public.recipes
          UNION ALL SELECT COUNT(*) FROM public.recipe_ingredients
          UNION ALL SELECT COUNT(*) FROM public.recipe_suggestions
          UNION ALL SELECT COUNT(*) FROM public.shopping_lists
          UNION ALL SELECT COUNT(*) FROM public.shopping_list_products
          UNION ALL SELECT COUNT(*) FROM public.stock_movements
          UNION ALL SELECT COUNT(*) FROM public.messages
          UNION ALL SELECT COUNT(*) FROM public.transactions
      ) AS counts;

    IF generated_rows < 500 THEN
        RAISE EXCEPTION 'Volume check failed: % rows found, expected at least 500', generated_rows;
    END IF;

    RAISE NOTICE 'Volume check passed: % rows across the selected tables', generated_rows;
END;
$$;
