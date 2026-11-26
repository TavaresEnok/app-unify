'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');
const { once } = require('node:events');

// Tokens legados não verificados ganham balde próprio pelo "sub", mas também
// contam num teto por IP: "sub" aleatório não pode contornar o limite.
test('forged legacy tokens with random subs still hit the per-IP ceiling; distinct IPs do not share it', async () => {
    const original = Module._load;
    const envKeys = ['NODE_ENV', 'JOBS_REDIS_URL', 'JWT_SECRET', 'APP_SECRETS_KEY', 'RATE_LIMIT_MAX_REQUESTS'];
    const before = Object.fromEntries(envKeys.map(key => [key, process.env[key]]));
    process.env.NODE_ENV = 'test';
    delete process.env.JOBS_REDIS_URL;
    process.env.JWT_SECRET = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    process.env.APP_SECRETS_KEY = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';
    process.env.RATE_LIMIT_MAX_REQUESTS = '2';
    class FakeRedis { on() {} connect() { return Promise.resolve(); } }
    class FakePool {
        on() {}
        async query() { return { rows: [] }; }
    }
    let api;
    try {
        Module._load = function(name, parent, ...args) {
            if (parent?.filename === require.resolve('../index')) {
                if (name === 'ioredis') return FakeRedis;
                if (name === 'pg') return { Pool: FakePool };
                if (name === './lib/upstream') return { createUpstream: () => ({ execute() { throw new Error('No SGP allowed'); } }), readTtl: () => 0 };
            }
            return original.call(this, name, parent, ...args);
        };
        api = require('../index');
    } finally { Module._load = original; }
    const server = api.app.listen(0, '127.0.0.1');
    await once(server, 'listening');
    const forged = (sub) => {
        const b64 = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
        return `${b64({ alg: 'RS256', kid: 'x' })}.${b64({ sub, user_id: sub })}.c2ln`;
    };
    const post = (sub, ip) => fetch('http://127.0.0.1:' + server.address().port + '/diagnostic/analyze', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + forged(sub), 'X-Forwarded-For': ip },
        body: JSON.stringify({ cpfCnpj: '12345678901' }), signal: AbortSignal.timeout(3000),
    });
    try {
        // Limite por usuário = 2, teto por IP = 8.
        const statuses = [];
        for (let i = 0; i < 10; i++) statuses.push((await post(`random-${i}`, '203.0.113.7')).status);
        assert.equal(statuses.filter(s => s === 429).length, 2, `statuses: ${statuses.join(',')}`);
        assert.ok(statuses.slice(0, 8).every(s => s !== 429));
        // Outro IP não herda o teto do primeiro.
        assert.notEqual((await post('random-other', '198.51.100.9')).status, 429);
        // O mesmo "sub" continua limitado pelo próprio balde.
        const same = [];
        for (let i = 0; i < 3; i++) same.push((await post('same-user', '198.51.100.10')).status);
        assert.equal(same[2], 429);
    } finally {
        server.closeAllConnections();
        await new Promise(resolve => server.close(resolve));
        for (const key of envKeys) if (before[key] === undefined) delete process.env[key]; else process.env[key] = before[key];
    }
});
