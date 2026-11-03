CREATE OR REPLACE FUNCTION public.trg_fn_conversation_participants_pair_key()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_conversation_type conversation_type_enum;
    v_participants       INTEGER[];
BEGIN
    SELECT conversation_type INTO v_conversation_type
    FROM conversations
    WHERE id = NEW.conversation_id;

    IF v_conversation_type = 'PRIVATE' THEN
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
$function$
