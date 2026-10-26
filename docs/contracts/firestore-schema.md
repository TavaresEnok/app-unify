# Contrato: Firestore Schema

Atualizado em 2026-07-10 apos revisao de regras, Functions e app Flutter.

## `provedores/{providerId}`

Documento publico usado para carregar tema, layout, app white-label e dados
basicos do provedor.

Campos principais:

- `name`, `active`, `createdAt`, `updatedAt`
- `layoutType`, `diagnosticStyle`
- cores: `themeColor`, `secondaryColor`, `backgroundColor`, `cardColor`,
  `textColor`, `actionColor`, `invoiceColor`
- assets: `logoUrl`, `iconUrl`, `backgroundUrl`
- conteudo: `menuConfig`, `imageCarousel`, `dashboardConfig`, `promotions`,
  `notifications`, `faq`, `tips`, `messages`, `strings`, `termsOfUse`
- configuracao: `features`, `supportContacts`, `supportChannels`,
  `social`, `socialNetworks`, `other`, `appVersion`
- legado: `config`, `dashboard`

Regra importante: `integrations` e `config.integrations` nao devem ficar no
documento publico. As regras bloqueiam escrita publica desses campos.

## `provedores/{providerId}/secrets/sgp`

Documento sensivel restrito a superAdmin/admin do provedor.

Campos:

- `integrations.apiToken`
- `integrations.appName`
- `integrations.sgpBaseUrl`

## `provedores/{providerId}/backups/{backupId}`

Backups criados por Function.

Campos:

- `name`
- `providerData`
- `secrets`
- `createdBy`
- `createdAt`

## `provedores/{providerId}/migration_backups/{backupId}`

Backups tecnicos do script `scripts/migrations/migrate-provider-config.mjs`.
Usado para rollback pontual de migracao de schema.

## `provedores/{providerId}/clientes/{clientId}`

Cache de clientes sincronizados do SGP para operacao administrativa.

Campos principais:

- `providerId`
- `nome`
- `cpfcnpj`/`cpfCnpj`
- `status`
- `plano`
- `contratos` sanitizados
- `updatedAt`

## `clientes/{authUid}`

Documento global do assinante autenticado no app.

Campos permitidos pelo proprio cliente:

- `authUid`
- `cpfCnpj`
- `providerId`
- `fcmToken`
- `nome`
- `plano`
- `status`
- `lastUpdated`

O ID canonico e o UID do Firebase Auth. Fluxos antigos por CPF sao tratados por
fallback de consulta quando necessario.

## `tickets/{ticketId}` e `tickets/{ticketId}/messages/{messageId}`

Criados e alterados pelas Functions.

Campos do ticket:

- `subject`
- `status`: `Aberto`, `Em Andamento`, `Fechado`
- `providerId`, `providerName`
- `userEmail`
- `createdByUid`
- `createdAt`, `updatedAt`

Campos da mensagem:

- `message`
- `senderUid`, `senderEmail`, `senderRole`
- `imageUrl`
- `createdAt`

## `notifications/{notificationId}`

Criadas pelas Functions de envio de notificacao.

Campos:

- `providerId`
- `title`, `body`
- `category`
- filtros/escopo
- contadores `successCount`, `failureCount`
- `sentBy`, `createdAt`

Leitura e escopada por superAdmin, admin do provedor ou cliente do provedor.

## `function_requests` e `function_responses`

Contratos descritos em `docs/contracts/function-requests.md`.

## `users/{userId}`

Metadados auxiliares de usuarios administrativos.
Leitura restrita a superAdmin; escrita via Functions/Admin SDK.

## `audit_logs/{auditId}`

Trilha de auditoria de acoes criticas.
Leitura restrita a superAdmin; escrita via Functions/API Admin SDK.

## `maintenance_logs/{logId}`

Logs de jobs agendados, como limpeza da fila.
Leitura restrita a superAdmin.

## Regras e indices

- Regras: `firestore.rules`
- Storage: `storage.rules`
- Indices: `firestore.indexes.json`
- Testes: `tests/firestore-rules.test.mjs`
