CREATE OR REPLACE FUNCTION fn_pair_key(p_user_a INTEGER, p_user_b INTEGER)
RETURNS VARCHAR
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT LEAST(p_user_a, p_user_b)::VARCHAR || '_' || GREATEST(p_user_a, p_user_b)::VARCHAR;
$$;
