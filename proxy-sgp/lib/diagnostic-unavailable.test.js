'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');
const { once } = require('node:events');

test('real HTTP analyze keeps auth/tenant checks and returns stable 501 without analysis or SGP effects', async () => {
    const original = Module._load;
    const envKeys = ['NODE_ENV', 'JOBS_REDIS_URL', 'JWT_SECRET', 'APP_SECRETS_KEY'];
    const before = Object.fromEntries(envKeys.map(key => [key, process.env[key]]));
    process.env.NODE_ENV = 'test';
    delete process.env.JOBS_REDIS_URL;
    process.env.JWT_SECRET = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    process.env.APP_SECRETS_KEY = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';
    const selfAuth = require('./self-auth');
    selfAuth.clearKeyCacheForTests();

    let sgpEffects = 0, writeEffects = 0;
    const adminUsers = new Map([
        ['synthetic-saas', { uid: 'synthetic-saas', email: 'saas@synthetic.test', role: 'superAdmin', provider_id: null, disabled: false, token_version: 1 }],
    ]);
    const subscribers = new Map([
        ['synthetic-user:a', { uid: 'synthetic-user:a', provider_id: 'a', cpfcnpj: '12345678901', email: '', disabled: false, token_version: 1 }],
        ['synthetic-user:b', { uid: 'synthetic-user:b', provider_id: 'b', cpfcnpj: '12345678901', email: '', disabled: false, token_version: 1 }],
    ]);
    class FakeRedis { on() {} connect() { return Promise.resolve(); } }
    class FakePool {
        on() {}
        async query(sql, params = []) {
            const text = String(sql).trim();
            if (/^(CREATE|ALTER|DO\b)/i.test(text)) return { rows: [] };
            if (/FROM\s+admin_users\b/i.test(text)) {
                const row = adminUsers.get(params[0]);
                return { rows: row ? [row] : [] };
            }
            if (/FROM\s+subscribers\b/i.test(text)) {
                const row = subscribers.get(params[0]);
                return { rows: row ? [row] : [] };
            }
            writeEffects++;
            throw new Error(`No write/business PG allowed in analyze: ${text}`);
        }
    }
    let api;
    try {
        Module._load = function(name, parent, ...args) {
            if (parent?.filename === require.resolve('../index')) {
                if (name === 'ioredis') return FakeRedis;
                if (name === 'pg') return { Pool: FakePool };
                if (name === './lib/upstream') return { createUpstream: () => ({ execute() { sgpEffects++; throw new Error('No SGP allowed'); } }), readTtl: () => 0 };
                if (name === './lib/sgp-outbound') return { formatSgpUrl() { sgpEffects++; throw new Error('No SGP allowed'); } };
            }
            return original.call(this, name, parent, ...args);
        };
        api = require('../index');
    } finally { Module._load = original; }
    const server = api.app.listen(0, '127.0.0.1');
    await once(server, 'listening');
    const tokenFor = (kind) => {
        if (!kind) return '';
        if (kind === 'invalid') return 'invalid.jwt.token';
        if (kind === 'saas') return selfAuth.signJwt({ uid: 'synthetic-saas', role: 'superAdmin', superAdmin: true, tv: 1 });
        return selfAuth.signJwt({ uid: `synthetic-user:${kind}`, role: 'subscriber', providerId: kind, cpfCnpj: '12345678901', tv: 1 });
    };
    const post = (token, body = { cpfCnpj: '12345678901' }) => fetch('http://127.0.0.1:' + server.address().port + '/diagnostic/analyze', {
        method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: 'Bearer ' + tokenFor(token) } : {}) },
        body: JSON.stringify(body), signal: AbortSignal.timeout(3000),
    });
    try {
        const expected = { error: { code: 'DIAGNOSTIC_UNAVAILABLE', message: 'Análise de diagnóstico indisponível. Nenhuma análise medida foi realizada.' } };
        for (const token of ['a', 'b', 'saas']) {
            const result = await post(token, { cpfCnpj: '12345678901', providerId: token === 'saas' ? 'a' : token });
            assert.equal(result.status, 501);
            assert.deepEqual(await result.json(), expected);
        }
        assert.equal((await post()).status, 401);
        assert.equal((await post('invalid')).status, 401);
        assert.equal((await post('a', { cpfCnpj: '12345678901', providerId: 'b' })).status, 403);
        assert.equal((await post('a', { cpfCnpj: '99999999999' })).status, 403);
        assert.equal((await post('a', {})).status, 400);
        assert.equal(sgpEffects, 0); assert.equal(writeEffects, 0);
    } finally {
        server.closeAllConnections();
        await new Promise(resolve => server.close(resolve));
        selfAuth.clearKeyCacheForTests();
        for (const key of envKeys) if (before[key] === undefined) delete process.env[key]; else process.env[key] = before[key];
    }
});
