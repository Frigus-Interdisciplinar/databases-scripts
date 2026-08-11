CREATE OR REPLACE FUNCTION trg_fn_conversation_participants_pair_key()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_conversation_type conversation_type_enum;
    v_participants       INTEGER[];
BEGIN
    SELECT conversation_type INTO v_conversation_type
    FROM conversations
    WHERE id = NEW.conversation_id;

    IF v_conversation_type = 'Privada' THEN
        SELECT array_agg(user_id ORDER BY user_id) INTO v_participants
        FROM conversation_participants
        WHERE conversation_id = NEW.conversation_id;

        IF array_length(v_participants, 1) = 2 THEN
            UPDATE conversations
               SET pair_key = fn_pair_key(v_participants[1], v_participants[2])
             WHERE id = NEW.conversation_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_conversation_participants_pair_key ON conversation_participants;
CREATE TRIGGER trg_conversation_participants_pair_key
    AFTER INSERT ON conversation_participants
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_conversation_participants_pair_key();
