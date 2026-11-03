-- ponytail: discard não tem user_id, então não dá pra também gravar em stock_movements
-- sem inventar um usuário. Se quiser um ledger unificado, adicionar user_id em discard.
CREATE OR REPLACE FUNCTION trg_fn_discard_apply()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE stock_products
       SET quantity = 0
     WHERE id = NEW.stock_product_id;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_discard_apply ON discard;
CREATE TRIGGER trg_discard_apply
    AFTER INSERT ON discard
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_discard_apply();
