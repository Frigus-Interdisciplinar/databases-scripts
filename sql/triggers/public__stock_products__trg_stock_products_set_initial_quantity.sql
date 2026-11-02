DROP TRIGGER IF EXISTS "trg_stock_products_set_initial_quantity" ON "public"."stock_products";
CREATE TRIGGER trg_stock_products_set_initial_quantity BEFORE INSERT ON stock_products FOR EACH ROW EXECUTE FUNCTION trg_fn_stock_products_set_initial_quantity();
