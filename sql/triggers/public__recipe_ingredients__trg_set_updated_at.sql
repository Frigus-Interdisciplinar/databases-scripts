DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."recipe_ingredients";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON recipe_ingredients FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
