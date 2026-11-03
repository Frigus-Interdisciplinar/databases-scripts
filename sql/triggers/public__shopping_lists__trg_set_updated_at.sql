DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."shopping_lists";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON shopping_lists FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
