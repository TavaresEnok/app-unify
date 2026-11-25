'use strict';

// Fonte única de verdade para o schema core self-hosted no PostgreSQL,
// sincronizada para `proxy-sgp/lib/` e `api-service/src/services/`.
const CORE_SCHEMA_STATEMENTS = [
  `CREATE TABLE IF NOT EXISTS providers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )`,

  `CREATE TABLE IF NOT EXISTS provider_secrets (
    provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    kind TEXT NOT NULL,
    ciphertext TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (provider_id, kind)
  )`,

  `CREATE TABLE IF NOT EXISTS provider_backups (
    id TEXT PRIMARY KEY,
    provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    label TEXT NOT NULL DEFAULT '',
    created_by TEXT NOT NULL DEFAULT '',
    snapshot JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )`,
  `CREATE INDEX IF NOT EXISTS idx_provider_backups_provider_created ON provider_backups (provider_id, created_at DESC)`,

  `CREATE TABLE IF NOT EXISTS admin_users (
    uid TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('superAdmin', 'providerAdmin')),
    provider_id TEXT,
    disabled BOOLEAN NOT NULL DEFAULT FALSE,
    token_version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )`,

  `CREATE TABLE IF NOT EXISTS subscribers (
    uid TEXT PRIMARY KEY,
    provider_id TEXT NOT NULL,
    cpfcnpj TEXT NOT NULL,
    nome TEXT NOT NULL DEFAULT '',
    plano TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT '',
    contract_status TEXT NOT NULL DEFAULT '',
    contrato_id TEXT NOT NULL DEFAULT '',
    email TEXT NOT NULL DEFAULT '',
    disabled BOOLEAN NOT NULL DEFAULT FALSE,
    token_version INTEGER NOT NULL DEFAULT 1,
    last_login_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )`,
  `CREATE INDEX IF NOT EXISTS idx_subscribers_provider_cpf ON subscribers (provider_id, cpfcnpj)`,

  `CREATE TABLE IF NOT EXISTS incidents (
    id TEXT PRIMARY KEY,
    provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    area TEXT,
    severity TEXT NOT NULL DEFAULT 'warning',
    estimated_resolution TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
  )`,
  `CREATE INDEX IF NOT EXISTS idx_incidents_provider_active_created ON incidents (provider_id, active, created_at DESC)`,

  `CREATE TABLE IF NOT EXISTS tickets (
    id TEXT PRIMARY KEY,
    provider_id TEXT NOT NULL,
    provider_name TEXT NOT NULL DEFAULT '',
    subject TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Aberto',
    created_by_uid TEXT NOT NULL,
    created_by_email TEXT NOT NULL DEFAULT '',
    cpfcnpj TEXT NOT NULL DEFAULT '',
    last_message TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )`,
  `CREATE INDEX IF NOT EXISTS idx_tickets_provider_updated ON tickets (provider_id, updated_at DESC)`,
  `CREATE INDEX IF NOT EXISTS idx_tickets_creator_updated ON tickets (created_by_uid, updated_at DESC)`,

  `CREATE TABLE IF NOT EXISTS ticket_messages (
    id TEXT PRIMARY KEY,
    ticket_id TEXT NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    sender_uid TEXT NOT NULL,
    sender_email TEXT NOT NULL DEFAULT '',
    sender_role TEXT NOT NULL DEFAULT 'subscriber',
    message TEXT NOT NULL DEFAULT '',
    attachment_id TEXT,
    image_url TEXT,
    read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )`,
  `CREATE INDEX IF NOT EXISTS idx_ticket_messages_ticket_created ON ticket_messages (ticket_id, created_at ASC)`,

  `CREATE TABLE IF NOT EXISTS private_attachments (
    id TEXT PRIMARY KEY,
    resource_kind TEXT NOT NULL,
    resource_id TEXT NOT NULL,
    attachment_id TEXT NOT NULL,
    provider_id TEXT NOT NULL,
    owner_uid TEXT NOT NULL,
    rel_path TEXT NOT NULL,
    checksum TEXT NOT NULL,
    size_bytes INTEGER NOT NULL,
    mime TEXT NOT NULL,
    state TEXT NOT NULL DEFAULT 'committed',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (resource_kind, resource_id, attachment_id)
  )`,

  `CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    type TEXT NOT NULL,
    requester_uid TEXT NOT NULL,
    provider_id TEXT,
    correlation_id TEXT,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    source TEXT NOT NULL DEFAULT 'api-service',
    outcome TEXT NOT NULL DEFAULT 'success',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  )`,
  `CREATE INDEX IF NOT EXISTS idx_audit_logs_provider_created ON audit_logs (provider_id, created_at DESC)`,

  `DO $$
  BEGIN
    IF to_regclass('public.diagnostic_results') IS NOT NULL THEN
      ALTER TABLE diagnostic_results ADD COLUMN IF NOT EXISTS created_by_uid TEXT NOT NULL DEFAULT '';
      ALTER TABLE diagnostic_results ADD COLUMN IF NOT EXISTS report_attachment_id TEXT;
    END IF;
  END $$`,
];

module.exports = {
  CORE_SCHEMA_STATEMENTS,
};
