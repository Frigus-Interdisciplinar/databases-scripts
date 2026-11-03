-- Remove public.users.senha.
-- A coluna guardava apenas o placeholder 'VAZIO' (DEFAULT) em todas as linhas e duplicava a função de hash_password.
-- Evidência em 2026-11-02 (Dev): nenhuma view, função, trigger ou índice depende dela; nenhuma consulta da Core API
-- (Hibernate) a lê ou escreve; o RPA e o dataload.sql não a informam. A credencial real é hash_password.
--
-- Para desfazer: ALTER TABLE public.users ADD COLUMN senha varchar DEFAULT 'VAZIO';
-- Antes de aplicar em outro ambiente, conferir em pg_stat_statements que nenhuma consulta cita "senha".

ALTER TABLE public.users DROP COLUMN IF EXISTS senha;

DELETE FROM governance.data_catalog
 WHERE object_schema = 'public' AND object_name = 'users' AND column_name = 'senha';
