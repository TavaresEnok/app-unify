# Contrato: Firestore Schema

Inventario inicial criado em 2026-07-10.

Este documento registra collections usadas pelo painel, Functions e app. O schema ainda e parcialmente legacy e deve ser normalizado em fases.

## Collections principais

### `provedores/{providerId}`

Usado por:

- Painel admin.
- App Flutter.
- Functions.

Campos observados/relevantes:

- `name`
- `active`
- `createdAt`
- `updatedAt`
- `logoUrl`
- `details`
- `config`
- `themeColor`
- `secondaryColor`
- `textColor`
- `invoiceColor`
- `actionColor`
- `cardColor`
- `cardTextColor`
- `layoutType`
- `diagnosticStyle`
- `features`
- `menuConfig`
- `socialNetworks`
- `integrations` legado/publico em alguns fluxos
- `strings`
- `typography`
- `imageCarousel`
- `faq`
- `messages`
- `promotions`
- `notifications`
- `dashboardConfig`

Risco:

- Ha duplicacao entre campos na raiz e objeto `config`.
- Algumas Functions fazem espelhamento para compatibilidade.
- `SettingsContext` tenta remover `integrations` do documento publico e salvar em secret.

### `provedores/{providerId}/secrets/sgp`

Usado por:

- `SettingsContext`
- Integracoes SGP no painel.

Campos observados:

- `integrations`
- `integrations.apiToken`
- `integrations.appName`

Regra:

- Deve ser tratado como sensivel.
- Nao deve ser exposto no app cliente.

### `provedores/{providerId}/clientes`

Usado por:

- Functions SGP/cache.
- Provider clients no painel.
- App/servicos de cliente.

Campos provaveis:

- CPF/CNPJ ou identificador normalizado.
- Dados retornados do SGP.
- Contratos associados.
- Dados cacheados de consulta.

Pendente:

- Definir schema minimo real apos amostragem segura em ambiente controlado.

### `provedores/{providerId}/users`

Usado por:

- Functions de contagem/dashboard.
- Possivel vinculo provider admin/cliente.

Pendente:

- Confirmar campos e consumidores ativos.

### `provedores/{providerId}/diagnostic_results`

Usado por:

- `DiagnosticHistoryPage`
- App Flutter `test_history_service.dart`

Campos provaveis:

- resultado de diagnostico
- data
- cliente
- metricas de rede

Pendente:

- Documentar formato final antes de refatorar diagnosticos.

### `tickets/{ticketId}`

Usado por:

- Painel admin.
- Painel provedor.
- App Flutter suporte.
- API service.
- Functions.

Campos observados/provaveis:

- `providerId`
- `clientId`
- `clientName`
- `subject`
- `status`
- `priority`
- `createdAt`
- `updatedAt`
- `lastMessage`

Subcollection:

- `tickets/{ticketId}/messages`

### `tickets/{ticketId}/messages/{messageId}`

Campos observados/provaveis:

- `text`
- `senderId`
- `senderName`
- `senderRole`
- `createdAt`

### `users/{userId}`

Usado por:

- Listagem de admins.
- Dashboard.
- Permissoes/claims complementares.

Campos provaveis:

- `email`
- `name`
- `role`
- `providerId`
- `createdAt`
- `active`

### `clientes/{cpfCnpj}`

Usado por:

- App Flutter auth repository.
- Functions em fluxos de cliente.

Risco:

- Existe tambem `provedores/{providerId}/clientes`; e necessario definir relacao e fonte canonica.

### `notifications/{notificationId}`

Usado por:

- Functions de envio.
- App Flutter notification service.
- Dashboard.

Campos provaveis:

- `providerId`
- `title`
- `message`
- `scope`
- `createdAt`
- `sentBy`
- `target`

### `function_requests/{requestId}`

Contrato documentado em `function-requests.md`.

### `function_responses/{requestId}`

Contrato documentado em `function-requests.md`.

## Regras de migracao recomendadas

1. Definir schema canonico de `ProviderConfig`.
2. Manter leitura legacy na raiz e em `config`.
3. Passar a escrever no formato canonico.
4. Rodar script de preenchimento de campos ausentes.
5. Apenas em fase futura remover duplicacao.

## Campos sensiveis

Nunca devem ficar em documento publico:

- tokens SGP
- senhas
- `authorization`
- secrets
- dados de service account
- chaves privadas

O sanitizador em Functions ja remove chaves sensiveis de contratos SGP; esta regra deve virar helper compartilhado.
