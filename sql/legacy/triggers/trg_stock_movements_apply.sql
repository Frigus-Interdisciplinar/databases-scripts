CREATE OR REPLACE FUNCTION trg_fn_stock_movements_apply()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_delta        INTEGER;
    v_new_quantity INTEGER;
BEGIN
    -- ponytail: 'Ajuste' usa o sinal de NEW.quantity direto (positivo soma, negativo subtrai).
    -- Se precisar de um tipo de ajuste explicitamente absoluto, separar em outra coluna/enum.
    v_delta := CASE NEW.movement_type
        WHEN 'Entrada' THEN NEW.quantity
        WHEN 'Saída'   THEN -NEW.quantity
        ELSE NEW.quantity
    END;

    UPDATE stock_products
       SET quantity = quantity + v_delta
     WHERE id = NEW.stock_product_id
     RETURNING quantity INTO v_new_quantity;

    IF v_new_quantity < 0 THEN
        RAISE EXCEPTION 'stock_movements: quantidade resultante negativa para stock_product_id %', NEW.stock_product_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stock_movements_apply ON stock_movements;
CREATE TRIGGER trg_stock_movements_apply
    AFTER INSERT ON stock_movements
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_stock_movements_apply();
