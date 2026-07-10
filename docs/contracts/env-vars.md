# Contrato: Environment Variables

Atualizado em 2026-07-10. Nao registrar valores reais neste arquivo.

## Frontend admin

| Variavel | Uso |
| --- | --- |
| `VITE_API_URL` | URL publica do `api-service` usada no build Vite |

## API service

| Variavel | Obrigatoria | Default | Uso |
| --- | --- | --- | --- |
| `PORT` | nao | `9136` | Porta HTTP |
| `NODE_ENV` | nao | `development` | Ambiente |
| `FIREBASE_API_KEY` | sim para login REST | vazio | Identity Toolkit |
| `ALLOWED_ORIGINS` | nao | origens locais/producao | CORS separado por virgula |
| `SGP_TOKEN` | sim para rotas nativas SGP | vazio | Token SGP |
| `SGP_APP_NAME` | sim para rotas nativas SGP | vazio | App SGP |
| `SGP_BASE_URL` | nao | `https://vibetelecom.sgp.net.br` | Base SGP |
| `SGP_REJECT_UNAUTHORIZED` | nao | `true` | TLS para SGP |
| `PROXY_SGP_INTERNAL_URL` | nao | `http://backend-proxy:3002` | Proxy legado/cache |
| `APK_SCRIPT_PATH` | nao | script local | Gerador APK |
| `APK_PROJECT_ROOT` | nao | raiz do repo | CWD do gerador |
| `APK_OUTPUT_DIR` | nao | `public_apks` | Saida |
| `APK_FLUTTER_PROJECT` | nao | `app-flutter/unified` | Projeto alvo |

## Firebase Functions

Secrets/params:

| Nome | Tipo | Uso |
| --- | --- | --- |
| `PROXY_URL` | secret | URL do proxy SGP |
| `PROXY_SECRET` | secret | Segredo server-to-server do proxy |
| `APK_SCRIPT_PATH` | param | Script de APK |
| `APK_PROJECT_ROOT` | param | Raiz do projeto APK |

Variaveis runtime:

- `GCLOUD_PROJECT`
- `GCP_PROJECT`
- `PROJECT_ID`
- `STORAGE_BUCKET`
- `FIREBASE_STORAGE_BUCKET`

## Proxy SGP

| Variavel | Obrigatoria | Default | Uso |
| --- | --- | --- | --- |
| `PORT` | nao | `3002` | Porta HTTP |
| `DATABASE_URL` | sim em Docker | Postgres local | Cache Postgres |
| `REDIS_URL` | nao | Redis local | Cache/rate limit |
| `PROXY_SECRET` | recomendado | vazio | Rotas server-to-server |
| `PROXY_SECRET_KEY` | recomendado | vazio | Alias legado |
| `DEBUG_REQUESTS` | nao | `false` | Logs detalhados |
| `ENABLE_DEV_CPF_MOCK` | nao | `false` | Mock de login |
| `DEV_MOCK_CPF` | nao | vazio | CPF do mock |
| `SGP_BASE_URL` | fallback | `https://vibetelecom.sgp.net.br` | Base SGP |
| `SGP_TOKEN` | fallback | vazio | Token SGP |
| `SGP_APP_NAME` | fallback | vazio | App SGP |

## APK builder dedicado

| Variavel | Uso |
| --- | --- |
| `APK_BUILDER_PORT` | Porta do servico |
| `PORT` | Fallback de porta |
| `PYTHON_BIN` | Python para script |
| `APK_SCRIPT_PATH` | Script de build |
| `APK_PROJECT_ROOT` | Raiz do projeto |
| `APK_OUTPUT_DIR` | Saida |
| `APK_FLUTTER_PROJECT` | Projeto Flutter alvo |
| `ANDROID_HOME`/`ANDROID_SDK_ROOT` | SDK Android |

## Regras

- Secrets ficam em `.env`, Firebase secrets ou store segura do host.
- A API valida configuracoes criticas no boot com warnings.
- `npm run security:secrets` verifica padroes comuns de secrets versionados.
