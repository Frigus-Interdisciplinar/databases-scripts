CREATE OR REPLACE FUNCTION trg_fn_stock_products_set_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.product_status := fn_compute_product_status(NEW.expire_date);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stock_products_set_status ON stock_products;
CREATE TRIGGER trg_stock_products_set_status
    BEFORE INSERT OR UPDATE OF expire_date ON stock_products
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_stock_products_set_status();
