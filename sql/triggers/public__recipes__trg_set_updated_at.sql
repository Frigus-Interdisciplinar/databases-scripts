DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."recipes";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON recipes FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
