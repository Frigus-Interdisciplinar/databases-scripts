DROP TRIGGER IF EXISTS "audit_stock_products_row_changes" ON "public"."stock_products";
CREATE TRIGGER audit_stock_products_row_changes AFTER INSERT OR DELETE OR UPDATE ON stock_products FOR EACH ROW EXECUTE FUNCTION audit.capture_row_change();
