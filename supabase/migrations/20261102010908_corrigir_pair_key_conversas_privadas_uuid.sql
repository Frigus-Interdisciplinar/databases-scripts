CREATE OR REPLACE FUNCTION public.fn_pair_key(p_user_a uuid, p_user_b uuid)
RETURNS varchar
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = pg_catalog
AS $function$
    SELECT LEAST(p_user_a, p_user_b)::varchar || '_' || GREATEST(p_user_a, p_user_b)::varchar;
$function$;

CREATE OR REPLACE FUNCTION public.trg_fn_conversation_participants_pair_key()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $function$
DECLARE
    v_conversation_type public.conversation_type_enum;
    v_participants uuid[];
BEGIN
    SELECT c.conversation_type
      INTO v_conversation_type
      FROM public.conversations AS c
     WHERE c.id = NEW.conversation_id;

    IF v_conversation_type = 'PRIVATE' THEN
        SELECT array_agg(cp.user_id ORDER BY cp.user_id)
          INTO v_participants
          FROM public.conversation_participants AS cp
         WHERE cp.conversation_id = NEW.conversation_id;

        IF cardinality(v_participants) = 2 THEN
            UPDATE public.conversations
               SET pair_key = public.fn_pair_key(v_participants[1], v_participants[2])
             WHERE id = NEW.conversation_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$function$;
