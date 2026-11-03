DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."plans";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON plans FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
