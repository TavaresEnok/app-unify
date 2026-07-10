# Contrato: Function Requests

Inventario inicial criado em 2026-07-10 para a refatoracao completa.

O painel e o app usam o padrao:

- Criar documento em `function_requests/{requestId}`.
- Aguardar documento em `function_responses/{requestId}`.
- Usar `requesterUid`, `payload` e `createdAt`.

## Formato base atual

```ts
{
  type: string;
  createdAt: serverTimestamp;
  requesterUid: string;
  payload: Record<string, unknown>;
}
```

Resposta esperada:

```ts
{
  result?: unknown;
  error?: string;
  requesterUid?: string | null;
  completedAt: serverTimestamp;
}
```

## Handlers encontrados em `functions/src/index.ts`

| Tipo | Status | Consumidores identificados | Observacoes |
| --- | --- | --- | --- |
| `UPDATE_PROVIDER_CONFIG` | ativo | `ProviderDetailPage` | Atualiza/cria provedor, espelha dados na raiz e em `config`. |
| `UPDATE_PROVIDER_DETAILS` | ativo | `MyCompanyPage`, `EditProviderDialog` | Atualiza detalhes do provedor. |
| `GET_DASHBOARD_DATA` | ativo | `useApi` | Handler existe, mas parte do dashboard atual tambem consulta Firestore direto. |
| `DELETE_PROVIDER` | ativo | `ProvidersPage` | Remove provedor e dados relacionados. |
| `SEND_PUSH_NOTIFICATION` | ativo | `NotificationsManager` | Usado na area de configuracoes/notificacoes. |
| `SEND_SCOPED_NOTIFICATION_SEGMENTED` | ativo | `NotificationSenderPage` | Envio segmentado por escopo. |
| `GET_PROVIDER_DASHBOARD_DATA` | ativo | `ProviderDashboardPage` | Dashboard do provedor. |
| `SGP_API_PROXY` | ativo | `ProviderClientsPage`, `ClientDetailPage` | Faz proxy para integracao SGP/cache. |
| `GET_ALL_TICKETS` | ativo | `AdminTicketsPage` | Lista tickets para super admin. |
| `GET_PROVIDER_TICKETS` | ativo | `useApi` declarado | Handler existe; algumas telas tambem consultam Firestore direto. |
| `DELETE_TICKET` | ativo | `AdminTicketsPage` | Exclui ticket. |
| `LIST_ADMIN_USERS` | ativo | `UsersPage` | Lista admins. |
| `DELETE_ADMIN_USER` | ativo | `UsersPage` | Remove admin. |

## Tipos usados no front/app sem handler encontrado

Estes tipos aparecem em `admin-painel/src` ou `lib/`, mas nao apareceram como handler em `functions/src/index.ts` nem em `functions/lib/index.js` durante a auditoria inicial.

| Tipo | Onde aparece | Risco |
| --- | --- | --- |
| `CREATE_PROVIDER` | `AddProviderDialog` | Criacao via dialog pode ficar sem resposta se nao existir outro fluxo. |
| `CREATE_ADMIN_USER` | `AddAdminDialog` | Criacao de admin pode ficar sem resposta. |
| `SET_SUPER_ADMIN_BY_EMAIL` | `SetSuperAdminDialog` | Promocao de super admin pode ficar sem resposta. |
| `CREATE_TICKET` | `AddTicketDialog`, app Flutter `suporte_service.dart` | Abertura de ticket pode depender de handler ausente. |
| `REPLY_TO_TICKET` | `TicketDetailPage` | Resposta ao ticket pode ficar sem resposta. |
| `UPDATE_TICKET_STATUS` | `TicketDetailPage` | Atualizacao de status pode ficar sem resposta. |
| `DELETE_CLIENT` | `ClientDetailPage` | Exclusao de cliente pode ficar sem resposta. |
| `LIST_PROVIDER_CLIENTS` | `useApi` | Declarado, mas nao identificado como consumidor ativo direto. |
| `GET_CLIENT_DETAILS` | `useApi` | Declarado, mas nao identificado como consumidor ativo direto. |
| `BACKUP_PROVIDER_CONFIG` | `BackupSettings` | Backup pode ficar sem resposta. |
| `LIST_PROVIDER_BACKUPS` | `BackupSettings` | Listagem de backups pode ficar sem resposta. |
| `RESTORE_PROVIDER_CONFIG` | `BackupSettings` | Restore pode ficar sem resposta. |
| `DELETE_PROVIDER_BACKUP` | `BackupSettings` | Exclusao de backup pode ficar sem resposta. |
| `SEND_SCOPED_NOTIFICATION` | `useApi` | Declarado, sem consumidor ativo identificado. |

## Decisao para a refatoracao

Antes de mover ou dividir `functions/src/index.ts`, executar uma das acoes para cada tipo sem handler:

1. Implementar handler compativel.
2. Remover chamada se for tela/fluxo legado nao usado.
3. Redirecionar para REST API existente.
4. Marcar como legado e esconder UI ate existir backend.

Nao iniciar uma modularizacao grande de Functions enquanto esta tabela nao estiver resolvida, porque a refatoracao pode mascarar falhas ja existentes.

## Regras de contrato desejadas

- Todo `type` deve existir em uma lista unica compartilhada.
- Todo payload deve ter tipo e validador runtime.
- Todo handler deve responder em `function_responses/{requestId}` em sucesso e erro.
- Todo erro deve ser string exibivel e, idealmente, ter codigo interno.
- Toda operacao deve validar `requesterUid` e claims.
- Requests de provider admin devem ignorar `providerId` arbitrario vindo do cliente e usar claim quando aplicavel.
