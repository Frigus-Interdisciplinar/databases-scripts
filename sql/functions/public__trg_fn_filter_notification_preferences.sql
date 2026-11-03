CREATE OR REPLACE FUNCTION public.trg_fn_filter_notification_preferences()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
 IF EXISTS (SELECT 1 FROM user_preferences p WHERE p.user_id=NEW.recipient_user_id AND (
  (NEW.type::text='PRODUCT_NEAR_EXPIRATION' AND NOT p.expiration_alerts_enabled) OR
  (NEW.type::text IN ('LOW_STOCK','OUT_OF_STOCK') AND NOT p.low_stock_alerts_enabled) OR
  (NEW.type::text='SHOPPING_LIST_REMINDER' AND NOT p.shopping_reminders_enabled) OR
  (NEW.type::text='WEEKLY_SUMMARY' AND NOT p.weekly_summary_enabled)
 )) THEN RETURN NULL; END IF;
 RETURN NEW;
END $function$
