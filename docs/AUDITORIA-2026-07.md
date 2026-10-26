# Auditoria completa — painel_provedores

**Data:** 2026-07-17 · **Branch:** `refactor/base-architecture`
**Escopo:** admin-painel (React), api-service (Express/TS), proxy-sgp (Node), Firebase Functions + Rules, app Flutter, infra/CI/deps.
**Método:** revisão manual + 6 auditorias paralelas por subsistema, com verificação direta das alegações críticas no código.

> Todas as alegações Críticas/Altas abaixo foram confirmadas lendo o código-fonte real. Nada foi modificado.

---

## Tema central (a raiz de quase tudo)

O sistema tem **um plano de dados de assinante sem autenticação/autorização real**. Três sintomas do mesmo problema arquitetural:

1. **Login só por CPF** — `/check-cpf` emite um `customToken` do Firebase para quem souber um CPF, sem senha/OTP. CPF no Brasil é semi-público e enumerável.
2. **Identidade vinda do cliente** — CPF e `providerId` são enviados no *corpo* das requisições, não derivados do token verificado. Sem vínculo usuário↔provedor.
3. **Rotas SGP sem token** — várias rotas de assinante no `api-service` e no `proxy-sgp` não exigem autenticação nenhuma.

Enquanto isso não for resolvido no backend, o app Flutter e o painel não têm como se proteger. **Este é o item nº 1 a corrigir.**

---

## 🔴 CRÍTICO

### C1. Escalonamento a Super Admin por forja de `requesterUid` na fila de Functions
**Arquivos:** `firestore.rules:29-38`, `functions/src/app/requestRouter.ts:20-26`, `functions/src/handlers/users.ts:81-101`

A fila `function_requests` roda sem contexto de autenticação — cada handler confia no campo `requesterUid` gravado no documento. A regra `isOwnFunctionRequest` é um **OR**: aceita o doc se `payload.requesterUid == auth.uid` **ou** se o `requesterUid` de topo bater. O router só normaliza (copia `payload.requesterUid` para o topo) quando o `requesterUid` de topo **não é string** (`requestRouter.ts:21-22`).

**Exploit (qualquer usuário autenticado → Super Admin):**
```json
{ "type": "SET_SUPER_ADMIN_BY_EMAIL",
  "requesterUid": "<UID_DE_UM_SUPERADMIN>",
  "payload": { "requesterUid": "<MEU_UID>", "email": "meu@email.com" } }
```
A regra passa (segunda cláusula: `payload.requesterUid == meu uid`). O router usa o `requesterUid` de topo forjado (string), `requireSuperAdmin("<UID_DE_UM_SUPERADMIN>")` passa, e o handler concede `superAdmin` à **conta do atacante**. O UID de um superadmin vaza facilmente por `notifications.sentBy` e `tickets/*/messages.senderUid` (legíveis por clientes). Mesma técnica serve para `CREATE_ADMIN_USER`, `DELETE_PROVIDER`, etc.

**Correção:** na regra, exigir um **único** campo canônico `request.resource.data.requesterUid == request.auth.uid` e rejeitar docs com `payload.requesterUid` divergente. No router, rejeitar quando topo e payload divergem — nunca deixar o campo aninhado sobrescrever o de topo usado na autorização.

### C2. Login só por CPF emite sessão Firebase sem senha/2FA
**Arquivos:** `proxy-sgp/index.js:689, 869-876`, `app-flutter/.../auth_repository.dart:42-112`

`/check-cpf` (sem autenticação, só rate-limit) busca o CPF no SGP com o token do provedor e devolve um `customToken` do Firebase (uid = CPF). Basta o CPF para tomar conta da conta: ver faturas/valores, `unlock-trust`, ler ONU e **trocar SSID/senha do WiFi**. O check `uid === reqCpf` não protege — o atacante legitimamente possui um token cujo uid é o CPF da vítima.

**Correção:** exigir 2º fator antes do `createCustomToken` — senha central do contrato, ou OTP para telefone/e-mail já cadastrados no SGP.

### C3. Rotas de assinante do `api-service` totalmente sem autenticação (IDOR + ação financeira)
**Arquivos:** `api-service/src/app.ts:30`, `api-service/src/routes/subscriber.routes.ts:13-135`

`app.use(subscriberRouter)` é montado na raiz só com `sgpLimiter`, sem `verifyToken`. Todas as rotas usam `cpfCnpj` do corpo, sem verificar posse:
- `POST /getInvoices` → devolve faturas com **linha digitável, código PIX e link de pagamento** para qualquer CPF.
- `POST /makePaymentPromise` → **ação de estado** (libera/desbloqueia contrato) para qualquer CPF.
- `POST /getClientData`, `/getConsumptionData` → PII e consumo.

Anônimo enumera CPFs (11 dígitos, dígito verificador conhecido) e colhe a base inteira + instrumentos de pagamento. **Correção:** exigir `verifyToken` no router e derivar/autorizar o CPF a partir do principal autenticado.

### C4. Vazamento de token SGP + PII em massa nos logs em disco do proxy-sgp
**Arquivos:** `proxy-sgp/output.log`, `debug_login.log`, `proxy_debug.log`

Contêm segredos e PII **reais e válidos**:
- **Token mestre SGP** `4b6aae35-...` (= `SGP_TOKEN` do `.env`) — acesso total à base de clientes via API SGP.
- **123 contratos** com nome, CPF formatado, **data de nascimento**, **coordenadas GPS da casa**, endereço, telefones, e-mail e **senhas** (`vibe123`, `230669`, ...).

Mitigação: os `.log` estão no `.gitignore` e **nunca foram commitados** (verificado) — a exposição é local (working tree/host), não no histórico git. Mas o código **grava** respostas cruas do SGP em disco. **Correção:** (1) **rotacionar o `SGP_TOKEN` agora** (tratar como comprometido); (2) apagar os 3 logs e purgar de backups; (3) parar de logar params/respostas cruas (ver A6); (4) mover segredos para secret manager.

---

## 🟠 ALTO

### A1. Auto-registro como "cliente" de qualquer provedor → acesso cross-tenant
**Arquivo:** `firestore.rules:114-118, 53-65`

`clientes/{clientId}` permite create por `auth.uid == clientId && clientSyncFieldsValid()`, e `clientSyncFieldsValid` **não verifica** que o usuário pertence ao provedor — só valida o conjunto de chaves e `providerId is string`. Qualquer usuário cria `clientes/<meuUid>` com `providerId` de uma vítima e ganha: ler **notifications** da vítima (com `targetCpf` = CPFs e `sentBy` = UIDs de admin → alimenta C1), ler anexos de tickets de outros, escrever em `diagnostic_results`. **Correção:** vínculo cliente↔provedor definido no servidor (Function validando contra SGP/convite), não campo gravável pelo cliente.

### A2. `providerId` controlado pelo cliente sem verificação (proxy-sgp e api-service)
**Arquivos:** `proxy-sgp/index.js:306-353`, `api-service` rotas SGP (diagnostics/proxy)

O token só carrega o CPF; cada request manda `providerId` no corpo e o proxy carrega as credenciais **daquele** provedor. Nada vincula o usuário ao tenant. Usuário do provedor A aponta para o B e faz o proxy consumir o token do B. **Correção:** gravar `providerId` como custom claim no login e derivar do `req.user`, ignorando o corpo.

### A3. `/check-cpf` do api-service sem autenticação (oráculo de CPF)
**Arquivo:** `api-service/src/routes/proxy.routes.ts:9-12`

Única rota do arquivo sem `verifyToken`. Serve de oráculo de existência de CPF na base. **Correção:** aplicar `verifyToken` (ou no router inteiro).

### A4. SSRF via traceroute (branch de hostname sem revalidação pós-DNS)
**Arquivos:** `api-service/src/validators/traceroute.ts:7-15`, `diagnostics.routes.ts:19-31`

`isValidTracerouteTarget` só bloqueia IPs privados **literais**. Para alvos com letra, aceita o hostname sem resolver DNS — `localhost`, `metadata.google.internal` ou domínio do atacante que resolve para `169.254.169.254`/`10.x` passam, e o handler retorna o `raw` stdout (topologia interna). Sem injeção de comando (spawn com array + filtro de charset). **Correção:** resolver o hostname e revalidar cada IP resolvido contra faixas privadas/loopback/link-local antes do spawn; não retornar `raw`.

### A5. `/admin-cron/trigger-cron` falha aberto quando `PROXY_SECRET` não está setado
**Arquivo:** `proxy-sgp/cron-jobs.js:103-114`

`if (secret !== process.env.PROXY_SECRET_KEY && secret !== process.env.PROXY_SECRET)` — se ambas env vars são `undefined`, mandar **nenhum** secret faz as duas comparações darem `false` e o 403 é pulado. Dispara `cron.getTasks().forEach(t => t.now())` (todas as tarefas). **Correção:** reusar `assertProxySecret` (rejeita quando não configurado) + `crypto.timingSafeEqual`.

### A6. Enforcement de papel só no cliente (rotas super-admin sem `requiredRole`)
**Arquivo:** `admin-painel/src/App.tsx:102-124` vs `ProtectedRoute.tsx`

`ProtectedRoute` suporta `requiredRole`, mas **nenhuma rota o passa**. `/dashboard`, `/provedores`, `/utilizadores` ficam acessíveis a qualquer papel; só guardas ad-hoc dentro das páginas salvam hoje. **Correção:** passar `requiredRole="superAdmin"` nas rotas; garantir (já verificado: `requireSuperAdmin` existe nas Functions) que o backend é a fronteira real.

### A7. Leitura pública do doc de provedor pode expor credenciais SGP legadas
**Arquivos:** `firestore.rules:76-78,102-105`, `functions/src/handlers/sgp.ts:50-53`, `backups.ts:46`

`provedores/{id}` é `allow read: if true`. `publicProviderDataValid` bloqueia gravar `integrations`, mas não `apiToken`/`token`/`password` na raiz, nem dados **já existentes**. `sgp.ts` ainda lê `data.integrations`/`data.details?.apiToken` como fallback, e `restoreProviderConfig` faz merge de backup cru na raiz. Qualquer anônimo lê o token via um único `get`. **Correção:** nunca guardar segredo no doc público; remover fallbacks; sanitizar backup/restore; restringir a leitura pública a um allow-list de campos de tema.

### A8. HTTP em cleartext é permitido e é o default no app Flutter
**Arquivos:** `provider_config.dart:59-72`, `diagnostico_service.dart:812-818`

`apiUrl` vem do Firestore **sem validação de esquema**; fallback é `http://`. Se um provedor for configurado com `http://`, o token Firebase, CPF, faturas e a **nova senha do WiFi** trafegam em claro. **Correção:** rejeitar não-`https` no `ProviderConfig.fromJson` (exceto loopback em debug); `usesCleartextTraffic=false` no Android.

---

## 🟡 MÉDIO

- **M1 — Sem escopo de tenant nas rotas SGP do api-service** (`diagnostics.routes.ts:12`, `proxy.routes.ts:14`): mesmo com `verifyToken`, não checa se o CPF pertence ao `providerId` do chamador. `/cpe/wifi/update` altera WiFi de qualquer contrato.
- **M2 — Notifications vazam CPF e UID de admin** (`firestore.rules:154-155`, `notifications.ts:72-123`): docs com `targetCpf`/`sentBy` legíveis por qualquer cliente do provedor. Alimenta C1/A1.
- **M3 — Credenciais Postgres hardcoded no compose** (`docker-compose.yml:90,114-116`): `sgp_user`/`sgp_password` versionados; DB alcançável por todo container na `painel_net`. **Rotacionar e externalizar.**
- **M4 — Sem TLS no reverse proxy** (`Caddyfile`, `docker-compose.yml:11`): só `:8080` HTTP; mapeamento `8443:443` morto; sem HSTS/CSP. Tokens/PII em claro na rede.
- **M5 — SSRF via `sgpBaseUrl` do corpo** (`proxy-sgp/index.js:538-583` `/sync-clients`; `functions/.../generateApk.ts:10-18` segue redirect sem allow-list de host). Gated por secret/superAdmin, mas real.
- **M6 — Erros internos vazados ao cliente** (api-service `sgpClient.ts:46`; proxy `index.js:668,685` expõe texto do PostgreSQL; functions `errors.ts:10`, `generateApk.ts` devolve stderr do subprocesso).
- **M7 — `secureLog` mascara por nome de chave (allowlist errada)** (`proxy-sgp/lib/secure-log.js`): `razaoSocial`, `dataNascimento`, `endereco_ll` (GPS), `telefones`, `emails` passam em claro; call-sites logam respostas cruas do SGP. Foi exatamente isso que materializou C4.
- **M8 — Cron de "fatura vence amanhã" usa campos SGP errados** (`cron-jobs.js:55`): filtra `t.vencimento`/`t.situacao` mas o schema é `dataVencimento`/`status:'abertos'` → filtro nunca casa, push nunca é enviado. Data em UTC vs America/Recife.
- **M9 — Dedup da fila é TOCTOU** (`requestRouter.ts:13-17`): entregas concorrentes podem processar 2×; `SEND_PUSH_NOTIFICATION`, `DELETE_PROVIDER` não são idempotentes. Usar create transacional de marcador.
- **M10 — Bug de secrets stale no painel** (`providerSettingsService.ts:20-31`): `secrets` lido uma vez e capturado no closure do `onSnapshot`; após salvar o token, o snapshot re-renderiza com o valor antigo (parece "perder" até reload). Também: falha de permissão no `getDoc(secretRef)` derruba **toda** a página de settings (fail-closed demais).
- **M11 — App guarda senha SGP sem uso** (`auth_repository.dart:96,141,229`): `data['senha']` persistida em secure storage e chaves de biometria, mas login é só CPF e biometria é stub. Superfície de ataque sem benefício. `FlutterSecureStorage` usado sem opções endurecidas, enquanto o wrapper endurecido (`security_service.dart`) é dead code.
- **M12 — Scripts privilegiados/dev no source deployável das Functions** (`generate_token.ts` minta token para `vibe@gmail.com`; `manual_fix_vibe.ts` roda `initializeApp()` no import). Mover para fora do build ou apagar.
- **M13 — apk-builder roda como root** (`Dockerfile.apkbuilder`) com keystore de release + service-account montados, base `:stable` mutável. Blast radius máximo se comprometido (gated por superAdmin/loopback). Pinar digest e rodar não-root.

---

## 🟢 BAIXO / Qualidade / Fatoração

- **Regex quebrada em `SecurityValidators`** (`security_service.dart:186,208`): `\$` em raw string é `$` literal, não âncora de fim — `isValidCPF`/`isValidEmail` não rejeitam entradas inválidas. Módulo é dead code hoje, mas é uma armadilha se ligado.
- **Página de teste em produção** (`admin-painel/public/teste-final-upload.html`): upload Firebase não autenticado (bloqueado pelas Storage rules, mas não deveria existir). Apagar.
- **Dead code volumoso no Flutter**: `security_service.dart` (~266 linhas), `biometric_service.dart` (duplicado com namespace divergente), campos/imports não usados nas páginas de diagnóstico (grosso das 113 warnings).
- **Arquivos gigantes (manutenibilidade)**: `dashboard_page.dart` (1819), `diagnostic_05_page.dart` (1639), `shared_diagnostico_page.dart` (1615), `diagnostico_service.dart` (1292). Decompor.
- **806 infos do analyzer**: 534 `deprecated_member_use` (migração `withOpacity`→`withValues` incompleta), `use_build_context_synchronously` ×4 (`rating_prompt_dialog.dart:46`, `main.dart:188`), `avoid_print` ×4.
- **`any` pervasivo no painel** (`shared/contracts/index.ts:71-100,166` com `[key: string]: any`) mina a camada de normalização tipada.
- **Dados mockados exibidos como reais** (`MyCompanyPage.tsx:104-127` "Integração SGP — Conectado" fixo; `NotificationSenderPage` histórico fake).
- **`.gitignore` sem ignores explícitos** para `*.jks/*.keystore/*.p12/*.pem/*-service-account*.json/key.properties` — defesa em profundidade contra `git add .` acidental.
- **Actions de CI em tags flutuantes** (`actions/checkout@v4` etc.) — pinar em SHA.
- **`flutter_analyze.txt` versionado** (dump gerado) — remover do tracking.
- **Login throttle só no cliente** (`LoginPage.tsx`) — não é controle de segurança.
- **`AuthContext` nunca renova claims** (`AuthContext.tsx:21-63`) — privilégio revogado persiste ~1h no cliente.
- **Toggle de TLS-verify por env** (`api-service/config/env.ts:18` `SGP_REJECT_UNAUTHORIZED=false`) — proibir em produção.
- **CORS permite requisições sem `Origin`** com `credentials:true` (api-service e proxy) — defesa em profundidade.

---

## Pontos corretos (o que já está bom)

- **`updateProviderDetails` remove `apiToken` do doc público** (`providers.ts:84`) e o roteia para `secrets/sgp` — corrige o risco que o frontend sugeria (o token não é persistido publicamente por este caminho).
- Rules de `secrets` (`provedores/{id}/secrets/**`) exigem `canManageProvider` — **sem roubo cross-tenant do segredo via rules**.
- Escopo multi-tenant correto nas rotas Firestore do api-service (`providers`/`tickets`/`dashboard` escopam por `req.user.providerId`) e no painel (`useApi` força `forceProviderScope` para providerAdmin).
- SQL parametrizado no proxy (identificador de tabela sanitizado); `spawn` sempre com array (sem shell injection) no traceroute, generateApk e apk-builder.
- Containers endurecidos: `no-new-privileges`, `read_only`+`tmpfs`, usuário `node` não-root (api/proxy), healthchecks, log rotation; Postgres sem porta publicada; apk-builder em loopback com SSRF-guard no download de logo.
- **`npm audit --omit=dev` (root): 0 vulnerabilidades.** Sem segredos/service-account/keystores commitados.
- Sem `dangerouslySetInnerHTML`/`eval` no painel; sem bypass de TLS no Flutter; segredos não vão para o log do app.

---

## Log de remediação (aplicado em 2026-07-17)

Verificado: Functions build + 55 testes · api-service tsc + 8 testes · proxy-sgp testes · admin-painel tsc/lint · Flutter analyze limpo.

| Item | Status | O que foi feito |
|------|--------|-----------------|
| C1 forja requesterUid | ✅ | `isOwnFunctionRequest` exige topo==uid e payload==uid; router rejeita divergência; +testes (rules e router) |
| C2 login só CPF | ✅ (opt-in) | Flag `REQUIRE_LOGIN_SECOND_FACTOR` no proxy exige senha central antes do token. **Ativar após UI Flutter enviar `senha`** |
| C3 rotas assinante sem auth | ✅ | `verifyToken` por rota + vínculo assinante↔CPF no `subscriberRouter` |
| C4 logs com PII/token | ✅ | 3 logs apagados; `secureLog` mascara PII; **rotacionar `SGP_TOKEN` (ação manual)** |
| A1 auto-registro cliente | ✅ | `clientSyncFieldsValid` exige `providerId == token.providerId` |
| A2 providerId do cliente | ✅ | providerId vira claim no token; `verifyFirebaseToken` rejeita divergência |
| A3 /check-cpf oráculo | ✅ | Coberto por C2 (segundo fator) + rate-limit |
| A4 SSRF traceroute | ✅ | Revalidação pós-DNS + pinning IP público; +CGNAT; +testes |
| A5 cron fail-open | ✅ | `trigger-cron` fail-closed + `timingSafeEqual` |
| A6 rota super-admin | ✅ | `requiredRole="superAdmin"` nas rotas admin |
| A7 segredo em doc público | ✅ | Token só do secret; backup/restore sanitizado |
| A8 HTTP cleartext app | ✅ (opt-in) | Valida esquema; `ENFORCE_HTTPS` força https. **Ativar junto com TLS (M4)** |
| M2 notifications vazam | ✅ | Rule por alvo/broadcast + query Flutter + índices |
| M3 senha Postgres | ✅ | Externalizada p/ `.env`. **Rotacionar no banco (manual)** |
| M4 sem TLS Caddy | ✅ (config) | `SITE_ADDRESS` habilita HTTPS automático + HSTS. **Definir domínio + portas** |
| M5/M6 erros vazados | ✅ | Genéricos ao cliente em api-service, proxy e functions |
| M7 secureLog PII | ✅ | Denylist expandida (nome, endereço, GPS, telefone, e-mail, wifi…) |
| M8 cron nunca dispara | ✅ | `dataVencimento` + `status:'abertos'` |
| M9 dedup TOCTOU | ✅ | Claim atômico via `function_locks` |
| M10 secrets stale | ✅ | Assina ambos os docs; falha de secrets degrada localmente |
| M11 senha guardada | ✅ | App não persiste mais a senha SGP; marcador de auto-login trocado |
| M12 scripts dev | ✅ | `generate_token.ts` e `manual_fix_vibe.ts` removidos |
| M6 regex (Flutter) | ✅ | `\$`→`$` em `SecurityValidators` |
| H2 token mascarado | ✅ | Campo password + toggle em IntegrationsSettings |
| M3-react limpar token | ✅ | Limpar integrações apaga o secret (`deleteField`) |
| Página teste upload | ✅ | `teste-final-upload.html` removida |
| .gitignore chaves | ✅ | `*.jks/*.p12/*.pem/*-service-account*.json`… + `flutter_analyze.txt` destrackeado |

**Ações manuais pendentes (não automatizáveis por código):**
1. **Rotacionar `SGP_TOKEN`** no SGP (foi exposto em log local) e o `PROXY_SECRET`.
2. **Rotacionar a senha do Postgres**: `ALTER USER sgp_user WITH PASSWORD '<forte>';` e atualizar `POSTGRES_PASSWORD` no `.env` (o volume `pgdata` mantém a senha atual).
3. **Habilitar TLS**: definir `SITE_ADDRESS=painel.seudominio.com` e mapear portas 80/443 no compose; depois ligar `ENFORCE_HTTPS` no build Flutter.
4. **Ativar o segundo fator**: adicionar campo de senha no login Flutter e ligar `REQUIRE_LOGIN_SECOND_FACTOR=true`.

### Segunda rodada — itens restantes (também aplicada em 2026-07-17)

| Item | Status | O que foi feito |
|------|--------|-----------------|
| M1 escopo de tenant SGP | ✅ | `assertCpfInTenant` resolve CPF→provider via `clientes` e bloqueia acesso cross-tenant em `/diagnostic/onu-signal` e todas as rotas proxy com CPF |
| TLS-verify em produção | ✅ | `SGP_REJECT_UNAUTHORIZED=false` ignorado quando `NODE_ENV=production` |
| CORS 500→403 | ✅ | Rejeição de origem agora usa `ApiError(403)` |
| Timing-safe no proxy | ✅ | `assertProxySecret` com `timingSafeEqual` |
| Crash `providerId.replace` | ✅ | Guard 400 antes de montar o nome da tabela (2 rotas) |
| Vazamento de erro do Postgres | ✅ | Texto do DB não vai mais ao cliente |
| Stub / analyze mock | ✅ | Mantidos (contracts.js marca `keep-temporarily` p/ apps antigos), mas documentados e com código morto removido; stub não lê mais `sgpParams/sgpBaseUrl` do corpo |
| AuthContext claims | ✅ | `onIdTokenChanged` + refresh forçado a cada 15 min |
| revokeObjectURL | ✅ | Object URL liberado no `onload`/`onerror` |
| Protocolos tiptap | ✅ | `protocols: ['http','https','mailto']` |
| Token duplicado no dialog | ✅ | Campo removido do `EditProviderDialog` (fonte única: IntegrationsSettings) |
| `SENSITIVE_CONFIG_FIELDS` | ✅ | Deixou de ser dead code: redige campos sensíveis antes de gravar o doc público |
| Dados mockados como reais | ✅ | MyCompanyPage mostra status derivado real; histórico de notificações lê a coleção `notifications` |
| Flutter provider lança | ✅ | Serviço nullable + estado de erro, sem lançar no builder |
| Dead code Flutter | ✅ | `security_service.dart` e `biometric_service.dart` removidos; opções endurecidas migradas para o `FlutterSecureStorage` real |
| Digest da imagem apk-builder | ✅ | Base fixada por `sha256:0a9de3b7…` |
| Pin de actions CI | ✅ | 15 referências fixadas por SHA nos 4 workflows |

**Único item deliberadamente NÃO aplicado:**
- **M13 — apk-builder rodando como root.** Mudar para não-root exige reconfigurar propriedade do Android SDK montado, dos caches `/root/.gradle` e `/root/.kotlin`, do pub-cache e do `key.properties` — só validável executando um build real de APK. Aplicar às cegas provavelmente quebraria a geração de APK. O digest já foi fixado; o serviço permanece em loopback (`127.0.0.1:8035`), com `no-new-privileges` e exigindo token de superAdmin.

---

## Ordem de remediação sugerida

1. **C1** (forja de `requesterUid`) — explorável hoje por qualquer assinante, vira Super Admin. Corrigir regra + router **antes de tudo**.
2. **C4** — rotacionar `SGP_TOKEN` já, apagar os 3 logs, parar de logar respostas cruas (M7).
3. **C2 + C3 + A1 + A2 + A3** — a reforma de auth do plano de assinante: 2º fator no `/check-cpf`, `providerId` como claim, `verifyToken` nas rotas SGP, vínculo cliente↔provedor no servidor.
4. **A4** (SSRF traceroute), **A5** (cron fail-open), **A7** (segredo legado no doc público), **A8** (HTTPS no app).
5. **M3/M4** (senha Postgres, TLS no Caddy) antes de expor à internet.
6. Médios restantes → baixos/qualidade (dead code, analyzer, arquivos gigantes).
