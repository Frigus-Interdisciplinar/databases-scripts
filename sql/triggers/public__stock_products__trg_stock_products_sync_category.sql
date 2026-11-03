CREATE TRIGGER trg_stock_products_sync_category BEFORE INSERT OR UPDATE OF category, product_id ON public.stock_products FOR EACH ROW EXECUTE FUNCTION trg_fn_stock_products_sync_category()
