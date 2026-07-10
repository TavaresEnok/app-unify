# Plano de Refatoracao Completa do Sistema Unify

Gerado em: 2026-07-10

Este documento deve ser usado como roteiro de continuidade para uma refatoracao completa, incremental e segura do sistema. A meta nao e "reescrever tudo", e sim reorganizar a arquitetura, reduzir duplicacao, tipar contratos, aumentar previsibilidade e permitir evolucao sem quebrar funcionalidades existentes.

Status de execucao em 2026-07-10: plano executado de ponta a ponta na branch
`refactor/base-architecture`. O resultado final e descrito em
`docs/refactor-completion-2026-07-10.md`; a arquitetura final esta em
`docs/architecture.md`.

## 1. Objetivo

Refatorar o sistema completo mantendo compatibilidade funcional com:

- Painel administrativo React/Vite (`admin-painel`).
- App Flutter white-label (`lib/`).
- Firebase Functions (`functions`).
- API service Express (`api-service`).
- Proxy SGP/cache (`proxy-sgp`).
- APK builder, landing page, speed test e infraestrutura Docker.

O resultado esperado e um sistema mais modular, testavel e seguro, com contratos claros entre front-end, back-end, Firebase, SGP e app mobile.

## 2. Principios obrigatorios

1. Preservar comportamento antes de reorganizar codigo.
2. Refatorar em etapas pequenas, com build/teste a cada etapa.
3. Evitar big bang: nenhuma fase deve exigir trocar front, backend e app ao mesmo tempo.
4. Manter compatibilidade com dados existentes no Firestore.
5. Separar mudanca estrutural de mudanca visual ou funcional.
6. Documentar contratos antes de alterar endpoints, collections ou payloads.
7. Nunca remover campo, rota, handler ou tela sem confirmar uso real.
8. Toda refatoracao deve ter criterio de aceite objetivo.

## 3. Estado atual identificado

### 3.1 Front-end administrativo

Stack:

- React 18.
- Vite.
- TypeScript com `strict: false` em `admin-painel/tsconfig.app.json`.
- Tailwind.
- Radix UI/lucide.
- Firebase client SDK.
- Rotas em `admin-painel/src/App.tsx`.

Pontos relevantes:

- O painel mistura chamadas diretas ao Firestore, `function_requests`, callable Functions e API REST.
- `useApi` centraliza parte das chamadas por `function_requests`, mas varias paginas ainda implementam o mesmo padrao manualmente.
- `SettingsContext` salva configuracoes diretamente no Firestore e tambem separa dados sensiveis em `provedores/{id}/secrets/sgp`.
- Tipos de `ProviderConfig` existem em `admin-painel/src/lib/types/provider-config.ts`, mas ainda ha muito `any` e compatibilidade legacy.
- O redesign recente criou componentes reaproveitaveis como `DataTable`, `StatusBadge` e `components/settings/SettingsPage.tsx`.

### 3.2 Firebase Functions

Stack:

- Node 22.
- TypeScript strict.
- Firebase Functions v2.
- Handlers acionados por documentos em `function_requests/{requestId}` e respondendo em `function_responses/{requestId}`.

Pontos relevantes:

- `functions/src/index.ts` concentra muitos handlers em um unico arquivo.
- Existem helpers locais para permissao, resposta e sanitizacao, mas ainda nao ha separacao clara por dominio.
- Tipos de request usados pelo front precisam ser auditados contra handlers reais no backend.
- Ha modelos em `functions/src/models/*`, mas os contratos ainda nao parecem ser compartilhados com o front.

### 3.3 API service

Stack:

- Express.
- TypeScript strict.
- Firebase Admin.
- Axios.
- Rate limiting.

Responsabilidades atuais:

- Login admin via Firebase Identity Toolkit.
- Endpoints admin para provedores, tickets, usuarios e dashboard.
- Proxy/normalizacao de chamadas SGP.
- Diagnosticos de ONU/traceroute.
- Geracao de APK via endpoint protegido.

Pontos relevantes:

- `api-service/src/index.ts` concentra rotas, middlewares, clientes externos e regras de negocio.
- O service tem preocupacoes misturadas: admin REST, SGP, diagnostico, APK e auth.
- Ha endpoints com nomes duplicados/parecidos entre `api-service` e `proxy-sgp`.

### 3.4 Proxy SGP/cache

Stack:

- Node/Express em `proxy-sgp/index.js`.
- Postgres e Redis via Docker.
- Scripts auxiliares e possivel legado Python/PHP.

Responsabilidades atuais:

- Cache/sync de clientes SGP.
- Login/consulta por CPF.
- Consumo, faturas, desbloqueio, CPE/Wi-Fi, diagnostico ONU e build APK legado.

Pontos relevantes:

- Ha sobreposicao com `api-service`.
- Deve ser tratado como legado critico ate existir contrato claro de migracao.

### 3.5 App Flutter

Stack:

- Flutter >= 3.4.
- Riverpod.
- Firebase Auth/Firestore/Storage/Messaging/Analytics/Crashlytics.
- Layouts white-label em `lib/layouts/layout_02` ate `layout_06`.
- Servicos em `lib/core/services`.

Pontos relevantes:

- O app depende de configuracoes remotas do provedor.
- Layouts, textos, cores, menus e features precisam continuar compativeis com o painel.
- Qualquer mudanca no schema de `ProviderConfig` deve ser backwards compatible.

### 3.6 Infraestrutura

Stack:

- `docker-compose.yml` com Caddy, frontend, api-service, proxy-sgp, postgres, redis, landing, speed-test e apk-builder.
- Frontend publicado na porta `8031`.
- API service na porta `8034`.
- APK builder na porta `8035`.
- Proxy SGP na porta `8030`.

Pontos relevantes:

- Build do painel gera `admin-painel/dist_final`.
- `dist_final`, `api-service/dist` e `venv` devem ser tratados como artefatos, nao como codigo fonte.
- Antes da refatoracao, limpar rastreamento Git desses artefatos se ainda estiverem versionados.

## 4. Riscos principais

### Risco 1: contratos de `function_requests` incompletos ou divergentes

O front declara/usa tipos como:

- `CREATE_PROVIDER`
- `CREATE_ADMIN_USER`
- `SET_SUPER_ADMIN_BY_EMAIL`
- `CREATE_TICKET`
- `REPLY_TO_TICKET`
- `UPDATE_TICKET_STATUS`
- `LIST_PROVIDER_CLIENTS`
- `DELETE_CLIENT`
- `GET_CLIENT_DETAILS`
- `BACKUP_PROVIDER_CONFIG`
- `LIST_PROVIDER_BACKUPS`
- `RESTORE_PROVIDER_CONFIG`
- `DELETE_PROVIDER_BACKUP`

Nem todos aparecem claramente como handlers em `functions/src/index.ts` na auditoria inicial. Antes de qualquer refatoracao estrutural, confirmar se esses fluxos estao ativos por outro caminho, quebrados, legados ou pendentes.

### Risco 2: schema de provedor duplicado

Hoje ha leitura/escrita em campos de raiz e tambem em `config`. Algumas Functions fazem espelhamento. O app Flutter e o painel podem depender de formatos diferentes.

Mitigacao:

- Criar schema canonico.
- Manter leitura legacy.
- Fazer escrita compativel por fase.
- Migrar dados apenas apos testes.

### Risco 3: front-end acoplado ao Firestore

Varias paginas acessam collections diretamente. Isso dificulta permissao, teste e evolucao.

Mitigacao:

- Criar camada `services/` ou `api/` no painel.
- Mover queries e mutations para modulos por dominio.
- Manter componentes focados em UI/estado de tela.

### Risco 4: responsabilidades duplicadas entre `api-service` e `proxy-sgp`

Ha endpoints SGP em ambos. Migrar sem contrato pode quebrar app, painel ou diagnosticos.

Mitigacao:

- Inventariar todos os consumidores.
- Congelar API publica atual.
- Criar facade unica antes de remover legado.

### Risco 5: ausencia de testes front-end

O painel nao possui pipeline claro de unit/e2e. Refatorar sem testes aumenta chance de regressao visual e funcional.

Mitigacao:

- Criar smoke tests minimos antes da refatoracao.
- Validar rotas criticas com Playwright ou equivalente.
- Criar testes unitarios para helpers e services.

## 5. Fase 0 - Preparacao e seguranca

Objetivo: deixar o repositorio e o ambiente prontos para refatorar sem risco operacional.

Tarefas:

1. Criar branch dedicada: `refactor/base-architecture`.
2. Confirmar que `main` esta atualizado.
3. Garantir backup do Firestore antes de qualquer migracao de dados.
4. Registrar status dos containers atuais.
5. Registrar URLs e portas ativas.
6. Limpar rastreamento de artefatos gerados:
   - `admin-painel/dist_final/`
   - `api-service/dist/`
   - `proxy-sgp/venv/`
   - `deploy_pid`
   - arquivos soltos como `Failed`, `Get`, `Run`, se forem apenas residuos.
7. Garantir `.gitignore` cobrindo build, cache, venv e secrets.

Comandos-base:

```bash
git status --short --branch
git pull --ff-only origin main
npm run build --prefix admin-painel
npm run build --prefix functions
npm test --prefix functions
npm run build --prefix api-service
flutter analyze
flutter test
docker compose ps
```

Criterios de aceite:

- Branch criada.
- Status Git sem artefatos gerados rastreados indevidamente.
- Builds atuais documentados.
- Falhas existentes registradas antes de qualquer mudanca.

## 6. Fase 1 - Inventario de contratos

Objetivo: criar uma fotografia completa dos contratos atuais.

Entregaveis:

1. `docs/contracts/function-requests.md`
2. `docs/contracts/firestore-schema.md`
3. `docs/contracts/rest-api.md`
4. `docs/contracts/provider-config.md`
5. `docs/contracts/env-vars.md`

Conteudo minimo por contrato:

- Nome do contrato.
- Quem chama.
- Quem responde.
- Payload esperado.
- Resposta esperada.
- Permissoes/claims.
- Collections afetadas.
- Campos obrigatorios.
- Campos legacy.
- Erros conhecidos.
- Teste de validacao.

Inventario inicial de collections:

- `provedores`
- `provedores/{providerId}/secrets/sgp`
- `provedores/{providerId}/clientes`
- `provedores/{providerId}/users`
- `provedores/{providerId}/diagnostic_results`
- `tickets`
- `tickets/{ticketId}/messages`
- `users`
- `clientes`
- `notifications`
- `function_requests`
- `function_responses`

Criterios de aceite:

- Todos os tipos usados pelo front possuem classificacao: ativo, legado, ausente ou substituido.
- Nenhuma refatoracao remove contrato sem alternativa documentada.
- Existe mapa claro de campos sensiveis.

## 7. Fase 2 - Baseline de testes

Objetivo: criar protecoes antes de mover codigo.

Front-end:

- Adicionar testes unitarios para helpers puros.
- Adicionar smoke tests para rotas principais:
  - `/login`
  - `/dashboard`
  - `/provedores`
  - `/provedores/:providerId/appearance`
  - `/provedor/dashboard`
  - `/provedor/clientes`
  - `/provedor/tickets`
- Validar que o bundle carrega assets com `base: "./"`.

Functions:

- Cobrir helpers de permissao.
- Cobrir formato padrao de resposta.
- Cobrir handlers principais com mocks.
- Garantir timeout/erro quando `function_responses` nao chega.

API service:

- Testes unitarios de middlewares de auth.
- Testes de validacao de traceroute.
- Testes de normalizacao SGP.
- Testes de erro padronizado.

Flutter:

- `flutter analyze`.
- Testes unitarios para parsing de config.
- Testes de widgets simples para layouts ativos.

Criterios de aceite:

- Existe comando unico ou documentado para rodar validacoes por camada.
- Refatoracoes futuras precisam passar por esses checks.

## 8. Fase 3 - Contratos compartilhados e tipagem

Objetivo: reduzir `any`, duplicacao de interfaces e divergencias entre front, Functions e API.

Tarefas:

1. Criar um pacote/pasta de contratos compartilhados, por exemplo:
   - `shared/contracts`
   - ou `packages/contracts`
2. Definir tipos canonicos:
   - `ProviderConfig`
   - `FunctionRequestType`
   - `FunctionRequestPayloadMap`
   - `FunctionResponse`
   - `UserClaims`
   - `Ticket`
   - `Provider`
   - `Client`
   - `Notification`
3. Criar validadores runtime para payloads criticos.
4. Migrar primeiro o front para consumir os tipos.
5. Depois migrar Functions/API service.

Regras:

- Tipo compartilhado nao deve importar React, Firebase client ou Firebase admin.
- Validadores devem retornar mensagens de erro previsiveis.
- Campos legacy devem ficar marcados como deprecated, nao removidos.

Criterios de aceite:

- `useApi` deixa de aceitar payload generico sem tipagem.
- `ProviderConfig` vira fonte de verdade no painel.
- Functions usam os mesmos nomes de request do front.

## 9. Fase 4 - Refatoracao do front-end admin

Objetivo: separar UI, estado, dados e contratos.

### 9.1 Estrutura proposta

```text
admin-painel/src/
  app/
    routes.tsx
    providers.tsx
  features/
    auth/
    dashboard/
    providers/
    tickets/
    users/
    provider-settings/
    provider-clients/
    notifications/
  shared/
    api/
    firebase/
    components/
    hooks/
    layout/
    types/
    utils/
  design-system/
    components/
    tokens/
```

### 9.2 Ordem de migracao

1. Criar `shared/api/functionRequests.ts`.
2. Migrar `useApi` para camada de infraestrutura com timeout, cleanup e tipagem.
3. Criar services por dominio:
   - `providerService`
   - `settingsService`
   - `ticketService`
   - `userService`
   - `clientService`
   - `notificationService`
4. Mover queries diretas do Firestore para services.
5. Deixar paginas apenas coordenando UI, loading, erro e eventos.
6. Extrair formularios repetidos em componentes controlados.
7. Centralizar rotas e menu em uma unica fonte.
8. Revisar telas legacy nao conectadas ao menu:
   - `ForceUpdate.tsx`
   - `TermsOfUseSettings.tsx`
   - `SettingsAppBuild.tsx`
   - `LandingPage.tsx`

### 9.3 Design system

Manter e evoluir:

- `DataTable`
- `StatusBadge`
- `StatsCard`
- `SettingsPage`
- componentes `ui/*`

Criar:

- `PageHeader`
- `SectionHeader`
- `Toolbar`
- `ConfirmDialog`
- `FormField`
- `ColorField`
- `EmptyState` unico
- `LoadingState` unico
- `ErrorState` unico

Criterios de aceite:

- Nenhuma pagina nova acessa Firestore diretamente fora de services.
- Rotas e menu usam configuracao unica.
- Componentes visuais nao conhecem Firebase.
- Build do painel continua passando.

## 10. Fase 5 - Refatoracao das configuracoes do provedor

Objetivo: tornar `provider-settings` previsivel e facil de manter.

Tarefas:

1. Criar `provider-settings/schema.ts` com todos os campos configuraveis.
2. Criar `provider-settings/defaults.ts`.
3. Criar `provider-settings/normalizers.ts`:
   - `normalizeProviderConfig`
   - `toFirestoreProviderConfig`
   - `fromFirestoreProviderConfig`
4. Criar `provider-settings/useProviderSettings.ts`.
5. Migrar cada subpagina para usar o mesmo contrato:
   - Aparencia
   - Tipografia
   - Icones/imagens
   - Menus
   - Dashboard
   - Carrossel
   - Promocoes
   - Notificacoes
   - Dicas
   - FAQ
   - Mensagens
   - Textos
   - Modulos/features
   - Integracoes
   - Suporte
   - Social
   - Outros
   - Backup
   - Gerar app
6. Remover duplicacao de defaults entre `SettingsContext`, Functions e Flutter somente apos manter compatibilidade.

Criterios de aceite:

- Uma config vazia sempre renderiza sem tela quebrada.
- Salvar uma subpagina nao apaga campos de outras subpaginas.
- Dados sensiveis continuam fora do documento publico.
- App Flutter continua lendo configuracoes antigas e novas.

## 11. Fase 6 - Refatoracao das Firebase Functions

Objetivo: dividir `functions/src/index.ts` por dominio e padronizar request/response.

### 11.1 Estrutura proposta

```text
functions/src/
  index.ts
  app/
    requestRouter.ts
    writeResponse.ts
    permissions.ts
    errors.ts
  handlers/
    providers/
    users/
    dashboard/
    tickets/
    notifications/
    sgp/
    backups/
    clients/
  models/
  validators/
  tests/
```

### 11.2 Ordem de migracao

1. Extrair helpers puros sem mudar comportamento.
2. Criar router central para `function_requests`.
3. Registrar handlers por tipo.
4. Migrar um dominio por vez.
5. Adicionar testes por handler.
6. Confirmar handlers ausentes ou legacy.
7. Padronizar erros com codigos:
   - `unauthenticated`
   - `permission-denied`
   - `invalid-argument`
   - `not-found`
   - `internal`
8. Adicionar logs estruturados com `requestId`, `type`, `providerId`, `requesterUid`.

Criterios de aceite:

- Cada tipo de request tem exatamente um handler registrado ou esta marcado como legacy.
- `function_responses` sempre recebe `completedAt`.
- Erros sao previsiveis e exibiveis no front.
- `npm run build --prefix functions` e `npm test --prefix functions` passam.

## 12. Fase 7 - Refatoracao do API service

Objetivo: separar rotas, middlewares, services e clientes externos.

Estrutura proposta:

```text
api-service/src/
  index.ts
  server.ts
  config/
  middlewares/
    auth.ts
    cors.ts
    rateLimit.ts
    errorHandler.ts
  routes/
    adminAuth.routes.ts
    providers.routes.ts
    tickets.routes.ts
    users.routes.ts
    dashboard.routes.ts
    sgp.routes.ts
    diagnostics.routes.ts
    apk.routes.ts
  services/
    firebaseAdmin.ts
    sgpClient.ts
    providerService.ts
    ticketService.ts
    apkService.ts
    diagnosticsService.ts
  validators/
  types/
```

Tarefas:

1. Extrair config/env e validar na inicializacao.
2. Extrair middlewares de auth.
3. Extrair rate limits por dominio.
4. Criar `sgpClient` unico.
5. Padronizar resposta de erro.
6. Documentar endpoints.
7. Remover duplicacao apenas apos mapear consumidores.

Criterios de aceite:

- `api-service/src/index.ts` fica pequeno e apenas monta o servidor.
- Endpoints existentes continuam respondendo.
- Build passa.
- Healthcheck continua funcionando.

## 13. Fase 8 - Estrategia para `proxy-sgp`

Objetivo: decidir se `proxy-sgp` sera mantido, reduzido ou absorvido pelo `api-service`.

Etapas:

1. Inventariar endpoints usados por:
   - App Flutter.
   - Functions.
   - Painel.
   - scripts.
2. Classificar cada endpoint:
   - manter no proxy
   - migrar para api-service
   - remover por nao uso
   - manter como compatibilidade temporaria
3. Criar testes de contrato para endpoints SGP.
4. Se migrar, criar compatibilidade de rota por pelo menos uma versao.
5. Remover codigo legado somente apos logs confirmarem ausencia de uso.

Criterios de aceite:

- Nao ha endpoint SGP removido sem substituto.
- Cache e rate limit continuam funcionando.
- Login/CPF, faturas, consumo, desbloqueio, ONU e Wi-Fi continuam operacionais.

## 14. Fase 9 - Refatoracao do app Flutter

Objetivo: alinhar o app ao contrato canonico de configuracao sem quebrar white-labels existentes.

Tarefas:

1. Criar modelos tipados para config remota:
   - `ProviderConfig`
   - `ThemeConfig`
   - `MenuConfig`
   - `FeatureConfig`
   - `SupportConfig`
2. Criar normalizador Dart equivalente ao front:
   - defaults
   - leitura legacy
   - fallback de cores/textos
3. Centralizar registry de layouts.
4. Padronizar services externos:
   - financeiro
   - consumo
   - suporte
   - diagnostico
   - notificacoes
5. Revisar dependencias diretas de Firestore em paginas.
6. Adicionar testes para parsing e fallback.

Criterios de aceite:

- App abre com config antiga e nova.
- Layout selecionado continua respeitado.
- Menus personalizados continuam funcionando.
- Features desligadas nao aparecem no app.
- `flutter analyze` e `flutter test` passam ou falhas conhecidas ficam documentadas.

## 15. Fase 10 - Firestore, regras e dados

Objetivo: estabilizar modelo de dados e permissao.

Tarefas:

1. Documentar schema real das collections.
2. Definir campos publicos vs sensiveis.
3. Revisar regras de Firestore/Storage.
4. Criar scripts de migracao idempotentes.
5. Criar backups antes de migracoes.
6. Criar validadores de dados.
7. Criar plano para reduzir duplicacao `root` vs `config`.

Regras de migracao:

- Nunca migrar sem backup.
- Script deve poder rodar duas vezes sem dano.
- Primeiro adicionar campos novos, depois atualizar leitores, depois remover legado em fase futura.

Criterios de aceite:

- Schema documentado.
- Regras cobrem superAdmin, providerAdmin e cliente.
- Dados sensiveis nao vazam no documento publico.

## 16. Fase 11 - CI/CD e qualidade

Objetivo: automatizar validacoes essenciais.

Pipeline minimo:

```bash
npm run build --prefix admin-painel
npm run build --prefix functions
npm test --prefix functions
npm run build --prefix api-service
flutter analyze
flutter test
git diff --check
```

Melhorias recomendadas:

- ESLint no painel.
- Prettier ou formatter padronizado.
- Playwright para smoke tests.
- Coverage minimo para Functions/services.
- Checagem de secrets.
- Build Docker em ambiente limpo.

Criterios de aceite:

- Pull request nao entra sem build.
- Testes de contrato rodam antes de deploy.
- Deploy tem rollback claro.

## 17. Fase 12 - Observabilidade e seguranca

Objetivo: facilitar diagnostico e reduzir risco operacional.

Tarefas:

1. Logs estruturados por request.
2. Correlation id para `function_requests`.
3. Auditoria de acoes administrativas:
   - criar provedor
   - alterar configuracao
   - excluir provedor
   - enviar notificacao
   - gerar APK
4. Validacao central de claims.
5. Revisao de CORS.
6. Revisao de rate limits.
7. Garantir que secrets nao entram em logs.

Criterios de aceite:

- Cada erro operacional tem log suficiente para investigar.
- Acoes criticas deixam trilha de auditoria.
- Nenhum token/senha/API key aparece em log ou documento publico.

## 18. Ordem recomendada de execucao

### Marco 0 - Higiene e baseline

Prioridade: maxima.

Entregas:

- Repositorio limpo.
- Builds atuais registrados.
- Artefatos removidos do versionamento, se aplicavel.
- Plano de rollback.

### Marco 1 - Contratos e testes minimos

Prioridade: maxima.

Entregas:

- Inventario de Function Requests.
- Inventario REST.
- Inventario Firestore.
- Smoke tests minimos.

### Marco 2 - Camada de API do painel

Prioridade: alta.

Entregas:

- `useApi` tipado e robusto.
- Services por dominio.
- Paginas sem chamadas duplicadas ao Firestore quando possivel.

### Marco 3 - Configuracoes do provedor

Prioridade: alta.

Entregas:

- Schema canonico.
- Normalizadores.
- Subpaginas padronizadas.
- Compatibilidade com app Flutter.

### Marco 4 - Functions modularizadas

Prioridade: alta.

Entregas:

- Router de requests.
- Handlers por dominio.
- Testes por handler.
- Erros padronizados.

### Marco 5 - API service modularizado

Prioridade: media/alta.

Entregas:

- Rotas separadas.
- Services.
- Middlewares.
- Cliente SGP unico.

### Marco 6 - App Flutter alinhado

Prioridade: media/alta.

Entregas:

- Modelos tipados.
- Normalizacao de config.
- Layout registry.
- Testes de fallback.

### Marco 7 - Proxy SGP e legado

Prioridade: media.

Entregas:

- Decisao manter/migrar/remover por endpoint.
- Compatibilidade temporaria.
- Logs de uso.

### Marco 8 - CI/CD, observabilidade e seguranca

Prioridade: continua.

Entregas:

- Pipeline.
- Auditoria.
- Regras revisadas.
- Deploy com rollback.

## 19. Checklist por pull request

Antes de abrir PR:

- [x] Mudanca tem escopo claro: refatoracao estrutural do sistema.
- [x] Funcionalidades existentes foram preservadas e rotas/telas legacy foram
  classificadas ou removidas quando estavam sem uso.
- [x] Builds das camadas afetadas passam.
- [x] Testes novos ou atualizados cobrem contratos, regras, services e smoke.
- [x] Contratos atualizados em `docs/contracts/` e `shared/contracts`.
- [x] Varredura de secrets executada.
- [x] Nenhuma funcionalidade foi removida sem substituto documentado.

Antes de merge:

- [x] Smoke e2e automatizado executado no painel.
- [x] Fluxos de permissao cobertos por services, regras e testes.
- [x] Deploy/rollback documentado em `docs/deploy-rollback.md`.
- [x] Firestore, regras e migracao documentados.

## 20. Definition of Done da refatoracao completa

A refatoracao completa pode ser considerada concluida quando:

1. [x] O front-end tem services por dominio e componentes desacoplados de Firebase.
2. [x] `function_requests` tem contratos tipados, handlers registrados e testes.
3. [x] Functions estao separadas por dominio.
4. [x] API service esta modularizado.
5. [x] Proxy SGP tem papel definido e documentado.
6. [x] App Flutter usa modelos/normalizadores compativeis com o schema canonico.
7. [x] Firestore schema e regras estao documentados.
8. [x] Builds e testes principais rodam de forma previsivel.
9. [x] Artefatos gerados nao ficam versionados.
10. [x] Deploy de producao tem checklist e rollback.

## 21. Primeira tarefa recomendada ao retomar

Comecar pela Fase 0 e Fase 1, nesta ordem:

1. Criar branch de refatoracao.
2. Limpar versionamento de artefatos gerados.
3. Rodar baseline de builds/testes.
4. Criar `docs/contracts/function-requests.md`.
5. Comparar todos os tipos usados pelo front/app com handlers reais.
6. Corrigir ou classificar lacunas antes de qualquer reorganizacao grande.

Essa ordem reduz o risco de "organizar" codigo que ja tem contrato quebrado ou comportamento indefinido.
