# Contrato: REST API

Atualizado em 2026-07-10 apos modularizacao do `api-service`.

## Base

- Container interno: `http://api-service:9136`
- Porta publica atual: `http://168.194.13.18:8034`
- Healthcheck: `GET /health`

O `api-service` e a fachada publica para o painel/app. O `proxy-sgp` permanece como
adaptador legado e cache; novos consumidores devem chamar a API publica.

## Estrutura

```text
api-service/src/
  app.ts
  server.ts
  config/env.ts
  middlewares/
  routes/
  services/
  validators/
```

## Endpoints

| Metodo | Rota | Auth | Responsabilidade |
| --- | --- | --- | --- |
| POST | `/admin/auth/login` | publica com rate limit | Login admin via Identity Toolkit |
| GET | `/admin/providers` | Firebase token | Lista provedores conforme claims |
| POST | `/admin/providers` | Firebase token | Cria/atualiza provedor sem salvar secrets publicos |
| GET | `/admin/tickets` | Firebase token | Lista tickets por permissao |
| GET | `/admin/tickets/:id/messages` | Firebase token | Lista mensagens do ticket |
| PATCH | `/admin/tickets/:id` | Firebase token | Atualiza status/assunto |
| POST | `/admin/tickets/:id/reply` | Firebase token | Adiciona resposta |
| GET | `/admin/users` | superAdmin | Lista usuarios administrativos |
| GET | `/admin/dashboard` | Firebase token | Indicadores globais ou do provedor |
| POST | `/admin/generate-apk` | superAdmin | Gera APK/AAB |
| POST | `/getClientData` | rate limit SGP | Consulta dados do cliente |
| POST | `/getConsumptionData` | rate limit SGP | Consulta consumo |
| POST | `/getInvoices` | rate limit SGP | Consulta faturas |
| POST | `/makePaymentPromise` | rate limit SGP | Promessa/desbloqueio |
| POST | `/diagnostic/onu-signal` | Firebase token | Fachada para ONU no proxy SGP |
| POST | `/diagnostic/traceroute` | Firebase token | Traceroute validado no servidor |
| POST | `/check-cpf` | publica com rate limit | Login CPF via proxy SGP |
| POST | `/get-invoices` | Firebase token | Fachada para faturas legadas |
| POST | `/get-consumption-data` | Firebase token | Fachada para consumo legado |
| POST | `/unlock-trust` | Firebase token | Fachada para desbloqueio |
| POST | `/cpe/wifi/list` | Firebase token | Fachada para Wi-Fi |
| POST | `/cpe/wifi/update` | Firebase token | Fachada para atualizar Wi-Fi |
| GET | `/health` | publico | Healthcheck |

## Envelope de erro

```json
{
  "error": {
    "message": "Mensagem exibivel",
    "code": "permission-denied",
    "correlationId": "uuid"
  }
}
```

Rotas de sucesso preservam o formato esperado por consumidores existentes:
algumas retornam `{ "data": ... }`, outras `{ "success": true }`.

## Proxy SGP

O proxy continua na porta interna `http://backend-proxy:3002` e publica atual
`http://168.194.13.18:8030`. A classificacao de rotas fica em
`proxy-sgp/contracts.js` e `docs/proxy-sgp-strategy.md`.

## Testes

- `api-service/src/app.test.ts`
- `api-service/src/validators/traceroute.test.ts`
- `proxy-sgp/contracts.test.js`
