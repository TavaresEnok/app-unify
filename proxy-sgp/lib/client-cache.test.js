'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { bulkUpsertClientsAndSegments, pruneStaleAfterFullSync, runRetentionCleanup } = require('./client-cache');

test('bulkUpsertClientsAndSegments faz upsert em lote (UNNEST) de clientes e segmentos', async () => {
    const queries = [];
    const fakePool = {
        query: async (sql, params) => {
            queries.push({ sql: String(sql), params });
            return { rows: [], rowCount: 2 };
        },
    };
    await bulkUpsertClientsAndSegments(fakePool, 'vibe', [
        {
            clientId: '10', nome: 'Maria', cpf: '10331142430',
            contratos: [{
                id: 86069, status: 'Ativo', pop_id: 3492, vencimento: 10,
                endereco: { cidade: 'Paulista', bairro: 'Pau Amarelo' },
                servicos: [{ plano: { descricao: 'VIBE 500 MEGA' }, onu: { olt_id: 2, olt_nome: 'OLT ZTE - PAU AMARELO', slot: 1, pon: 11, splitter: { nome: 'R21-01' } } }],
            }],
        },
        {
            clientId: '10', nome: 'Maria Atualizada', cpf: '10331142430',
            contratos: [{ id: 86069, status: 'Ativo' }],
        },
    ]);

    const sgpInsert = queries.find(q => q.sql.includes('INSERT INTO sgp_clients'));
    const segInsert = queries.find(q => q.sql.includes('INSERT INTO subscriber_segments'));
    assert.ok(sgpInsert, 'deve fazer bulk upsert em sgp_clients');
    assert.ok(segInsert, 'deve fazer bulk upsert em subscriber_segments');
    // Deduplicou clientId 10 dentro da página
    assert.deepEqual(sgpInsert.params[1], ['10']);
    assert.deepEqual(sgpInsert.params[2], ['Maria Atualizada']);
});

test('pruneStaleAfterFullSync e runRetentionCleanup removem registros obsoletos', async () => {
    const calls = [];
    const fakePool = {
        query: async (sql, params) => {
            calls.push({ sql: String(sql), params });
            if (String(sql).includes('to_regclass')) {
                return { rows: [{ has_devices: true, has_campaigns: true, has_diagnostics: true, has_clients: true, has_segments: true }] };
            }
            return { rows: [], rowCount: 3 };
        },
    };

    const pruned = await pruneStaleAfterFullSync(fakePool, 'vibe', '2026-11-22T03:00:00Z');
    assert.deepEqual(pruned, { prunedClients: 3, prunedSegments: 3 });

    const cleanup = await runRetentionCleanup(fakePool, { deviceMaxAgeDays: 120, campaignMaxAgeDays: 180, activeProviderIds: ['vibe'] });
    assert.equal(cleanup.prunedDevices, 3);
    assert.equal(cleanup.prunedCampaigns, 3);
    assert.equal(cleanup.prunedDiagnostics, 3);
    assert.equal(cleanup.prunedOrphanProviders, 12);
});

