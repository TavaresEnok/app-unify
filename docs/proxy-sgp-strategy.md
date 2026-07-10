# Estratégia do proxy SGP

## Decisão

O `proxy-sgp` permanece como adaptador legado e dono do cache Postgres/Redis. O `api-service` é a fachada pública única do aplicativo e encaminha apenas as operações que ainda dependem do proxy.

Novos consumidores não devem chamar a porta `8030`. A API pública continua na porta `8034`.

## Responsabilidades mantidas no proxy

- Sincronização paginada do SGP.
- Cache de clientes em Postgres e Redis.
- Compatibilidade temporária dos diagnósticos especializados.
- Operações CPE/Wi-Fi continuam executadas no proxy, mas expostas pela fachada do `api-service`.

## Responsabilidades da API service

- Autenticação e autorização pública.
- Rate limit e correlação de requisições.
- Fachada para login por CPF, faturas, consumo, desbloqueio, ONU e Wi-Fi.
- Normalização das respostas e dos erros.
- Novos consumidores devem apontar para `api-service`; a porta `8030` fica como compatibilidade.

## Deprecações

`/build-apk` no proxy é legado. Novos builds usam `api-service /admin/generate-apk`, Firebase callable ou o serviço dedicado `apk-builder`.

O inventário executável fica em `proxy-sgp/contracts.js`; o teste de contrato confirma que as rotas classificadas continuam presentes.
