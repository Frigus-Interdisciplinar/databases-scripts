DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."conversation_participants";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON conversation_participants FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
