DROP TRIGGER IF EXISTS "trg_notify_commercial_stock_level" ON "public"."stock_products";
CREATE TRIGGER trg_notify_commercial_stock_level AFTER INSERT OR UPDATE OF quantity, minimal_quantity ON stock_products FOR EACH ROW EXECUTE FUNCTION trg_fn_notify_commercial_stock_level();
