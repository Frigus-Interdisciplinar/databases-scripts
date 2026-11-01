DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."groups";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON groups FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
