CREATE OR REPLACE FUNCTION public.fn_pair_key(p_user_a integer, p_user_b integer)
 RETURNS character varying
 LANGUAGE sql
 IMMUTABLE
AS $function$
    SELECT LEAST(p_user_a, p_user_b)::VARCHAR || '_' || GREATEST(p_user_a, p_user_b)::VARCHAR;
$function$
