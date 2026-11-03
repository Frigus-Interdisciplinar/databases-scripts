DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."message_attachments";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON message_attachments FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
