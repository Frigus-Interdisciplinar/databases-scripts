DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."subscriptions";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
