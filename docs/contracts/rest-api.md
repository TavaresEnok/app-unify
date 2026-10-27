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
| POST | `/getClientData` | Firebase token + rate limit SGP | Dados do contrato `contratoId` (ou do primeiro), `totalAberto` e lista `contratos` |
| POST | `/getConsumptionData` | Firebase token + rate limit SGP | Consumo somado de todos os contratos (ou de `contratoId`), com `contratos` por item |
| POST | `/getInvoices` | Firebase token + rate limit SGP | Faturas de todos os contratos (ou de `contratoId`) |
| POST | `/makePaymentPromise` | Firebase token + rate limit SGP | Promessa em `contratoId` ou em todos os contratos com débito; `resultados` por contrato |
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

### Rotas de assinante do api-service (`/getClientData`, `/getConsumptionData`, `/getInvoices`, `/makePaymentPromise`)

- Corpo: `cpfCnpj` (obrigatório), `contratoId` (opcional) e, só para superAdmin, `providerId`.
- O SGP consultado é o do provedor dono do CPF: claim `providerId` do token do assinante, ou `clientes/{cpf}.providerId`. As credenciais vêm de `provedores/{id}/secrets/sgp`. Se o provedor existe mas não tem integração, a resposta é 503 (sem cair no SGP global do `.env`). O `.env` só é usado para assinantes legados sem provedor identificado.
- providerAdmin só acessa CPFs do próprio provedor; assinante só o próprio CPF.
- A URL do SGP é validada contra SSRF com resolução de DNS (IPv4 e IPv6).
