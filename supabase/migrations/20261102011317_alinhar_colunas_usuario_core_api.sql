ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS email_verified boolean NOT NULL DEFAULT true,
    ADD COLUMN IF NOT EXISTS plan_selection_required boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS pending_plan_transaction_id uuid;
