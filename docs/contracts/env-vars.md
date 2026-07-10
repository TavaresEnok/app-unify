# Contrato: Environment Variables

Inventario inicial criado em 2026-07-10.

Este documento registra variaveis de ambiente encontradas no codigo fonte e no Docker Compose. Nao incluir valores reais aqui.

## Frontend admin

| Variavel | Origem | Uso |
| --- | --- | --- |
| `VITE_API_URL` | `docker-compose.yml`, Vite | URL publica/base do `api-service` usada no build do painel. |

## API service

| Variavel | Obrigatoria | Uso |
| --- | --- | --- |
| `PORT` | nao | Porta HTTP, default `9136`. |
| `SGP_TOKEN` | sim para SGP | Token de integracao SGP. |
| `SGP_APP_NAME` | sim para SGP | Nome/app de integracao SGP. |
| `FIREBASE_API_KEY` | sim para login admin | Login via Identity Toolkit. |
| `APK_SCRIPT_PATH` | nao | Caminho do script de APK. |
| `APK_PROJECT_ROOT` | nao | Raiz do projeto para build. |
| `APK_OUTPUT_DIR` | nao | Saida dos APKs. |
| `APK_FLUTTER_PROJECT` | nao | Projeto Flutter alvo. |
| `PROXY_SGP_INTERNAL_URL` | nao | URL interna do `proxy-sgp`, default `http://backend-proxy:3002`. |

## Proxy SGP

| Variavel | Obrigatoria | Uso |
| --- | --- | --- |
| `PORT` | nao | Porta HTTP, default `3002`. |
| `DATABASE_URL` | sim em Docker | Postgres/cache. |
| `REDIS_URL` | nao | Redis/cache/rate limit, default local. |
| `PROXY_SECRET` | recomendado | Autorizacao server-to-server. |
| `PROXY_SECRET_KEY` | recomendado | Alias/compatibilidade do segredo. |
| `DEBUG_REQUESTS` | nao | Logs detalhados. |
| `ENABLE_DEV_CPF_MOCK` | nao | Mock de CPF em desenvolvimento. |
| `DEV_MOCK_CPF` | nao | CPF usado no mock. |
| `SGP_BASE_URL` | nao | Base SGP, default especifico atual. |
| `SGP_TOKEN` | sim para SGP | Token SGP. |
| `SGP_APP_NAME` | sim para SGP | App SGP. |

## Firebase Functions

Secrets/params:

| Nome | Tipo | Uso |
| --- | --- | --- |
| `PROXY_URL` | secret | URL do proxy usada por Functions. |
| `PROXY_SECRET` | secret | Segredo para proxy. |
| `APK_SCRIPT_PATH` | string param | Caminho do script APK. |
| `APK_PROJECT_ROOT` | string param | Raiz do projeto APK. |

Variaveis runtime lidas:

| Variavel | Uso |
| --- | --- |
| `GCLOUD_PROJECT` | Detectar project id. |
| `GCP_PROJECT` | Detectar project id. |
| `PROJECT_ID` | Detectar project id. |
| `STORAGE_BUCKET` | Bucket Storage. |
| `FIREBASE_STORAGE_BUCKET` | Bucket Storage. |

## APK builder

| Variavel | Obrigatoria | Uso |
| --- | --- | --- |
| `APK_BUILDER_PORT` | nao | Porta do servico, default `8035`. |
| `PORT` | nao | Fallback de porta. |
| `PYTHON_BIN` | nao | Python para executar script. |
| `APK_SCRIPT_PATH` | nao | Script de build. |
| `APK_PROJECT_ROOT` | nao | Raiz do projeto. |
| `APK_OUTPUT_DIR` | nao | Saida de builds. |
| `APK_FLUTTER_PROJECT` | nao | Projeto Flutter alvo. |
| `ANDROID_HOME` | recomendado | SDK Android. |
| `ANDROID_SDK_ROOT` | recomendado | SDK Android. |
| `PATH` | recomendado | Flutter/Android tooling. |

## Admin Next-like API legado

Arquivos em `admin-painel/pages/api/...` usam:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

Pendente:

- Confirmar se esses endpoints sao usados, pois o app principal e Vite e nao Next.

## Regras

- Variaveis sensiveis devem ficar em `.env`, secrets do Firebase ou `/home/app/.secrets`.
- Nunca commitar valores reais.
- Validar variaveis obrigatorias na inicializacao de cada servico.
- Documentar defaults usados localmente e em Docker.
