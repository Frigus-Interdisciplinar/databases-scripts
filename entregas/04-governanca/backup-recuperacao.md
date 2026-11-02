# Backup e recuperacao — procedimento operacional

## Antes de mudancas

1. Confirmar o projeto e ambiente no Dashboard e validar duas vezes a referência antes de exportar ou restaurar. O bootstrap de Prod já foi executado; aplicar um restore exige um plano aprovado e janela de manutenção.
2. Verificar se o plano oferece backup diario e sua retencao em **Database > Backups**. Em planos que nao oferecem backup gerenciado, exportar regularmente para armazenamento externo cifrado.
3. Exportar o schema versionado e os dados antes de DDL/DML de risco. Exemplo com CLI 2.105.0: `supabase db dump --linked --schema public,analytics,audit,dw,governance --file backup-schema.sql`; para somente dados, usar `--data-only --use-copy --file backup-data.sql`. Não colocar senha/URL em histórico de shell ou repositório. Validar Storage separadamente.
4. Guardar os arquivos fora do repositorio e validar tamanho, data e checksum. Manter copia em conta/regiao separada conforme politica do projeto.

## Restauracao de backup gerenciado

1. Confirmar incidente, projeto, ponto de recuperacao e RPO aprovado.
2. Acessar **Database > Backups** ou **Point in Time** no Dashboard e selecionar o ponto anterior ao incidente. Restauracao deixa o projeto indisponivel durante o processo; comunicar janela de manutencao.
3. Aguardar conclusao e verificar schema, constraints, contagens e aplicacao Core API antes de reabrir trafego.
4. Recriar/configurar objetos externos ao backup. Supabase documenta que arquivos do Storage nao sao restaurados pelo backup do Postgres; validar objetos e configuracoes separadamente.

## Restauracao de dump logico

Restaurar primeiro em projeto/banco isolado usando cliente PostgreSQL (`psql` para SQL simples ou `pg_restore` para formato custom), conferir encoding, extensoes, roles e grants; depois validar constraints e contagens. Nunca restaurar por cima de producao sem plano de rollback e janela autorizada.

## Limites e referencia oficial

Backups gerenciados, retencao, PITR, indisponibilidade durante restore e exclusao dos objetos Storage sao descritos na [documentacao oficial de backups Supabase](https://supabase.com/docs/guides/platform/backups). O plano contratado define quais opcoes estao disponiveis. Este procedimento nao habilita PITR nem altera configuracao de billing.
