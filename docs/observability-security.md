# Observabilidade e seguranca

Atualizado em 2026-07-10.

## Observabilidade

- `function_requests` registra inicio, sucesso e falha com `requestId`, `type`,
  `providerId` e `requesterUid`.
- `api-service` gera `x-correlation-id` por request e devolve o ID no envelope
  de erro.
- Jobs agendados gravam `maintenance_logs`.
- Acoes criticas gravam `audit_logs`.

## Auditoria

Eventos auditados:

- criacao/alteracao/exclusao de provedor;
- alteracao de configuracao;
- criacao/exclusao/promocao de admin;
- tickets e respostas;
- notificacoes;
- backup/restore;
- geracao de APK.

Payloads sao redigidos para chaves sensiveis como `password`, `senha`, `token`,
`apiToken`, `authorization`, `secret`, `privateKey` e equivalentes.

## Regras

- Firestore: `firestore.rules`.
- Storage: `storage.rules`.
- Testes: `npm run test:rules`.
- Secrets de integracao SGP ficam em `provedores/{providerId}/secrets/sgp`.
- Ticket attachments ficam privados em `providers/{providerId}/ticket_attachments`.

## Validacoes

- `npm run security:secrets` faz varredura basica de secrets versionados.
- `npm run security:audit` valida dependencias de producao e desenvolvimento em
  todos os pacotes Node.
- Overrides transitivos corrigem as cadeias `uuid`, `ts-deepmerge` e
  `@opentelemetry/core`; a auditoria atual retorna zero vulnerabilidades.
