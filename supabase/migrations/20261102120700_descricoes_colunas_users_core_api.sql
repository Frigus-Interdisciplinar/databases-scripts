-- Descrições das colunas de public.users criadas pela migration 20261102011317 (alinhamento da Core API).
-- Estavam com texto genérico no catálogo.

COMMENT ON COLUMN public.users.plan_selection_required IS 'Indica se o usuário precisa escolher um plano antes de usar o app.';
COMMENT ON COLUMN public.users.pending_plan_transaction_id IS 'Transação de plano aguardando confirmação, se houver.';

UPDATE governance.data_catalog d
   SET description = col_description(to_regclass(format('%I.%I', d.object_schema, d.object_name)), d.ordinal_position),
       metadata_updated_at = now()
 WHERE d.column_name <> '__TABLE__'
   AND d.object_schema = 'public' AND d.object_name = 'users'
   AND d.column_name IN ('plan_selection_required', 'pending_plan_transaction_id');
