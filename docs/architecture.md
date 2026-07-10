# Arquitetura do Sistema Unify

Atualizado em 2026-07-10.

## Visao geral

```text
Admin React/Vite
  -> shared/contracts
  -> shared/api/functionRequests
  -> Firestore function_requests
  -> Firebase Functions handleFunctionRequest
  -> Firestore/Admin SDK/Proxy SGP

App Flutter
  -> ProviderConfigNormalizer
  -> api-service para SGP/login/diagnosticos
  -> Firestore para config, tickets e notificacoes permitidas

api-service
  -> rotas Express modulares
  -> Firebase Admin para auth/dados
  -> proxy-sgp para cache/rotas SGP legadas

proxy-sgp
  -> Postgres/Redis/cache
  -> SGP externo
```

## Camadas

- `shared/contracts`: nomes de requests, payloads, resultados e modelos comuns.
- `admin-painel/src/shared`: infraestrutura de API/Firebase.
- `admin-painel/src/features`: services e regras de dominio.
- `functions/src/app`: router, permissao, auditoria, erros e resposta.
- `functions/src/handlers`: dominios de provedores, tickets, usuarios, SGP,
  clientes, backups, dashboards e notificacoes.
- `api-service/src/routes`: fronteira HTTP.
- `api-service/src/services`: Firebase Admin, SGP, proxy, APK e auditoria.
- `app-flutter/unified/lib/core/models`: normalizacao de config remota no app
  movel canonico.

## Dados sensiveis

Tokens SGP e credenciais ficam em:

- `provedores/{providerId}/secrets/sgp`
- Firebase secrets/params
- variaveis de ambiente do host

Esses dados nao devem ser escritos em `provedores/{providerId}` nem em logs.

## Decisoes

- `function_requests` continua como fronteira para operacoes privilegiadas do
  painel/app porque preserva compatibilidade e regras existentes.
- O `api-service` e a fachada publica para HTTP.
- O `proxy-sgp` nao foi removido; ele permanece dono do cache e das rotas SGP
  ainda especificas.
- O schema `ProviderConfig` segue compativel com campos atuais e legados.
