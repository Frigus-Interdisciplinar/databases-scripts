-- O comentário de users.hash_password (migration 20261102120500) dizia que a coluna "coexiste com senha".
-- A coluna senha foi removida na 20261102120800, então o texto foi corrigido.

COMMENT ON COLUMN public.users.hash_password IS 'Hash da senha usado pela Core API no login. Nulo em contas que não entram por senha (login Google e contas sintéticas da massa de dados).';

UPDATE governance.data_catalog
   SET description = col_description('public.users'::regclass, ordinal_position),
       metadata_updated_at = now()
 WHERE object_schema = 'public' AND object_name = 'users' AND column_name = 'hash_password';
