DROP TRIGGER IF EXISTS "trg_log_transaction_status_change" ON "public"."transactions";
CREATE TRIGGER trg_log_transaction_status_change AFTER INSERT OR UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION fn_log_transaction_status_change();
