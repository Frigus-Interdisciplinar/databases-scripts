-- Corrige o separador de pair_key para '-'.
-- A migration 20261102010908 usava '_', mas as conversas privadas existentes e a Core API usam '-'.
-- Com '_', o mesmo par de usuários geraria outra chave e poderia duplicar a conversa.
-- Remove também a sobrecarga antiga com integer, que não é mais usada.

DROP FUNCTION IF EXISTS public.fn_pair_key(integer, integer);

CREATE OR REPLACE FUNCTION public.fn_pair_key(p_user_a uuid, p_user_b uuid)
RETURNS varchar
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = pg_catalog
AS $function$
    SELECT LEAST(p_user_a, p_user_b)::varchar || '-' || GREATEST(p_user_a, p_user_b)::varchar;
$function$;
