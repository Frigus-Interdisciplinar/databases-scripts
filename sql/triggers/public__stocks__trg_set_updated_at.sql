DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."stocks";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON stocks FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
