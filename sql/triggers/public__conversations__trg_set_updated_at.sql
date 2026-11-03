DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."conversations";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON conversations FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
