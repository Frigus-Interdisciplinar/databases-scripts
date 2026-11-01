CREATE OR REPLACE PROCEDURE public.sp_get_or_create_private_conversation(IN p_user_a integer, IN p_user_b integer, INOUT p_conversation_id integer DEFAULT NULL::integer)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_pair_key VARCHAR;
BEGIN
    v_pair_key := fn_pair_key(p_user_a, p_user_b);

    SELECT id INTO p_conversation_id
    FROM conversations
    WHERE pair_key = v_pair_key;

    IF p_conversation_id IS NULL THEN
        INSERT INTO conversations (conversation_type)
        VALUES ('PRIVATE')
        RETURNING id INTO p_conversation_id;

        INSERT INTO conversation_participants (conversation_id, user_id)
        VALUES (p_conversation_id, p_user_a), (p_conversation_id, p_user_b);
        -- trg_conversation_participants_pair_key seta o pair_key após o 2º insert acima
    END IF;
END;
$procedure$
