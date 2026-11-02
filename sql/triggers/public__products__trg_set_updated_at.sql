DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."products";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
