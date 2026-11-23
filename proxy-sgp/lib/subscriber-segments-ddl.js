'use strict';

// Fonte única de verdade para o schema da tabela `subscriber_segments`,
// sincronizada para `proxy-sgp/lib/` e `api-service/src/services/`.
const SUBSCRIBER_SEGMENTS_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS subscriber_segments (
    provider_id TEXT NOT NULL,
    cpfcnpj TEXT NOT NULL,
    contrato_id TEXT NOT NULL DEFAULT '',
    client_name TEXT NOT NULL DEFAULT '',
    contract_status TEXT NOT NULL DEFAULT '',
    plano TEXT NOT NULL DEFAULT '',
    cidade TEXT NOT NULL DEFAULT '',
    bairro TEXT NOT NULL DEFAULT '',
    pop_id TEXT NOT NULL DEFAULT '',
    olt_id TEXT NOT NULL DEFAULT '',
    olt_name TEXT NOT NULL DEFAULT '',
    slot TEXT NOT NULL DEFAULT '',
    pon TEXT NOT NULL DEFAULT '',
    cto TEXT NOT NULL DEFAULT '',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (provider_id, cpfcnpj, contrato_id)
  )
`;

const SUBSCRIBER_SEGMENTS_INDEXES_SQL = [
  'CREATE INDEX IF NOT EXISTS idx_segments_provider_olt ON subscriber_segments (provider_id, olt_name)',
  'CREATE INDEX IF NOT EXISTS idx_segments_provider_pon ON subscriber_segments (provider_id, olt_name, slot, pon)',
  'CREATE INDEX IF NOT EXISTS idx_segments_provider_cto ON subscriber_segments (provider_id, cto)',
  'CREATE INDEX IF NOT EXISTS idx_segments_provider_geo ON subscriber_segments (provider_id, cidade, bairro)',
  'CREATE INDEX IF NOT EXISTS idx_segments_provider_status ON subscriber_segments (provider_id, contract_status)',
  'CREATE INDEX IF NOT EXISTS idx_segments_provider_plano ON subscriber_segments (provider_id, plano)',
  'CREATE INDEX IF NOT EXISTS idx_segments_provider_pop ON subscriber_segments (provider_id, pop_id)',
];

module.exports = {
  SUBSCRIBER_SEGMENTS_TABLE_SQL,
  SUBSCRIBER_SEGMENTS_INDEXES_SQL,
};
