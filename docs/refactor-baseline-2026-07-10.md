# Baseline e Resultado da Refatoracao - 2026-07-10

Branch: `refactor/base-architecture`

Base original:

- `main` em `4e07baf Aplicar redesign do painel admin`
- Branch criada para refatoracao estrutural.

## Baseline inicial

Antes da refatoracao, os builds web/backend passavam, mas havia riscos
estruturais:

- contratos `function_requests` divergentes;
- handlers usados pelo front sem implementacao clara;
- `functions/src/index.ts` monolitico;
- `api-service/src/index.ts` monolitico;
- schema de `ProviderConfig` duplicado entre raiz/config/Flutter;
- acesso direto ao Firestore em muitas telas do painel;
- regras de Firestore/Storage sem testes automatizados;
- subapp Flutter com ajustes necessarios em diagnostico/config.

## Resultado atual

- Contratos compartilhados em `shared/contracts`.
- Admin panel com camada `shared/api`, services por dominio, normalizadores de
  config e smoke e2e.
- Functions modularizadas por dominio, com router unico e auditoria.
- API service modularizado por rotas/middlewares/services.
- Proxy SGP documentado como adaptador/cache legado.
- Flutter root e unified com normalizador de config e registry de layouts.
- Firestore/Storage rules com testes de emulador.
- CI criado para web/backend, Flutter e Docker build.
- Plano de deploy/rollback documentado.

## Validacoes executadas

- `npm run contracts:check`
- `npm run security:secrets`
- `npm run lint --prefix admin-painel`
- `npm run test --prefix admin-painel`
- `npm run build --prefix admin-painel`
- `npm run test:e2e --prefix admin-painel`
- `npm run build --prefix functions`
- `npm test --prefix functions -- --runInBand`
- `npm run test --prefix api-service`
- `npm run build --prefix api-service`
- `npm test --prefix proxy-sgp`
- `node --check proxy-sgp/index.js`
- `npm run test:rules` com Java 21
- `flutter analyze --no-fatal-infos --no-fatal-warnings && flutter test`
- mesmas validacoes Flutter em `app-flutter/unified`
- mesmas validacoes Flutter em `app-flutter/admin_app`

## Riscos residuais documentados

- `flutter analyze` ainda mostra warnings/infos legados, mas sem falhar porque
  o comando usa `--no-fatal-infos --no-fatal-warnings`.
- `npm audit --omit=dev` ainda aponta avisos moderados de cadeia Firebase Admin
  sem correcao sem downgrade/alteracao maior; nao ha critical/high restante nos
  pacotes de producao apos as atualizacoes aplicadas.
- O deploy de Firebase Functions/regras deve seguir `docs/deploy-rollback.md`,
  pois substitui gatilhos antigos por `handleFunctionRequest`.
