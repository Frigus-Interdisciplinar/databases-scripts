DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."discard";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON discard FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
