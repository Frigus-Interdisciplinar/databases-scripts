DROP TRIGGER IF EXISTS "audit_products_row_changes" ON "public"."products";
CREATE TRIGGER audit_products_row_changes AFTER INSERT OR DELETE OR UPDATE ON products FOR EACH ROW EXECUTE FUNCTION audit.capture_row_change();
