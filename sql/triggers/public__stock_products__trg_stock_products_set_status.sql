DROP TRIGGER IF EXISTS "trg_stock_products_set_status" ON "public"."stock_products";
CREATE TRIGGER trg_stock_products_set_status BEFORE INSERT OR UPDATE OF expire_date ON stock_products FOR EACH ROW EXECUTE FUNCTION trg_fn_stock_products_set_status();
