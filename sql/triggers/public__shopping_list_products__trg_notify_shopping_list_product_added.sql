DROP TRIGGER IF EXISTS "trg_notify_shopping_list_product_added" ON "public"."shopping_list_products";
CREATE TRIGGER trg_notify_shopping_list_product_added AFTER INSERT ON shopping_list_products FOR EACH ROW EXECUTE FUNCTION trg_fn_notify_shopping_list_product_added();
