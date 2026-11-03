-- stock_products.category repete products.category (dependência transitiva via product_id).
-- A Core API lê e grava essa coluna (insert/update com "category" e leituras sp1_0.category), então ela não pode ser
-- removida sem mudar o backend. Até lá, o banco garante que as duas nunca divergem:
--   1. ao inserir ou alterar um item de estoque, category é sempre copiada de products;
--   2. ao alterar products.category, a mudança é propagada para os itens de estoque.
-- Para remover a coluna depois: retirar o mapeamento da Core API, o INSERT do RPA e da procedure
-- sp_purchase_shopping_list_item, e então DROP COLUMN (os triggers abaixo caem junto ou podem ser removidos).

CREATE OR REPLACE FUNCTION public.trg_fn_stock_products_sync_category()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $function$
DECLARE
    v_category public.category_enum;
BEGIN
    SELECT p.category INTO v_category FROM public.products AS p WHERE p.id = NEW.product_id;
    IF FOUND THEN
        NEW.category := v_category;
    END IF;
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_stock_products_sync_category ON public.stock_products;
CREATE TRIGGER trg_stock_products_sync_category
    BEFORE INSERT OR UPDATE OF category, product_id ON public.stock_products
    FOR EACH ROW EXECUTE FUNCTION public.trg_fn_stock_products_sync_category();

CREATE OR REPLACE FUNCTION public.trg_fn_products_propagate_category()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $function$
BEGIN
    UPDATE public.stock_products SET category = NEW.category WHERE product_id = NEW.id;
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_products_propagate_category ON public.products;
CREATE TRIGGER trg_products_propagate_category
    AFTER UPDATE OF category ON public.products
    FOR EACH ROW
    WHEN (OLD.category IS DISTINCT FROM NEW.category)
    EXECUTE FUNCTION public.trg_fn_products_propagate_category();

COMMENT ON COLUMN public.stock_products.category IS 'Cópia de products.category mantida por trigger, por compatibilidade com a Core API. Não é fonte da categoria; o valor gravado diretamente é sobrescrito.';

UPDATE governance.data_catalog
   SET description = col_description('public.stock_products'::regclass, ordinal_position),
       metadata_updated_at = now()
 WHERE object_schema = 'public' AND object_name = 'stock_products' AND column_name = 'category';
