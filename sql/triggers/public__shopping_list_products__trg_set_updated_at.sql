DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."shopping_list_products";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON shopping_list_products FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
