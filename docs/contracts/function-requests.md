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

## Atualização de capacidade (2026-10-29)

- `LIST_PROVIDER_CLIENTS`: aceita `limit` (máximo 50), `cursor` e `search`; retorna `{items,total,nextCursor}`.
- `SGP_API_PROXY/get`: usa `params.cursor`; `paginacao.nextCursor` substitui o avanço por offset no painel.
- `SGP_API_PROXY/sync`: agenda e retorna `jobId`; `action=status` com `params.jobId` consulta progresso, `completed` ou `failed`.
- Administradores exigem `role=providerAdmin`; `providerId` isolado não concede administração.
- Respostas acima de 700 KB são rejeitadas antes da gravação. Requisições, respostas e locks antigos têm limpeza agendada.
# Atualização F1 C1/E4 — origem verificável da sessão (31/10/2026)

O envelope web exige `session: {authTime, issuedAt, role, providerId, superAdmin}`,
derivado de `getIdTokenResult()` Firebase. `authTime`/`issuedAt` são segundos de
`auth_time`/`iat`; scope ausente usa strings vazias e superAdmin=false.
Rules vinculam esses campos ao token autenticado, requesterUid ao próprio UID e
createdAt ao timestamp de servidor. Payload não fornece prova de identidade.
Router usa a fonte canônica imutável, Auth atual/disabled/tokensValidAfterTime e
scope corrente antes do handler e em retomadas. Sessão ausente, revogada ou com
scope alterado é negada sem efeito. Falha de autoridade: authorization-unavailable,
sem repetição automática de mutação. C8/unknown/fencing continuam obrigatórios.
Flutter/admin_app/SDKs antigos precisam atualização ou retirada antes de publicar;
nenhuma exceção insegura para envelope legado. Rules em emulador continuam gate.

## Gate de proveniência de criação (correção F1-SERVER-R1)

`RPC_SESSION_RULES_ACTIVE_AFTER` é configuração exclusiva do servidor, em UTC
ISO estrito (`YYYY-MM-DDTHH:mm:ss.sssZ`). Operação só pode defini-la para um
instante posterior à confirmação de que as Rules que vinculam a sessão estão
ativas. Sem corte válido já alcançado, a fila falha fechada. O lease exige
`DocumentSnapshot.createTime > corte` e `createTime <= agora`; não usa `createdAt`,
`updateTime`, campos de payload ou timestamps declarados de sessão para essa prova.
O mesmo gate vale para entrega e recuperação agendada. Documento anterior é
negado mesmo contendo sessão sintaticamente válida e posterior à revogação.
Lock prévio sem prova mantém `unknown`, sem repetição de efeitos.

Configurar corte retroativo, reabrir Rules antigas ou importar documentos legados
com novos createTimes invalida a prova: bloquear a fila e escolher novo corte após
restaurar/verificar Rules estritas. Backup não autoriza reenfileirar comandos antigos.

O roteador distingue falha de autoridade no primeiro lookup do handler real,
cujo prólogo é anterior a qualquer efeito, usando contexto interno por execução.
O marcador não vem do documento nem do cliente. Só essa falha comprovada preserva
`authorization-unavailable`; checagens posteriores sem prova de ausência de efeito
continuam conservadoramente `unknown` em mutações. Não há retry automático.
