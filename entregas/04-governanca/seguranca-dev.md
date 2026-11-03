# Observações de segurança — Dev e Prod

Verificações registradas em 2026-11-01; não substituem monitoramento contínuo.

## Acesso e RLS

- Nenhuma policy RLS nova foi criada nesta entrega. Em Prod havia 24 tabelas com RLS habilitado e uma policy em `audit.row_change_log`; tabelas com RLS e sem policy ficam inacessíveis a roles comuns quando RLS se aplica.
- `governance` é schema privado sem acesso concedido a `anon`, `authenticated` ou `service_role`. O catálogo exportado aqui é documentação; controlar também cópias e exports que possam conter metadados sensíveis.
- A Core API do Dev foi observada conectada como `postgres`, papel superusuário. Validação de rotas da aplicação não limita o impacto de vazamento dessa credencial.
- Em Prod foi criado `frigus_core_api` com `BYPASSRLS` e grants operacionais para a API. É um login sem atributos administrativos, mas `BYPASSRLS` significa que ignora as políticas RLS: proteger com segredo forte em secret manager, limitar rede, rotacionar credencial e usar somente do servidor. A API ainda precisa ser configurada e implantada para usar esse papel; não foi comprovado uso em produção.

## Advisors e dívida técnica observada no Dev

- Advisors apontaram 23 tabelas públicas com RLS e sem policies, 16 rotinas públicas com `search_path` mutável, 21 FKs sem índice cobridor e 24 índices sem uso observado.
- Os planos em `../03-objetos-e-otimizacao/explain-analyze-dev.md` mostram índices selecionados nas consultas verificadas. Uso observado curto não justifica remover índices automaticamente; revisar com métricas de workload.
- Views, funções `SECURITY DEFINER`, grants e políticas devem ser reavaliados quando a Core API mudar de papel. Não publicar credenciais em `.env`, exemplos ou logs.

O desenho atual confia na Core API para autorização de negócio. A segurança do banco ainda depende de grants mínimos e isolamento das credenciais, mesmo sem policies adicionais.
