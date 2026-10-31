# Rearquitetura F0/F1 — lote 1: baseline e inventário C4/C11/E3/E9

Data: 31/10/2026 (UTC). Tarefa: `task-17baa3af4fe4-f0-baseline`. Estado deste documento: **somente documentação**. Nenhum código de produto, serviço, regra, imagem ou segredo foi alterado; nada foi implantado ou distribuído.

Responsabilidade: executor técnico nominal desta continuação = `executor-codex-task-17baa3af4fe4-f0-baseline` (mesma identificação no `summary` do `.paseo-result.json`; revisão independente cabe ao controlador em outra sessão); coordenação = gerente deste chat; E8 = administrador externo do SGP (cadastro/validação pela equipe SaaS). O rascunho recebido da tentativa anterior foi preservado e conferido nas fontes abaixo; sua identificação anterior não representa o executor desta entrega.

## 1. Baseline vinculado

| Commit | Conteúdo | O que **não** é |
| --- | --- | --- |
| `aeef740` | Preserva as alterações locais anteriores ao lote, sobre o HEAD auditado `69bc581` | Não é correção nova, não é revisado e não é a produção |
| `608af5f` | Manifesto observado de implantação/host em `rearchitecture-deployment-baseline-2026-10-31.json` | Não é homologação; imagens sem `revision`; Functions, regras e APK não revalidados nele |

Manifestos usados (dados coletados anteriormente, não recoletados): [`rearchitecture-baseline-2026-10-31.json`](rearchitecture-baseline-2026-10-31.json) (estado do código; HEAD de origem `69bc581`) e [`rearchitecture-deployment-baseline-2026-10-31.json`](rearchitecture-deployment-baseline-2026-10-31.json) (11 containers em execução, idades de início 29–30/10/2026, backup `ok` às `2026-10-30T06:04:05Z`).

**Atual vs. histórico.** *Atual neste inventário* = código disponível nesta worktree sobre `aeef740`/`608af5f`, conferido por leitura estática. Os manifestos são observações anteriores: código às `2026-10-31T00:49:08.574339+00:00` (registra `sourceHead=69bc581` e alterações ainda locais na coleta), implantação/host às `2026-10-31T00:49:18.066862+00:00`. `aeef740` preservou depois aquelas alterações; `608af5f` arquivou a observação operacional. *Histórico adicional* = comparações de hashes da revisão de 30/10 (plano 15.2), log antigo de 6 testes de regras e auditoria de `69bc581`. O código lido abaixo **não prova** o que roda em produção; só os artefatos listados em 15.2 do plano foram comparados e apenas por arquivo. Nenhum manifesto foi atualizado por consulta ao host ou à produção neste lote.

## 2. Inventário mínimo C4/C11/E3/E9

Legenda de efeito: **L** leitura de segredo/backup, **E** escrita de segredo/destino/personalização, **B** geração de build. “Autorização atual” é a lida no código; “lacuna” é o que contraria a matriz do plano (seção 5).

Fachadas verificadas em `Caddyfile`: `/api/*` remove `/api` e encaminha à API; `/sgp/*` remove `/sgp` e encaminha diretamente ao proxy; `/apk-builder/*` remove esse prefixo e encaminha ao builder. As rotas das tabelas são relativas ao serviço, com método quando relevante; `/sgp` contorna os middlewares da API e requer autorização no próprio proxy. `/public_apks/*` serve artefatos pela landing; disponibilidade pública do APK não autoriza sua geração. Este é o roteamento local, sem comprovação de configuração ativa.

### 2.1 HTTP `/api` (api-service, Express)

| Arquivo / rota | Escritor → efeito | Consumidor | Autorização atual | Lacuna / achado |
| --- | --- | --- | --- | --- |
| `api-service/src/routes/providers.routes.ts` `GET /admin/providers` | lê `provedores` (remove `integrations` na raiz e em `config`) | painel web e `admin_app` | `verifyToken` + `verifyAdmin`; `superAdmin` lista todos; providerAdmin só `providerId` do token | Filtro só nas chaves `integrations`; `details.apiToken` não é removido; sem schema de saída (C4) |
| idem `POST /admin/providers` | **E** `set(data, {merge:true})` em `provedores/{id}`; auditoria `recordAdminAudit` com `payload: data` | painel web (via `useApi`) | criar: superAdmin; alterar: `canAccessProvider` (provedor pode alterar o próprio) | Remove só `integrations/apiToken/token/password` na **raiz**; aninhados (`config.*`, estruturas genéricas) passam ao documento público (C4 aberto). Auditoria: `api-service/src/services/auditService.ts` aplica redação recursiva (inclui `apiToken/token/password`) antes de persistir — proteção existente; limites: lista de chaves fixa, segredos com outros nomes não são cobertos, e o documento público segue exposto |
| `routes/tickets.routes.ts`, `users.routes.ts`, `dashboard.routes.ts` | tickets, usuários, dashboard | painel web | verificações próprias por rota | Fora do núcleo C4/E3; mapeados para F1 E9 |
| `routes/adminAuth.routes.ts` `POST /admin/auth/login` | sessão | painel | `loginLimiter` | Sem relação direta com segredo |
| `routes/proxy.routes.ts` `POST /check-cpf` | repasse ao proxy SGP (login por CPF; emite token) | Flutter | **sem** `verifyToken`; apenas `subscriberLoginLimiter` | Por definição pública; C2/C5 |
| `routes/proxy.routes.ts` demais rotas SGP | repasse SGP | Flutter | `verifyToken`+limites (conforme registro de cada rota) | Destino/credencial: C5/C6 (lote seguinte) |
| `routes/subscriber.routes.ts` `/getClientData`, `/getConsumptionData`, `/getInvoices`, `/makePaymentPromise` | SGP via `api-service/src/services/sgpClient.ts` (resolver chamado em `subscriber.routes.ts:63-69`) | Flutter | `verifyToken`+tenant | C9/C5; fora do escopo deste lote. Ver consumidor independente `sgpClient.ts` na seção 2.2 |
| `routes/diagnostics.routes.ts` `/diagnostic/onu-signal`, `/traceroute` | SGP/rede | Flutter | `verifyToken` + limites de taxa | E1/C16/E9 |
| `app.ts` `/admin/metrics` | métricas | painel/operação | `superAdmin` (`app.ts:30-35`) | — |
| `app.ts` `POST /admin/performance` | grava amostra de desempenho | painel/operação | `verifyToken` + `verifyAdmin` (`app.ts:30-35`) | — |
| `app.ts` `/health`, `/ready` | saúde | operação | **sem autenticação obrigatória** (`app.ts:47-57`) | Públicas; não confundir com as rotas `/admin/*` |

Não existe rota `/api` de backup, restauração, segredo ou build neste serviço (busca por `secrets`/`backup`/`generate` em `api-service/src/routes` não encontra caminho de escrita de segredo além do POST acima).

### 2.2 `/sgp` e proxy (proxy-sgp, `index.js`)

| Rota | Efeito | Autorização | Observação |
| --- | --- | --- | --- |
| `/sync-clients`, `/sync-status`, `/get-cached-clients`, `/get-single-client` | sync e leitura de cache por tenant | segredo interno (`lib/internal-secret.js`) | consumidores: API/worker; segredo SGP lido do Firestore privado |
| `/check-cpf` | login por CPF | `loginCredentialLimiter`; sem token Firebase | C2 |
| `/get-client-data-for-login` | registrada sem `loginCredentialLimiter`; retorna 501, salvo resposta em modo DEV | nenhuma no registro | C2; confirmar se DEV pode ativar em produção |
| `/get-consumption-data`, `/get-invoices`, `/unlock-trust`, `/cpe/wifi/list`, `/cpe/wifi/update`, `/diagnostic/onu-signal[-base]`, `/diagnostic/analyze` | SGP/CPE | `verifyFirebaseToken` | `/diagnostic/analyze`: E1 (resultado predeterminado) |
| `/health`, `/ready` | saúde | pública | — |

Leitor do segredo privado: proxy, worker (`worker.js`, `lib/jobs.js`), `functions/src/handlers/sgp.ts` e o próprio api-service. Consumidor independente `api-service/src/services/sgpClient.ts` (`:85-106`): lê `provedores/{id}/secrets/sgp` via Admin SDK e usa `integrations.apiToken`; aceita URL/app de campos públicos do provedor como fallback; mantém cache de credenciais de 15 s (`:110-117`); sem tenant identificado usa configuração global (`:86-88`). É chamado pelas quatro rotas `subscriber` (autorização do chamador: `verifyToken`+tenant). Deve ser preservado na compatibilidade da integração; SSRF/fallback não são tratados neste lote (C5/C6). Destinos: C5/C6 permanecem abertos; nada alterado aqui.

### 2.3 RPC `function_requests` / `function_responses` (Functions)

Entrada: `functions/src/index.ts` `handleFunctionRequest` (`onDocumentCreated`, `southamerica-east1`), roteador `app/requestRouter.ts` (lock sem lease: C8), 27 tipos em `contracts/index.ts` `FUNCTION_REQUEST_TYPES`. Criação é permitida por `isOwnFunctionRequest()` em `firestore.rules`; leitura/atualização direta é negada; respostas lidas por `isOwnFunctionResponse()`. `functions/src/app/permissions.ts` resolve o usuário no Auth e nega conta desativada; `requireProviderAccess` exige superAdmin ou role providerAdmin com mesmo tenant. As regras diretas usam claims do token; não equivalem a essa consulta atual ao Auth (E4 permanece aberto).

| Tipo | Handler / autorização | Efeito sobre segredo/backup/build | Achado |
| --- | --- | --- | --- |
| `UPDATE_PROVIDER_CONFIG` | `handlers/providers.ts` `requireProviderAccess` (superAdmin **ou** providerAdmin do tenant) | **E** grava `provedores/{id}/secrets/sgp` (`integrations`, linha ~70) | E3: provedor altera integração |
| `UPDATE_PROVIDER_DETAILS` | idem | **E** grava `secrets/sgp` (linha ~103) | E3 |
| `CREATE_PROVIDER` / `DELETE_PROVIDER` | `requireSuperAdmin` | cria/remove tenant | conforme matriz |
| `BACKUP_PROVIDER_CONFIG` | `handlers/backups.ts` `requireProviderAccess` | **L→E** copia `secrets/sgp` para `backups/{id}.secrets` (linha ~41) | C11/E3: backup misto acessível ao provedor |
| `LIST_PROVIDER_BACKUPS` | `requireProviderAccess` | lista metadados | E3 |
| `RESTORE_PROVIDER_CONFIG` | `requireProviderAccess` | **E** restaura por merge e regrava `secrets/sgp` (linha ~73); sanitiza chaves da raiz, `details.apiToken` e `config.integrations`, sem schema recursivo completo | C11 aberto; E3; campos novos ausentes no backup não são excluídos |
| `DELETE_PROVIDER_BACKUP` | `requireProviderAccess` | apaga | E3 |
| `SGP_API_PROXY` | `handlers/sgp.ts` `requireProviderAccess` | usa credencial privada no backend | E3/C5: provedor aciona leitura paginada/detalhe de cache, status e disparo de sync (não encaminha método/path arbitrários) |
| `SEND_PUSH_NOTIFICATION`, `SEND_SCOPED_NOTIFICATION[_SEGMENTED]`, tickets (6), usuários (4), `LIST_PROVIDER_CLIENTS`, `GET_CLIENT_DETAILS`, `DELETE_CLIENT`, dashboard (2) | handlers próprios | sem segredo | E9: mapeados; autorização por transporte a testar em F1 |

### 2.4 Callables

| Função | Autorização | Efeito | Consumidor | Observação |
| --- | --- | --- | --- | --- |
| `generateApk` (`functions/src/callables/generateApk.ts`) | `request.auth.token.superAdmin` | **B** executa o gerador Python no ambiente da Function e registra auditoria | nenhum consumidor identificado nos clientes examinados (o builder do painel usa HTTP `/generate-apk`, ver 2.6) | Entrada callable exportada; restrito a superAdmin no código; conferir se Function ativa executa o gerador (`apkScriptPath`/`apkProjectRoot`); distribuição e autorização efetiva em produção não verificadas; C12/C13 |
| `uploadProviderLogo` (`functions/src/callables/uploadProviderLogo.ts`) | `request.auth` obrigatório + `requireProviderAccess` (superAdmin ou providerAdmin do tenant); PNG/JPEG/WebP em base64, máx. 5 MB | **E** grava `providers/{id}/logo.{ext}` no Storage (Admin SDK) e `set({logoUrl},{merge:true})` em `provedores/{id}` | painel (personalização) | Personalização legítima, sem segredo; ignora regras de Storage (Admin SDK); caminho alternativo ao Storage direto (E9) |

### 2.5 Firestore e Storage (regras locais)

| Caminho | Regra atual (`firestore.rules`/`storage.rules`) | Leitor/escritor | Lacuna |
| --- | --- | --- | --- |
| `provedores/{id}` | leitura pública; escrita `canManageProvider` + `publicProviderDataValid()` | Flutter lê; painel (provedor/SaaS) escreve; API Admin SDK ignora regras | C4: Admin SDK não é limitado; validade das regras só cobre cliente |
| `provedores/{id}/secrets/{doc}` | `read, write: canManageProvider` | painel (`providerSettingsService.ts` `onSnapshot` e `batch.set` em `secrets/sgp`); proxy/worker/Functions via Admin | **E3**: provedor lê e grava segredo e destino direto |
| `provedores/{id}/backups/{id}` | `read, write: canManageProvider` | painel (`BackupSettings.tsx`), Functions | **C11/E3**: backup misto legível/gravável pelo provedor |
| `provedores/{id}/{collection}/{document=**}` | `read, write: canManageProvider` | wildcard | Regra coincidente ampla; revisar com secrets/backups |
| `providers/{id}` e subcoleções | leitura pública (doc) / `canManageProvider` | legado | Caminho alternativo (E9) |
| `provedores/{id}/diagnostic_results` | assinante: somente `create`; leitura, alteração e exclusão administrativas (`firestore.rules:103-112`) | Flutter cria; painel administra | E9: escopo por usuário/recurso a testar |
| `provedores/{id}/incidents` | assinante: somente leitura; escrita administrativa (`firestore.rules:103-112`) | Flutter lê; painel escreve | E9; o wildcard `:122-123` não amplia direitos do assinante |
| `clientes/{id}` | dono, superAdmin ou providerAdmin; create/update com condições | Flutter escreve perfil | E9 |
| `tickets`, `tickets/*/messages`, `notifications`, `users`, `audit_logs`, `maintenance_logs` | leitura restrita; escrita negada ao cliente | Functions escrevem | — |
| Storage `providers/{id}/{file}` e `public_assets` | leitura pública; escrita `canManageProvider`+imagem | painel | personalização legítima |
| Storage `providers/{id}/ticket_attachments`, `diagnostic_reports` | provedor ou cliente do tenant (por tenant, não por assinante/ticket); relatório: cliente cria, somente administrador altera/apaga | Flutter/painel | E9: escopo de anexo e URLs de download compartilháveis |

### 2.6 UI web (admin-painel) e clientes Flutter

| Arquivo | Uso | Lacuna |
| --- | --- | --- |
| `admin-painel/src/shared/firebase/providerSettingsService.ts` | subscreve `secrets/sgp` e grava `secrets/sgp` em `batch` junto da personalização | personalização depende de leitura/escrita de segredos (E3) |
| `admin-painel/src/shared/api/functionRequests.ts`, `shared/contracts/index.ts` | cliente do RPC | caminho para todos os tipos da 2.3 |
| `admin-painel/src/pages/provider-settings/BackupSettings.tsx` | criar/listar/restaurar/apagar backups | exposto ao provedor |
| `admin-painel/src/pages/provider-settings/AndroidBuilder_Final.tsx`, `shared/config/runtime.ts` (`VITE_APK_BUILDER_URL`) | geração de app via `fetch` HTTP `/generate-apk` (`AndroidBuilder_Final.tsx:156`); consumidor efetivo do builder | Restrição visual observada estaticamente: página bloqueada se `userRole` não é `superAdmin` (`:109`); autorização efetiva em produção e do backend do builder não verificadas. Única `httpsCallable` nesse arquivo: `uploadProviderLogo` (`:331`); `generateApk` não é chamado por ele |
| `app-flutter/unified` (`provider_config.dart`, `diagnostic_report_service.dart`, `suporte_service.dart`, etc.) | lê `provedores`; escreve `clientes`, `function_requests`; lê `notifications`, `incidents`; `provider_config.dart` aceita/propaga `integrations` | Cliente tolera `integrations` no documento público (dependência de compatibilidade) |
| `app-flutter/unified/lib/core/providers/configuration_provider.dart`, `core/models/provider_config_normalizer.dart`, `core/models/provider_config.dart` | `loadConfig` lê `provedores/{id}` do servidor, normaliza configuração e guarda cache local; erro mantém cache quando disponível; `apiUrl` determina o destino HTTP e `appName` pode vir de `integrations` | Fonte atual Firestore e cache; leitores de tema/layout e providers `financeiro_provider.dart`, `consumo_provider.dart`, `weekly_usage_provider.dart` dependem do contrato. Compatibilidade exige campos públicos permitidos e cache normalizado, nunca manter token público |
| `app-flutter/unified/lib/core/services/diagnostic_report_service.dart`, `suporte_service.dart`, `notification_service.dart` | PDF em `providers/{id}/diagnostic_reports/{uid}_{stamp}.pdf`; imagem em `ticket_attachments/{stamp}.{ext}`; retornam `getDownloadURL`; tickets via `function_requests`/resposta; notificações via coleção `notifications` | Regras locais não vinculam objeto a assinante/ticket. `attachReportUrl` tenta alterar `diagnostic_results` por merge, mas regra do assinante só permite create: atualização de documento existente é negada e erro apenas registrado; testar jornada em F1. URL de relatório pode circular por WhatsApp e permitir leitura a quem tem o link (comentário em `storage.rules`); regras restritas sozinhas não resolvem o compartilhamento |
| `app-flutter/admin_app` `lib/core/services/api_service.dart` | HTTP `/admin/auth/login`, `GET`/`POST /admin/providers`, `/admin/tickets`; `Authorization: Bearer`; base URL configurável (`api_base_url`) | **Consumidor direto de C4/E3**: usa a rota HTTP, não Firestore/RPC (buscas por `function_requests`/`secrets`/`generate-apk` sem ocorrências) |
| `admin_app` `pages/providers/provider_settings_page.dart` | lê e **escreve** `details.apiToken` e `details.systemUrl` (linhas ~126–130, 179–180, 215) e chama `saveProvider` | Tentativa de gravar token/URL SGP por `POST /admin/providers`, mas o corpo (`toMap()` sem `id`) não identifica o provedor: `providerAdmin` recebe 403; `superAdmin` cria documento público novo (201) que o cliente trata como erro (só aceita 200) — ver backlog 11; o filtro da API (só raiz) não cobre `details` aninhado; depende desse caminho para não perder funcionalidade (compatibilidade a conservar) |
| `admin_app` `core/models/provider_model.dart`, `core/repositories/provider_repository.dart`, `pages/providers/provider_details_page.dart`, `providers_list_page.dart` | serializa `details` e `config`; `saveProvider` em detalhes, listagem e configurações | Mesmo caminho; versões do `admin_app` em campo seguem não identificadas (lacuna de distribuição, não do inventário estático) |

### 2.7 Builds (apk-builder)

| Elemento | Atual | Lacuna |
| --- | --- | --- |
| `services/apk-builder/index.js` `POST /generate-apk`, `GET /jobs/:jobId` | `verifySuperAdmin` (token Firebase com `superAdmin === true`), `buildLimiter` | Autorização HTTP restrita ao SaaS; fila/persistência em `job-store.js` |
| `docker-compose.yml` `apk-builder` | monta `service-account.json` (caminho `/run/secrets/service-account.json`, `GOOGLE_APPLICATION_CREDENTIALS`) **e** o keystore/`key.properties`, escreve `public_apks` | **E2/E3**: credencial de serviço compartilhada e assinatura no mesmo executor. Valores não lidos |
| `scripts/build/generate-apk.py` | copia só APK/AAB; símbolos temporários | C12/C13 |
| Callable `generateApk` | superAdmin | segundo caminho de build (E9) |

### 2.8 Backups e migrações

| Item | Conteúdo | Consumidor | Lacuna |
| --- | --- | --- | --- |
| `scripts/ops/backup-scope.cjs` | incluir `secrets`, `backups`, `clientes`, `incidents`… em coleção-grupo; exclui efêmeras | `backup-cloud.cjs`, `upload-backup.cjs`, `backup-retention.cjs`, `backup-status.cjs` (timer `painel-backup.timer`) | Backup externo inclui segredos: **deve permanecer privado**; criptografia/recuperação de chave fora do host não comprovadas |
| `scripts/ops/backup-data.sh`, `backup-scheduled.sh`, `verify-backup.sh` | `pg_dump` + Redis + verificação | operação | Sem PITR (`archive_mode=off`, histórico) |
| `scripts/migrations/private-provider-credentials.cjs`, `migrate-provider-config.mjs`, `explicit-admin-roles.cjs` | migrações pontuais já existentes | operação manual | Execução em produção não comprovada; não executar neste lote |
| Firestore `provedores/*/backups` (backup de configuração mista) | `secrets` + configuração | RPC da 2.3 | C11/E3 |
| `.github/workflows/deploy-functions.yml` | deploy de Functions com credencial de CI | CI | Fora do escopo; manter sem alteração |

## 3. Caminhos alternativos relevantes

Para a mesma ação privilegiada existem **quatro** entradas: UI web → Firestore direto (`secrets/sgp`, `backups`), RPC `function_requests`, HTTP `/admin/providers` (Admin SDK) e as regras wildcard `provedores/{id}/{collection}/**`. Um bloqueio só em UI, ou só em um transporte, não satisfaz E3. O mesmo vale para build: HTTP `/apk-builder`, callable `generateApk` e (histórico) fila/jobs.

## 4. Lacunas do inventário (não fechadas)

1. Versões mobile e `admin_app` **em campo** (`versionCode` distribuído) e usuários ativos: não identificados (lacuna de distribuição/IAM; o consumo estático do `admin_app` está mapeado em 2.6).
2. Valor atual de regras/Functions em produção: só os hashes de 30/10 em 15.2; o manifesto `608af5f` não os revalida.
3. Inventário de dados por tenant, IAM real do projeto, contas de serviço, custo e capacidade: pendentes (G0 aberto).
4. Cobertura de testes por transporte para E3/C4/C11 não executada neste lote (nenhum teste de regras possível, ver 6).
5. Rotas de tickets/usuários/dashboard e `clientes/*`: autorização lida apenas em superfície; testes específicos em F1 (`uploadProviderLogo` e `admin_app` estão mapeados em 2.4/2.6).
6. Conteúdo de backups antigos no Firestore/externos não inspecionado (não ler segredos).

## 5. Backlog F0/F1 (responsável técnico: `executor-codex-task-17baa3af4fe4-f0-baseline`; coordenação: gerente deste chat; E8: administrador externo SGP)

O executor nominal responde pelo inventário e encaminhamento técnico de cada linha interna; o gerente coordena a atribuição dos próximos contratos e as dependências operacionais. Isso não afirma que IAM, consoles ou distribuição já tenham sido disponibilizados ao executor. E8 permanece atribuído ao administrador externo do SGP.

| # | Item | Achado | Dependência | Risco / limite | Estado |
| --- | --- | --- | --- | --- | --- |
| 1 | Schema explícito de entrada/saída no `POST /admin/providers` e auditoria sem payload bruto; testes com segredos sintéticos aninhados | C4 | nenhuma | Quebrar clientes que dependem de `integrations` público em `provider_config.dart` | Não implementado |
| 2 | Endpoint exclusivo SaaS para integração (token/URL/app); remover `UPDATE_PROVIDER_CONFIG/DETAILS` da escrita de `secrets` para provedor | E3 | 1; separar formulário de personalização | Painel hoje usa `secrets` para salvar cor; sequência obrigatória | Não implementado |
| 3 | Regras: restringir `secrets`, `backups` e wildcard a SaaS/backend; ajustar painel antes de publicar regras | E3/C11 | 2 e testes de regras (Java 21) | Quebra de painel se publicada antes da UI | Não implementado |
| 4 | Backup sanitizado de personalização; restore exato; backup misto privado SaaS | C11 | 3 | Backups antigos contêm segredo; não apagar | Não implementado |
| 5 | Negar `SGP_API_PROXY` e backups ao `providerAdmin`; testes por transporte | E3/E9 | 2 | Cliente legado pode usar | Não implementado |
| 6 | Reduzir credenciais do builder; separar assinatura | E2 | IAM mapeado (F0) | Quebra de build; manter continuidade do keystore | Não implementado |
| 7 | Inventariar versões em campo/`applicationId` do `admin_app` e mobile, IAM e custo; migrar o `admin_app` junto com o endpoint SaaS do item 2 | G0/E9 | acesso a consoles | Sem acesso, permanece lacuna | Aberto |
| 8 | Ambiente Java 21 isolado para regras/emulador | E5 | host Java 17 incompatível com CLI | Não instalar em serviço do host; usar ambiente isolado | Aberto |
| 9 | C5/C6 SSRF/fallback, C8 lease, C12/C13, C14, C16 | demais F1 | lotes seguintes | — | Aberto |
| 10 | Rotação do token SGP | E8 | administrador do SGP | Não apagar valor privado em uso | **Aberto (externo)** |
| 11 | Incompatibilidade `admin_app` → `POST /admin/providers`: `ProviderModel.toMap()` (`provider_model.dart:61`) não inclui `id` e `ApiService.saveProvider()` (`api_service.dart:89`) envia esse mapa e só aceita HTTP 200. Sem `id` a API (`providers.routes.ts:35`) **nega** `providerAdmin` (403) e, para `superAdmin`, **cria** novo documento público com ID automático e responde 201 (`:52-55`), tratado como erro pelo cliente. Não há evidência estática de atualização bem-sucedida do provedor selecionado. | C4/E3 | 1 e 2 (corrigir cliente e contrato juntos) | Não corrigir código neste lote; risco de documentos públicos duplicados já criados (não verificado em dados) e de token/URL gravados em documento novo | Aberto (documentado) |
| 12 | Validar compartilhamento/revogação de URLs de anexos e atualização de `reportUrl` pelo assinante; testes de dono/terceiro, tenant A/B e recurso | E9 | ambiente sintético com regras Java 21; definição de acesso por ticket/assinante | Permissão por tenant não demonstra isolamento por recurso; regra atual pode impedir jornada legítima do relatório | Aberto |

## 6. Ambiente de validação

Java do host era 17 conforme manifesto já coletado; o Firebase CLI exige 21 para o emulador de regras (`npm run test:rules` bloqueado na revisão de 30/10; não repetido aqui). É necessário **ambiente isolado com Java 21** (container ou toolchain local fora dos serviços), com Node, Firebase CLI e dependências fixados, para os testes de regras; resultados anteriores (6 testes) são históricos. Neste lote não foi executado teste de regras nem testes de aplicação (somente documentação). Busca de `AGENTS.md` na worktree e nos diretórios ancestrais não encontrou instruções adicionais; prevalece o contrato delimitado desta tarefa.

## 7. Ordem de implantação e rollback (planejada; **nenhuma implantação neste lote**)

Ordem, cada passo só após revisão, teste e gate:

1. Preparação: Java 21 isolado; testes de regras sintéticos (tenants A/B, segredo sintético); backup verificado atual e cópia privada do backup misto.
2. API: schemas C4 e endpoint SaaS de integração, **mantendo** a leitura/escrita atual de `secrets/sgp` para o backend e o token privado intocado.
3. Clientes: separar formulário de personalização do de integração (sem `secrets`); atualizar painel e `admin_app` com contrato/ID/status corretos. Identificar versões suportadas e verificar leitura do `unified`/APKs existentes com projeção sanitizada; cliente administrativo residual incompatível deve ser atualizado ou retirado explicitamente antes do corte, sem preservar acesso indevido ao token.
4. Functions: negar provedor em `UPDATE_*` de integração, `SGP_API_PROXY` e backups mistos; restore sanitizado.
5. Regras Firestore/Storage restritivas, **por último**, após clientes não dependerem dos caminhos bloqueados.
6. Builder: reduzir IAM; validar build real e continuidade de assinatura antes de revogar acesso antigo.
7. Verificação pós-implantação sem valores sensíveis; registrar manifesto (imagens, hash das regras, build das Functions).

Rollback (**não** é reversão cega ao baseline): o baseline `aeef740`/`608af5f` tem regras com `canManageProvider` em `secrets`/`backups` e handlers com `requireProviderAccess` — voltar a ele **reabriria** o acesso do provedor ao token e ao backup misto, o que a seção 10 do plano proíbe. Portanto:

- Após a restrição de regras/Functions estar publicada, a falha do painel/API **não** é revertida para artefatos permissivos; adota-se **bloqueio temporário** (funcionalidade de integração/backup indisponível ao provedor, SaaS opera) ou **correção para frente**.
- Reverter somente API e painel (que não reabrem segredo) a artefatos anteriores **identificados e validados**, desde que compatíveis com as regras/Functions restritivas vigentes. Se o painel antigo depender de `secrets`, usar bloqueio/correção para frente em vez de reverter regras.
- Antes de qualquer implantação, identificar e validar por hash/versão os artefatos de retorno (imagens com `revision`, build das Functions, regras). O manifesto `608af5f` **não** contém o par de regras/Functions revalidado: esses artefatos de retorno estão **pendentes de identificação** e não podem ser presumidos.

Conservar sempre: token privado em `secrets/sgp` (não apagar nem regravar sem acesso ao SGP), personalização atual, backup misto **privado** (restrito a SaaS/backend), compatibilidade com `provider_config.dart`/APKs existentes e keystore. Não restaurar backup antigo sobre produção. Dados escritos após uma mudança exigem correção para frente, não restauração.

## 8. Situação deste lote

| Item | Código | Testado | Implantado | Distribuído |
| --- | --- | --- | --- | --- |
| Inventário/documentação F0/F1 lote 1 | documento | `git diff --check` apenas | não | não |
| Correções C4/C11/E3/E9 | **não implementadas** | não | não | não |

G0 e F0 **não** estão completos (dados, IAM, mobile e custo pendentes). C4, C11, E3, E8 e E9 permanecem abertos.

Handoff após a falha de transporte ao iniciar a revisão da tentativa 4: rascunho e achados R4/R5 preservados (incompatibilidade `admin_app` sem `id`/HTTP 201 no backlog 11 e executor nominal no resultado). Nesta retomada foi conferida somente a coerência documental com o contrato e os vínculos de baseline; o inventário não foi reiniciado e a bateria funcional não foi repetida. O recibo `.paseo-result.json` não estava presente na worktree recebida e foi reconstituído com `status=completed` para a fase documental, sem afirmar aprovação da revisão independente. Cabe ao controlador encaminhar a nova revisão antes de integrar.

Validação documental desta continuação (31/10/2026): `git diff --check`, status **aprovado (exit 0)**, uma rodada essencial ao fim do bloco. Sem testes funcionais novos; a leitura estática sustenta o mapa de código e não homologa autorização executada, produção ou distribuição. Resultado e executor registrados também em `.paseo-result.json` para o controlador.
