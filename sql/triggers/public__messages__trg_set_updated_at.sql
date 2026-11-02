DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."messages";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON messages FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
