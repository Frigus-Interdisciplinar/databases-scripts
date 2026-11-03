CREATE OR REPLACE FUNCTION public.fn_pair_key(p_user_a uuid, p_user_b uuid)
 RETURNS character varying
 LANGUAGE sql
 IMMUTABLE
AS $function$
    SELECT LEAST(p_user_a, p_user_b)::text || '-' || GREATEST(p_user_a, p_user_b)::text;
$function$
