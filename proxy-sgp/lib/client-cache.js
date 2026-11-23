'use strict';
const {
    SUBSCRIBER_SEGMENTS_TABLE_SQL,
    SUBSCRIBER_SEGMENTS_INDEXES_SQL,
} = require('./subscriber-segments-ddl');
let ready;
let segmentsReady;
function ensureClientCache(pool) {
    if (!ready) ready = pool.query(`CREATE TABLE IF NOT EXISTS sgp_clients (
        provider_id TEXT NOT NULL, client_id TEXT NOT NULL, nome TEXT NOT NULL DEFAULT '',
        cpfcnpj TEXT NOT NULL, contratos JSONB NOT NULL DEFAULT '[]',
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY(provider_id, client_id)
    )`)
        .then(() => pool.query('ALTER TABLE sgp_clients ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()'))
        .then(() => pool.query('CREATE INDEX IF NOT EXISTS sgp_clients_name ON sgp_clients(provider_id,nome,client_id)'))
        .then(() => pool.query('CREATE INDEX IF NOT EXISTS sgp_clients_cpf ON sgp_clients(provider_id,cpfcnpj)'))
        .catch(error => { ready = null; throw error; });
    return ready;
}

function ensureSegmentTable(pool) {
    if (!segmentsReady) {
        segmentsReady = (async () => {
            await pool.query(SUBSCRIBER_SEGMENTS_TABLE_SQL);
            for (const idxSql of SUBSCRIBER_SEGMENTS_INDEXES_SQL) {
                await pool.query(idxSql);
            }
        })().catch(error => { segmentsReady = null; throw error; });
    }
    return segmentsReady;
}

function extractSegmentRows(providerId, clients) {
    const map = new Map();
    for (const item of clients) {
        const cpf = String(item.cpf || '').replace(/\D/g, '');
        if (!cpf) continue;
        const contratos = Array.isArray(item.contratos) && item.contratos.length ? item.contratos : [{}];
        for (const c of contratos) {
            const contratoId = String(c?.id ?? c?.contratoId ?? '');
            const servicos = Array.isArray(c?.servicos) ? c.servicos : [];
            const srv = servicos.find(s => s?.onu && (s.onu.olt_nome || s.onu.olt_name)) || servicos.find(s => s?.onu) || servicos[0] || {};
            const onu = srv?.onu && typeof srv.onu === 'object' ? srv.onu : {};
            const plano = (typeof srv?.plano === 'object' ? srv?.plano?.descricao : srv?.plano) || c?.servico_plano || c?.plano || '';
            const cidade = String(c?.endereco?.cidade || srv?.endereco?.cidade || '').trim().toUpperCase();
            const bairro = String(c?.endereco?.bairro || srv?.endereco?.bairro || '').trim().toUpperCase();
            const status = String(c?.status || c?.contratoStatusDisplay || c?.contratoStatus || '').trim();
            const popId = c?.pop_id != null ? String(c.pop_id) : '';
            const oltId = onu?.olt_id != null ? String(onu.olt_id) : '';
            const oltName = String(onu?.olt_nome || onu?.olt_name || '').trim();
            const slot = onu?.slot != null ? String(onu.slot) : '';
            const pon = onu?.pon != null ? String(onu.pon) : '';
            const cto = String(onu?.splitter?.nome || onu?.cto || '').trim();
            map.set(`${cpf}::${contratoId}`, {
                providerId,
                cpf,
                contratoId,
                nome: String(item.nome || '').trim(),
                status,
                plano: String(plano || '').trim(),
                cidade,
                bairro,
                popId,
                oltId,
                oltName,
                slot,
                pon,
                cto,
            });
        }
    }
    return [...map.values()];
}

/**
 * Grava uma página inteira (até 100 clientes) com apenas 2 queries em lote (UNNEST),
 * eliminando o gargalo N+1 de 200 queries sequenciais por página.
 */
async function bulkUpsertClientsAndSegments(pool, providerId, rows) {
    if (!pool || !providerId || !Array.isArray(rows) || !rows.length) return;
    await Promise.all([ensureClientCache(pool), ensureSegmentTable(pool)]);

    // Deduplica por client_id na mesma página para evitar erro ON CONFLICT DO UPDATE duplo
    const byClientId = new Map();
    for (const row of rows) {
        if (!row.cpf) continue;
        byClientId.set(String(row.clientId), row);
    }
    const dedupClients = [...byClientId.values()];
    if (!dedupClients.length) return;

    await pool.query(
        `INSERT INTO sgp_clients (provider_id, client_id, nome, cpfcnpj, contratos, updated_at)
         SELECT $1, u.client_id, u.nome, u.cpfcnpj, u.contratos::jsonb, NOW()
         FROM UNNEST($2::text[], $3::text[], $4::text[], $5::text[])
              AS u(client_id, nome, cpfcnpj, contratos)
         ON CONFLICT (provider_id, client_id) DO UPDATE SET
           nome = EXCLUDED.nome,
           cpfcnpj = EXCLUDED.cpfcnpj,
           contratos = EXCLUDED.contratos,
           updated_at = NOW()`,
        [
            providerId,
            dedupClients.map(r => String(r.clientId)),
            dedupClients.map(r => String(r.nome || 'Cliente')),
            dedupClients.map(r => String(r.cpf)),
            dedupClients.map(r => JSON.stringify(r.contratos || [])),
        ],
    );

    const segs = extractSegmentRows(providerId, dedupClients);
    if (!segs.length) return;

    await pool.query(
        `INSERT INTO subscriber_segments (
           provider_id, cpfcnpj, contrato_id, client_name, contract_status,
           plano, cidade, bairro, pop_id, olt_id, olt_name, slot, pon, cto, updated_at
         )
         SELECT $1, u.cpfcnpj, u.contrato_id, u.client_name, u.contract_status,
                u.plano, u.cidade, u.bairro, u.pop_id, u.olt_id, u.olt_name, u.slot, u.pon, u.cto, NOW()
         FROM UNNEST(
           $2::text[], $3::text[], $4::text[], $5::text[], $6::text[],
           $7::text[], $8::text[], $9::text[], $10::text[], $11::text[],
           $12::text[], $13::text[], $14::text[]
         ) AS u(cpfcnpj, contrato_id, client_name, contract_status, plano, cidade, bairro, pop_id, olt_id, olt_name, slot, pon, cto)
         ON CONFLICT (provider_id, cpfcnpj, contrato_id) DO UPDATE SET
           client_name = CASE WHEN EXCLUDED.client_name <> '' THEN EXCLUDED.client_name ELSE subscriber_segments.client_name END,
           contract_status = CASE WHEN EXCLUDED.contract_status <> '' THEN EXCLUDED.contract_status ELSE subscriber_segments.contract_status END,
           plano = CASE WHEN EXCLUDED.plano <> '' THEN EXCLUDED.plano ELSE subscriber_segments.plano END,
           cidade = CASE WHEN EXCLUDED.cidade <> '' THEN EXCLUDED.cidade ELSE subscriber_segments.cidade END,
           bairro = CASE WHEN EXCLUDED.bairro <> '' THEN EXCLUDED.bairro ELSE subscriber_segments.bairro END,
           pop_id = CASE WHEN EXCLUDED.pop_id <> '' THEN EXCLUDED.pop_id ELSE subscriber_segments.pop_id END,
           olt_id = CASE WHEN EXCLUDED.olt_id <> '' THEN EXCLUDED.olt_id ELSE subscriber_segments.olt_id END,
           olt_name = CASE WHEN EXCLUDED.olt_name <> '' THEN EXCLUDED.olt_name ELSE subscriber_segments.olt_name END,
           slot = CASE WHEN EXCLUDED.slot <> '' THEN EXCLUDED.slot ELSE subscriber_segments.slot END,
           pon = CASE WHEN EXCLUDED.pon <> '' THEN EXCLUDED.pon ELSE subscriber_segments.pon END,
           cto = CASE WHEN EXCLUDED.cto <> '' THEN EXCLUDED.cto ELSE subscriber_segments.cto END,
           updated_at = NOW()`,
        [
            providerId,
            segs.map(s => s.cpf),
            segs.map(s => s.contratoId),
            segs.map(s => s.nome),
            segs.map(s => s.status),
            segs.map(s => s.plano),
            segs.map(s => s.cidade),
            segs.map(s => s.bairro),
            segs.map(s => s.popId),
            segs.map(s => s.oltId),
            segs.map(s => s.oltName),
            segs.map(s => s.slot),
            segs.map(s => s.pon),
            segs.map(s => s.cto),
        ],
    );
}

/**
 * Remove do Postgres clientes/segmentos que não vieram em uma sincronização
 * completa bem-sucedida (ex.: clientes removidos do SGP).
 */
async function pruneStaleAfterFullSync(pool, providerId, syncStartedIso) {
    if (!pool || !providerId || !syncStartedIso) return { prunedClients: 0, prunedSegments: 0 };
    await Promise.all([ensureClientCache(pool), ensureSegmentTable(pool)]);
    const [clientsRes, segmentsRes] = await Promise.all([
        pool.query("DELETE FROM sgp_clients WHERE provider_id = $1 AND updated_at < ($2::timestamptz - INTERVAL '60 seconds')", [providerId, syncStartedIso]),
        pool.query("DELETE FROM subscriber_segments WHERE provider_id = $1 AND updated_at < ($2::timestamptz - INTERVAL '60 seconds')", [providerId, syncStartedIso]),
    ]);
    return { prunedClients: clientsRes.rowCount || 0, prunedSegments: segmentsRes.rowCount || 0 };
}

/**
 * Política periódica de limpeza e retenção no PostgreSQL:
 * - Remove tokens FCM sem atualização há > deviceMaxAgeDays (padrão 120 dias)
 * - Remove histórico de campanhas com mais de campaignMaxAgeDays (padrão 180 dias)
 * - Remove caches órfãos de provedores que não existem mais (quando activeProviderIds é informado)
 */
async function runRetentionCleanup(pool, options = {}) {
    if (!pool) return { prunedDevices: 0, prunedCampaigns: 0, prunedDiagnostics: 0, prunedOrphanProviders: 0 };
    const deviceMaxAgeDays = Math.max(30, Number(options.deviceMaxAgeDays) || 120);
    const campaignMaxAgeDays = Math.max(30, Number(options.campaignMaxAgeDays) || 180);
    const activeProviderIds = Array.isArray(options.activeProviderIds) ? options.activeProviderIds.filter(Boolean) : null;

    let prunedDevices = 0;
    let prunedCampaigns = 0;
    let prunedDiagnostics = 0;
    let prunedOrphanProviders = 0;

    const tables = await pool.query(`
        SELECT
          to_regclass('public.subscriber_devices') IS NOT NULL AS has_devices,
          to_regclass('public.notification_campaigns') IS NOT NULL AS has_campaigns,
          to_regclass('public.diagnostic_results') IS NOT NULL AS has_diagnostics,
          to_regclass('public.sgp_clients') IS NOT NULL AS has_clients,
          to_regclass('public.subscriber_segments') IS NOT NULL AS has_segments
    `);
    const t = tables.rows[0] || {};

    if (t.has_devices) {
        const res = await pool.query(
            `DELETE FROM subscriber_devices WHERE updated_at < NOW() - ($1::int * INTERVAL '1 day')`,
            [deviceMaxAgeDays],
        );
        prunedDevices = res.rowCount || 0;
    }
    if (t.has_campaigns) {
        const res = await pool.query(
            `DELETE FROM notification_campaigns WHERE created_at < NOW() - ($1::int * INTERVAL '1 day')`,
            [campaignMaxAgeDays],
        );
        prunedCampaigns = res.rowCount || 0;
    }
    if (t.has_diagnostics) {
        const res = await pool.query(
            `DELETE FROM diagnostic_results WHERE created_at < NOW() - ($1::int * INTERVAL '1 day')`,
            [campaignMaxAgeDays],
        );
        prunedDiagnostics = res.rowCount || 0;
    }
    if (activeProviderIds && activeProviderIds.length > 0) {
        if (t.has_clients) {
            const r1 = await pool.query(`DELETE FROM sgp_clients WHERE NOT (provider_id = ANY($1::text[]))`, [activeProviderIds]);
            prunedOrphanProviders += r1.rowCount || 0;
        }
        if (t.has_segments) {
            const r2 = await pool.query(`DELETE FROM subscriber_segments WHERE NOT (provider_id = ANY($1::text[]))`, [activeProviderIds]);
            prunedOrphanProviders += r2.rowCount || 0;
        }
        if (t.has_devices) {
            const r3 = await pool.query(`DELETE FROM subscriber_devices WHERE NOT (provider_id = ANY($1::text[]))`, [activeProviderIds]);
            prunedOrphanProviders += r3.rowCount || 0;
        }
        if (t.has_diagnostics) {
            const r4 = await pool.query(`DELETE FROM diagnostic_results WHERE NOT (provider_id = ANY($1::text[]))`, [activeProviderIds]);
            prunedOrphanProviders += r4.rowCount || 0;
        }
    }

    return { prunedDevices, prunedCampaigns, prunedDiagnostics, prunedOrphanProviders };
}

async function upsertSegmentsForClient(pool, providerId, cpf, nome, contratos) {
    if (!pool || !providerId || !cpf || !Array.isArray(contratos) || !contratos.length) return;
    await bulkUpsertClientsAndSegments(pool, providerId, [{
        clientId: String(cpf).replace(/\D/g, ''),
        cpf: String(cpf).replace(/\D/g, ''),
        nome,
        contratos,
    }]);
}

async function upsertOnuSegment(pool, providerId, cpf, contratoId, formattedData) {
    if (!pool || !providerId || !cpf || !formattedData) return;
    const digits = String(cpf).replace(/\D/g, '');
    if (!digits) return;
    await ensureSegmentTable(pool);
    const oltId = formattedData.oltId ? String(formattedData.oltId) : '';
    const oltName = String(formattedData.oltName || '').trim();
    const slot = formattedData.slot ? String(formattedData.slot) : '';
    const pon = formattedData.pon ? String(formattedData.pon) : '';
    const cto = String(formattedData.cto || '').trim();
    if (!oltName && !cto && !slot) return;
    await pool.query(
        `INSERT INTO subscriber_segments (
            provider_id, cpfcnpj, contrato_id, olt_id, olt_name, slot, pon, cto, updated_at
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NOW())
        ON CONFLICT (provider_id, cpfcnpj, contrato_id) DO UPDATE SET
            olt_id = CASE WHEN EXCLUDED.olt_id <> '' THEN EXCLUDED.olt_id ELSE subscriber_segments.olt_id END,
            olt_name = CASE WHEN EXCLUDED.olt_name <> '' THEN EXCLUDED.olt_name ELSE subscriber_segments.olt_name END,
            slot = CASE WHEN EXCLUDED.slot <> '' THEN EXCLUDED.slot ELSE subscriber_segments.slot END,
            pon = CASE WHEN EXCLUDED.pon <> '' THEN EXCLUDED.pon ELSE subscriber_segments.pon END,
            cto = CASE WHEN EXCLUDED.cto <> '' THEN EXCLUDED.cto ELSE subscriber_segments.cto END,
            updated_at = NOW()`,
        [providerId, digits, String(contratoId || ''), oltId, oltName, slot, pon, cto]
    );
}

module.exports = {
    ensureClientCache,
    ensureSegmentTable,
    bulkUpsertClientsAndSegments,
    pruneStaleAfterFullSync,
    runRetentionCleanup,
    upsertSegmentsForClient,
    upsertOnuSegment,
};
