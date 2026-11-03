-- Reflete no catalogo o modelo de acesso efetivamente observado no Dev.
UPDATE governance.data_catalog
SET access_level = CASE
        WHEN object_schema = 'governance' THEN 'Restrito: proprietario do banco; schema sem USAGE para roles da Data API'
        WHEN object_schema = 'audit' THEN 'Restrito: Core API/banco; trilha de auditoria; sem grants da Data API'
        WHEN object_schema IN ('dw', 'analytics') THEN 'Interno: acesso somente por roles explicitamente concedidos; sem acesso anon/authenticated no Data API'
        WHEN object_schema = 'public' THEN 'Core API; conexao observada como postgres (superuser), que pode contornar grants/RLS; nunca cliente direto'
        ELSE access_level
    END,
    metadata_updated_at = now()
WHERE object_schema IN ('public', 'analytics', 'audit', 'dw', 'governance');
