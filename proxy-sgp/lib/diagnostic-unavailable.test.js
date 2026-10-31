'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');
const { once } = require('node:events');

test('real HTTP analyze keeps auth/tenant checks and returns stable 501 without analysis or SGP effects', async () => {
    const original = Module._load;
    const envKeys = ['NODE_ENV', 'GOOGLE_APPLICATION_CREDENTIALS', 'JOBS_REDIS_URL'];
    const before = Object.fromEntries(envKeys.map(key => [key, process.env[key]]));
    process.env.NODE_ENV = 'test';
    delete process.env.GOOGLE_APPLICATION_CREDENTIALS;
    delete process.env.JOBS_REDIS_URL;
    let sgpEffects = 0, pgEffects = 0, firestoreEffects = 0;
    class FakeRedis { on() {} connect() { return Promise.resolve(); } }
    class FakePool { on() {} query() { pgEffects++; throw new Error('No PG allowed'); } }
    let api;
    try {
        Module._load = function(name, parent, ...args) {
            if (parent?.filename === require.resolve('../index')) {
                if (name === 'firebase-admin') return {
                    apps: [{}],
                    firestore: () => ({ collection() { firestoreEffects++; throw new Error('No Firestore allowed'); } }),
                    auth: () => ({ verifyIdToken: async token => {
                        if (token === 'invalid') throw new Error('synthetic invalid identity');
                        if (token === 'saas') return { uid: 'synthetic-saas', superAdmin: true };
                        return { uid: 'synthetic-user', role: 'subscriber', providerId: token, cpfCnpj: '12345678901' };
                    } }),
                };
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
    const post = (token, body = { cpfCnpj: '12345678901' }) => fetch('http://127.0.0.1:' + server.address().port + '/diagnostic/analyze', {
        method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: 'Bearer ' + token } : {}) },
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
        assert.equal(sgpEffects, 0); assert.equal(pgEffects, 0); assert.equal(firestoreEffects, 0);
    } finally {
        server.closeAllConnections();
        await new Promise(resolve => server.close(resolve));
        for (const key of envKeys) if (before[key] === undefined) delete process.env[key]; else process.env[key] = before[key];
    }
});
