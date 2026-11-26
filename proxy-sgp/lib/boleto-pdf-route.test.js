'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');
const { once } = require('node:events');

const PDF = Buffer.concat([Buffer.from('%PDF-1.7\n'), Buffer.alloc(32, 7), Buffer.from('\n%%EOF')]);

test('POST /invoice/boleto-pdf: dono confere, PDF volta com cabeçalhos privados, cache e cota por assinante', async () => {
    const original = Module._load;
    const envKeys = ['NODE_ENV', 'JOBS_REDIS_URL', 'JWT_SECRET', 'APP_SECRETS_KEY', 'BOLETO_PDF_PER_HOUR', 'LEGACY_FIREBASE_AUTH_UNTIL'];
    const before = Object.fromEntries(envKeys.map(key => [key, process.env[key]]));
    process.env.NODE_ENV = 'test';
    delete process.env.JOBS_REDIS_URL;
    delete process.env.LEGACY_FIREBASE_AUTH_UNTIL;
    process.env.BOLETO_PDF_PER_HOUR = '4';
    process.env.JWT_SECRET = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    process.env.APP_SECRETS_KEY = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';
    const selfAuth = require('./self-auth');
    selfAuth.clearKeyCacheForTests();
    const realOutbound = require('./sgp-outbound');

    const subscribers = new Map([
        ['u:ixc', { uid: 'u:ixc', provider_id: 'ixcp', cpfcnpj: '12345678909', email: '', disabled: false, token_version: 1 }],
        ['u:sgp', { uid: 'u:sgp', provider_id: 'sgpp', cpfcnpj: '12345678909', email: '', disabled: false, token_version: 1 }],
    ]);
    const integrations = {
        ixcp: { erp: 'ixc', baseUrl: 'https://ixc.example.test', token: '1:tok', app: '' },
        sgpp: { erp: 'sgp', baseUrl: 'https://sgp.example.test', token: 'tok', app: 'app' },
    };
    let lastProvider = null;
    const ixcCalls = [];
    class FakeRedis { on() {} connect() { return Promise.reject(new Error('sem redis no teste')); } }
    class FakePool {
        on() {}
        async query(sql, params = []) {
            const text = String(sql).trim();
            if (/^(CREATE|ALTER|DO\b)/i.test(text)) return { rows: [] };
            if (/FROM\s+providers\s+p\b/i.test(text)) { lastProvider = params[0]; return { rows: integrations[params[0]] ? [{ id: params[0], ciphertext: null }] : [] }; }
            if (/FROM\s+subscribers\b/i.test(text)) { const row = subscribers.get(params[0]); return { rows: row ? [row] : [] }; }
            return { rows: [] };
        }
    }
    const fakeOutbound = {
        ...realOutbound,
        privateIntegration: () => integrations[lastProvider],
        async request(url, body) {
            const table = url.split('/').pop();
            ixcCalls.push(table);
            if (table === 'cliente') return { data: { total: 1, registros: [{ id: '1', cnpj_cpf: '123.456.789-09' }] } };
            if (table === 'fn_areceber') {
                const rows = { 900: { id: '900', id_cliente: '1', id_contrato: '100', status: 'A' }, 905: { id: '905', id_cliente: '2', id_contrato: '200', status: 'A' } };
                const row = rows[body.query];
                return { data: { total: row ? 1 : 0, registros: row ? [row] : [] } };
            }
            if (table === 'get_boleto') return { data: PDF.toString('base64') };
            throw new Error('tabela inesperada');
        },
    };
    let api;
    try {
        Module._load = function(name, parent, ...args) {
            if (parent?.filename === require.resolve('../index')) {
                if (name === 'ioredis') return FakeRedis;
                if (name === 'pg') return { Pool: FakePool };
                if (name === './lib/upstream') return { createUpstream: () => ({ execute: (_input, operation) => operation() }), readTtl: () => 0 };
                if (name === './lib/sgp-outbound') return fakeOutbound;
            }
            return original.call(this, name, parent, ...args);
        };
        api = require('../index');
    } finally { Module._load = original; }
    const server = api.app.listen(0, '127.0.0.1');
    await once(server, 'listening');
    const token = uid => selfAuth.signJwt({ uid, role: 'subscriber', providerId: subscribers.get(uid).provider_id, cpfCnpj: '12345678909', tv: 1 });
    const post = (uid, body) => fetch(`http://127.0.0.1:${server.address().port}/invoice/boleto-pdf`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', ...(uid ? { Authorization: `Bearer ${token(uid)}` } : {}) },
        body: JSON.stringify({ cpfCnpj: '12345678909', ...body }), signal: AbortSignal.timeout(3000),
    });
    try {
        assert.equal((await post(null, { faturaId: '900' })).status, 401);
        assert.equal((await post('u:ixc', { faturaId: '900', cpfCnpj: '98765432100' })).status, 403);

        const ok = await post('u:ixc', { faturaId: '900', contratoId: 100 });
        assert.equal(ok.status, 200);
        assert.equal(ok.headers.get('content-type'), 'application/pdf');
        assert.equal(ok.headers.get('cache-control'), 'private, no-store');
        assert.match(ok.headers.get('content-disposition'), /^inline; filename="boleto-900\.pdf"$/);
        assert.deepEqual(Buffer.from(await ok.arrayBuffer()), PDF);
        const emitted = ixcCalls.filter(t => t === 'get_boleto').length;
        assert.equal(emitted, 1);
        // Segundo toque: sai do cache, sem nova emissão no IXC.
        assert.equal((await post('u:ixc', { faturaId: '900', contratoId: 100 })).status, 200);
        assert.equal(ixcCalls.filter(t => t === 'get_boleto').length, 1);

        const foreign = await post('u:ixc', { faturaId: '905' });
        assert.equal(foreign.status, 404);
        assert.equal((await foreign.json()).error.code, 'invoice-not-found');
        assert.equal(ixcCalls.filter(t => t === 'get_boleto').length, 1, 'fatura alheia nunca é emitida');

        // Cota por assinante (4/h neste teste): o 5º pedido recebe 429.
        assert.equal((await post('u:ixc', { faturaId: 'abc' })).status, 400);
        const limited = await post('u:ixc', { faturaId: '900' });
        assert.equal(limited.status, 429);
        assert.ok(Number(limited.headers.get('retry-after')) > 0);

        const sgp = await post('u:sgp', { faturaId: '900' });
        assert.equal(sgp.status, 404);
        assert.equal((await sgp.json()).error.code, 'boleto-unavailable');
        assert.equal((await post('u:sgp', { faturaId: '9 9' })).status, 400);
    } finally {
        server.closeAllConnections();
        await new Promise(resolve => server.close(resolve));
        selfAuth.clearKeyCacheForTests();
        for (const key of envKeys) if (before[key] === undefined) delete process.env[key]; else process.env[key] = before[key];
    }
});
