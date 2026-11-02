DROP TRIGGER IF EXISTS "trg_filter_notification_preferences" ON "public"."notifications";
CREATE TRIGGER trg_filter_notification_preferences BEFORE INSERT ON notifications FOR EACH ROW EXECUTE FUNCTION trg_fn_filter_notification_preferences();
