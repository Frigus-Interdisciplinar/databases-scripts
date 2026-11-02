CREATE OR REPLACE PROCEDURE public.sp_get_or_create_private_conversation(IN p_user_a uuid, IN p_user_b uuid, INOUT p_conversation_id uuid DEFAULT NULL::uuid)
 LANGUAGE plpgsql
AS $procedure$
DECLARE v_key varchar := fn_pair_key(p_user_a, p_user_b);
BEGIN
    IF p_user_a = p_user_b THEN RAISE EXCEPTION 'usuarios iguais'; END IF;
    SELECT id INTO p_conversation_id FROM conversations WHERE pair_key = v_key;
    IF p_conversation_id IS NULL THEN
        INSERT INTO conversations (conversation_type, pair_key) VALUES ('PRIVATE', v_key)
        RETURNING id INTO p_conversation_id;
        INSERT INTO conversation_participants (conversation_id, user_id)
        VALUES (p_conversation_id, p_user_a), (p_conversation_id, p_user_b);
    END IF;
END $procedure$
