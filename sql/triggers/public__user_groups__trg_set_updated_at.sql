DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."user_groups";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON user_groups FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
