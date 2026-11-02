-- Configuracao aplicada em Frigus Prod durante o bootstrap.
-- As pastas sao criadas pelo upload de objetos nesses caminhos.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('products', 'products', false, 716800, ARRAY['image/png', 'image/jpeg', 'image/jpg']),
  ('profile-picture', 'profile-picture', true, 256000, ARRAY['image/png', 'image/jpeg', 'image/jpg'])
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;
