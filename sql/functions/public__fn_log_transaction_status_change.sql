CREATE OR REPLACE FUNCTION public.fn_log_transaction_status_change()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF TG_OP = 'INSERT' OR NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO transaction_events (transaction_id, status, message)
        VALUES (NEW.id, NEW.status, NULL);
    END IF;
    RETURN NEW;
END;
$function$
