DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."requests";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON requests FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
