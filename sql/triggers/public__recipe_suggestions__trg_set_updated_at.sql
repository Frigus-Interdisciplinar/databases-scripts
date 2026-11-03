DROP TRIGGER IF EXISTS "trg_set_updated_at" ON "public"."recipe_suggestions";
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON recipe_suggestions FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
