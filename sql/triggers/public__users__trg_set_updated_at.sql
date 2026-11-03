DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."users";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
