# Contrato: Function Requests

Atualizado em 2026-07-10 apos a refatoracao da fila `function_requests`.

## Visao geral

O painel admin e o app Flutter enviam operacoes privilegiadas criando documentos em
`function_requests/{requestId}`. Uma unica Cloud Function, `handleFunctionRequest`,
roteia o pedido para handlers de dominio e grava a resposta em
`function_responses/{requestId}`.

Formato do request:

```ts
{
  type: FunctionRequestType;
  requesterUid: string;
  payload: FunctionRequestPayloadMap[FunctionRequestType];
  createdAt: serverTimestamp;
}
```

Formato da resposta:

```ts
{
  result?: unknown;
  error?: string;
  code?: ErrorCode;
  requesterUid: string;
  completedAt: serverTimestamp;
  expiresAt: Timestamp;
}
```

## Fonte canonica

- Contrato mestre: `shared/contracts/index.ts`.
- Copias sincronizadas:
  - `admin-painel/src/shared/contracts/index.ts`
  - `functions/src/contracts/index.ts`
  - `api-service/src/contracts/index.ts`
- Sincronizacao: `npm run contracts:sync`.
- Validacao: `npm run contracts:check`.

## Tipos ativos

Todos os tipos usados pelo painel/app possuem handler registrado em
`functions/src/handlers/index.ts`.

| Tipo | Handler | Permissao |
| --- | --- | --- |
| `UPDATE_PROVIDER_CONFIG` | `handlers/providers.ts` | superAdmin ou admin do provedor |
| `UPDATE_PROVIDER_DETAILS` | `handlers/providers.ts` | superAdmin ou admin do provedor |
| `CREATE_PROVIDER` | `handlers/providers.ts` | superAdmin |
| `DELETE_PROVIDER` | `handlers/providers.ts` | superAdmin |
| `GET_DASHBOARD_DATA` | `handlers/dashboard.ts` | superAdmin |
| `GET_PROVIDER_DASHBOARD_DATA` | `handlers/dashboard.ts` | superAdmin ou admin do provedor |
| `SEND_PUSH_NOTIFICATION` | `handlers/notifications.ts` | superAdmin ou admin do provedor |
| `SEND_SCOPED_NOTIFICATION` | `handlers/notifications.ts` | superAdmin ou admin do provedor |
| `SEND_SCOPED_NOTIFICATION_SEGMENTED` | `handlers/notifications.ts` | superAdmin ou admin do provedor |
| `SGP_API_PROXY` | `handlers/sgp.ts` | superAdmin ou admin do provedor |
| `GET_ALL_TICKETS` | `handlers/tickets.ts` | superAdmin |
| `GET_PROVIDER_TICKETS` | `handlers/tickets.ts` | superAdmin ou admin do provedor |
| `CREATE_TICKET` | `handlers/tickets.ts` | admin do provedor, superAdmin ou cliente vinculado |
| `REPLY_TO_TICKET` | `handlers/tickets.ts` | participante autorizado do ticket |
| `UPDATE_TICKET_STATUS` | `handlers/tickets.ts` | superAdmin ou admin do provedor |
| `DELETE_TICKET` | `handlers/tickets.ts` | superAdmin |
| `LIST_ADMIN_USERS` | `handlers/users.ts` | superAdmin |
| `CREATE_ADMIN_USER` | `handlers/users.ts` | superAdmin |
| `DELETE_ADMIN_USER` | `handlers/users.ts` | superAdmin |
| `SET_SUPER_ADMIN_BY_EMAIL` | `handlers/users.ts` | superAdmin |
| `LIST_PROVIDER_CLIENTS` | `handlers/clients.ts` | superAdmin ou admin do provedor |
| `GET_CLIENT_DETAILS` | `handlers/clients.ts` | superAdmin ou admin do provedor |
| `DELETE_CLIENT` | `handlers/clients.ts` | superAdmin ou admin do provedor |
| `BACKUP_PROVIDER_CONFIG` | `handlers/backups.ts` | superAdmin ou admin do provedor |
| `LIST_PROVIDER_BACKUPS` | `handlers/backups.ts` | superAdmin ou admin do provedor |
| `RESTORE_PROVIDER_CONFIG` | `handlers/backups.ts` | superAdmin ou admin do provedor |
| `DELETE_PROVIDER_BACKUP` | `handlers/backups.ts` | superAdmin ou admin do provedor |

## Regras implementadas

- `assertFunctionRequest` valida envelope, tipo e payload minimo.
- Requests legacy do app que enviam `payload.requesterUid` ainda sao normalizados.
- Requests duplicados nao reexecutam se ja existe `function_responses/{requestId}`.
- `function_responses` sempre recebe `completedAt` e `expiresAt`.
- Erros usam `code` previsivel: `unauthenticated`, `permission-denied`,
  `invalid-argument`, `not-found`, `conflict`, `internal` ou `timeout`.
- Auditoria vai para `audit_logs`, com redacao de chaves sensiveis.
- Documentos antigos da fila sao limpos por `cleanupFunctionDocuments`.

## Testes

- `functions/src/contracts.test.ts` valida nomes e payloads.
- `functions/src/handlers.test.ts` garante que todos os tipos possuem handler.
- `admin-painel/src/shared/api/functionRequests.ts` aplica timeout e cleanup de listener.
