DROP TRIGGER IF EXISTS "trg_conversation_participants_pair_key" ON "public"."conversation_participants";
CREATE TRIGGER trg_conversation_participants_pair_key AFTER INSERT ON conversation_participants FOR EACH ROW EXECUTE FUNCTION trg_fn_conversation_participants_pair_key();
