# Contrato: REST API

Inventario inicial criado em 2026-07-10.

## API service (`api-service`)

Base em Docker:

- Interno/container: `http://api-service:9136`
- Host atual: `http://168.194.13.18:8034`

Endpoints encontrados em `api-service/src/index.ts`:

| Metodo | Rota | Auth | Responsabilidade |
| --- | --- | --- | --- |
| POST | `/admin/auth/login` | login limiter | Login admin via Firebase Identity Toolkit. |
| GET | `/admin/providers` | Firebase token | Lista provedores conforme claim. |
| POST | `/admin/providers` | Firebase token | Cria/atualiza provedor. |
| GET | `/admin/tickets` | Firebase token | Lista tickets. |
| GET | `/admin/tickets/:id/messages` | Firebase token | Lista mensagens de um ticket. |
| PATCH | `/admin/tickets/:id` | Firebase token | Atualiza ticket. |
| POST | `/admin/tickets/:id/reply` | Firebase token | Adiciona resposta ao ticket. |
| GET | `/admin/users` | Firebase token | Lista usuarios/admins. |
| GET | `/admin/dashboard` | Firebase token | Dados de dashboard. |
| POST | `/getClientData` | SGP limiter | Consulta dados de cliente. |
| POST | `/getConsumptionData` | SGP limiter | Consulta consumo. |
| POST | `/getInvoices` | SGP limiter | Consulta faturas. |
| POST | `/makePaymentPromise` | SGP limiter | Promessa de pagamento. |
| POST | `/diagnostic/onu-signal` | SGP limiter | Diagnostico de ONU. |
| POST | `/diagnostic/traceroute` | traceroute limiter | Diagnostico de rota. |
| POST | `/cpe/wifi/list` | nenhum identificado | Stub/lista CPE Wi-Fi. |
| POST | `/admin/generate-apk` | super admin | Gera APK via script. |
| POST | `/check-cpf` | SGP limiter | Proxy para `proxy-sgp`. |
| POST | `/get-invoices` | SGP limiter | Proxy para `proxy-sgp`. |
| POST | `/get-consumption-data` | SGP limiter | Proxy para `proxy-sgp`. |
| POST | `/unlock-trust` | SGP limiter | Proxy para `proxy-sgp`. |
| POST | `/cpe/wifi/update` | SGP limiter | Proxy para `proxy-sgp`. |
| GET | `/health` | publico | Healthcheck. |

## Proxy SGP (`proxy-sgp`)

Base em Docker:

- Interno/container: `http://backend-proxy:3002`
- Host atual: `http://168.194.13.18:8030`

Endpoints encontrados em `proxy-sgp/index.js`:

| Metodo | Rota | Auth | Responsabilidade |
| --- | --- | --- | --- |
| POST | `/get-consumption-data` | Firebase token | Consumo SGP/cache. |
| POST | `/sync-clients` | segredo/proxy | Sincroniza clientes. |
| POST | `/get-cached-clients` | segredo/proxy | Lista clientes cacheados. |
| POST | `/get-single-client` | segredo/proxy | Cliente unico cacheado. |
| POST | `/check-cpf` | publico/SGP | Valida CPF/login. |
| POST | `/get-client-data-for-login` | publico/SGP | Dados para login. |
| POST | `/diagnostic/onu-signal` | Firebase token | Diagnostico ONU. |
| POST | `/diagnostic/onu-signal-base` | Firebase token | Diagnostico ONU base. |
| POST | `/diagnostic/analyze` | Firebase token | Analise diagnostica. |
| POST | `/cpe/wifi/list` | Firebase token | Lista Wi-Fi/CPE. |
| POST | `/cpe/wifi/update` | Firebase token | Atualiza Wi-Fi/CPE. |
| POST | `/get-invoices` | Firebase token | Faturas. |
| POST | `/unlock-trust` | Firebase token | Desbloqueio de confianca. |
| POST | `/build-apk` | nao consolidado | Build APK legado. |
| GET | `/health` | publico | Healthcheck. |

## APK builder

Base em Docker:

- Host atual: `http://168.194.13.18:8035`

Endpoints encontrados em `apk-builder-service.js`:

| Metodo | Rota | Auth | Responsabilidade |
| --- | --- | --- | --- |
| POST | `/generate-apk` | super admin | Gera APK/AAB do app. |
| GET | `/health` | publico | Healthcheck. |

## Decisoes pendentes

1. Definir se `api-service` sera a facade publica unica para SGP.
2. Decidir quais endpoints do `proxy-sgp` serao mantidos ou migrados.
3. Padronizar envelope de resposta REST:

```json
{
  "data": {},
  "error": null
}
```

ou:

```json
{
  "success": true,
  "data": {}
}
```

4. Padronizar erros com `code`, `message` e `details`.
5. Documentar auth exigida por endpoint com claims.
