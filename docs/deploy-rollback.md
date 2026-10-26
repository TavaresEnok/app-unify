# Deploy e rollback

Atualizado em 2026-07-10 para a arquitetura modular.

## Pré-deploy

1. Executar `npm run validate`, `npm run validate:e2e` e `npm run test:rules`.
2. Confirmar `docker compose config` e registrar as imagens atuais com `docker compose images`.
3. Para alterações de dados, exportar o Firestore e executar a migração primeiro sem `--apply`.
4. Conferir secrets e variáveis usando `docs/contracts/env-vars.md` sem imprimir valores.
5. Confirmar Node 22 e Java 21 no ambiente de deploy/CI.

## Deploy Docker

```bash
docker compose build frontend api-service backend-proxy
docker compose up -d --no-deps frontend api-service backend-proxy
docker compose ps
curl --fail http://127.0.0.1:8031/
curl --fail http://127.0.0.1:8034/health
curl --fail http://127.0.0.1:8030/health
```

## Deploy Firebase

O novo router substitui os gatilhos antigos de `function_requests`. O primeiro deploy deve remover as Functions antigas somente depois de confirmar `handleFunctionRequest` ativo.

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

Ordem recomendada:

1. Deploy de regras e indices.
2. Deploy de Functions com `handleFunctionRequest`.
3. Criar um request de teste e confirmar `function_responses`.
4. Remover Functions antigas somente apos confirmar que nao ha gatilhos legados ativos.

## Rollback

- Docker: reconstruir a tag/commit anterior e executar `docker compose up -d --no-deps` nos serviços afetados.
- Functions e regras: fazer checkout do commit anterior e executar novamente o deploy Firebase.
- Dados: restaurar o export do Firestore ou os documentos em `migration_backups`; scripts de migração não devem ser revertidos por exclusão manual.

Após qualquer rollback, repetir os três healthchecks e os fluxos de login, dashboard, configuração, tickets e SGP.
