'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');
const http = require('node:http');
const net = require('node:net');
const { once } = require('node:events');
const runtime = require('./sgp-outbound');

test('real proxy routes and worker entrypoints isolate A/B and reject global, forged and incomplete credentials', async () => {
    const received = []; let redirect = false; let mixedDns = false; let failLookup = false; let online = true;
    const upstreamServer = http.createServer(async (req, res) => {
        let body = ''; for await (const chunk of req) body += chunk;
        received.push({ host: req.headers.host, method: req.method, url: req.url, body });
        if (redirect) { res.writeHead(302, { Location: 'http://127.0.0.1:1/forbidden' }); res.end(); return; }
        if (req.url === '/api/central/verificaacesso/') { res.end(JSON.stringify({ status: online ? 1 : 0 })); return; }
        res.end(JSON.stringify({ contratos: [{ contratoId: '1', contratoCentralSenha: 'synthetic-password', contratoStatus: 'Ativo' }], clientes: [], titulos: [] }));
    });
    upstreamServer.listen(0, '127.0.0.1'); await once(upstreamServer, 'listening');
    const port = upstreamServer.address().port;
    const base = `http://sgp.synthetic.test:${port}`;
    const docs = new Map(); const reads = []; let lookupFailure = false;
    for (const provider of ['a', 'b', 'incomplete']) {
        docs.set(`provedores/${provider}`, { details: { systemUrl: base, appName: 'public-forged' } });
        docs.set(`provedores/${provider}/secrets/sgp`, { integrations: { sgpBaseUrl: base, appName: `app-${provider}`, ...(provider !== 'incomplete' ? { apiToken: `synthetic-${provider}` } : {}) } });
    }
    const ref = path => ({ get: async () => { reads.push(path); if (lookupFailure) throw new Error('synthetic lookup failure'); return { exists: docs.has(path), data: () => docs.get(path) }; }, collection: name => collection(`${path}/${name}`) });
    const collection = path => ({ doc: id => ref(`${path}/${id}`) });
    const transport = runtime.createSgpTransport({ lookup: async () => {
        if (failLookup) throw new Error('synthetic DNS failure');
        return mixedDns ? [{ address: '8.8.8.8', family: 4 }, { address: '127.0.0.1', family: 4 }] : [{ address: '8.8.8.8', family: 4 }];
    }, connect: options => {
        assert.equal(options.host, '8.8.8.8');
        const socket = net.connect({ host: '127.0.0.1', port });
        Object.defineProperty(socket, 'remoteAddress', { get: () => '8.8.8.8' }); return socket;
    } });
    class FakeRedis { on() {} connect() { return Promise.resolve(); } }
    class FakePool { on() {} }
    const before = { SGP_TOKEN: process.env.SGP_TOKEN, NODE_ENV: process.env.NODE_ENV };
    process.env.SGP_TOKEN = 'synthetic-global-never-send'; process.env.NODE_ENV = 'test';
    const load = Module._load;
    let api;
    try {
        Module._load = function(name, parent, ...args) {
            if (parent?.filename === require.resolve('../index')) {
                if (name === 'firebase-admin') return { apps: [{}], firestore: () => ({ collection }), auth: () => ({ verifyIdToken: async token => ({ uid: `subscriber:${token}`, role: 'subscriber', providerId: token, cpfCnpj: '12345678901' }) }) };
                if (name === 'ioredis') return FakeRedis;
                if (name === 'pg') return { Pool: FakePool };
                if (name === './lib/upstream') return { createUpstream: () => ({ execute: async (_input, operation) => operation() }), readTtl: () => 0 };
                if (name === './lib/sgp-outbound') return { ...runtime, ...transport };
            }
            return load.call(this, name, parent, ...args);
        };
        api = require('../index');
    } finally { Module._load = load; }
    const server = api.app.listen(0, '127.0.0.1'); await once(server, 'listening');
    const post = (path, body, token = 'a') => fetch(`http://127.0.0.1:${server.address().port}${path}`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify(body), signal: AbortSignal.timeout(3000) });
    try {
        // Exercise the HTTP login consumer, preserving its CPF/password form
        // authentication (verificaacesso does not use token/app).
        for (const tenant of ['a', 'b']) for (const status of [true, false]) {
            online = status;
            const start = received.length;
            const result = await post('/check-cpf', { providerId: tenant, cpf: '12345678901', senha: 'synthetic-password' });
            assert.equal(result.status, 200);
            assert.equal((await result.json()).status, status ? 'Online' : 'Offline');
            const requests = received.slice(start);
            const consulta = requests.find(item => item.url === '/api/ura/consultacliente/');
            assert.equal(new URLSearchParams(consulta.body).get('token'), `synthetic-${tenant}`);
            const verifica = requests.filter(item => item.url === '/api/central/verificaacesso/');
            assert.equal(verifica.length, 1);
            assert.equal(verifica[0].method, 'POST');
            assert.deepEqual(Object.fromEntries(new URLSearchParams(verifica[0].body)), {
                cpfcnpj: '12345678901', senha: 'synthetic-password', contrato: '1',
            });
        }
        const beforeOnu = received.length;
        const unhandled = [];
        const observe = error => unhandled.push(error);
        process.on('unhandledRejection', observe);
        try {
            for (const path of ['/diagnostic/onu-signal', '/diagnostic/onu-signal-base']) {
                for (const forged of [{ token: 'forged' }, { app: 'forged' }, { sgpBaseUrl: 'http://127.0.0.1' }, { sgpParams: { token: 'forged' } }]) {
                    const result = await post(path, { cpfCnpj: '12345678901', ...forged });
                    assert.equal(result.status, 400);
                    assert.ok((await result.json()).error);
                }
                const result = await post(path, { cpfCnpj: '12345678901' }, 'incomplete');
                assert.equal(result.status, 503);
                assert.ok((await result.json()).error);
            }
            await new Promise(resolve => setImmediate(resolve));
            assert.deepEqual(unhandled, []);
            assert.equal(received.length, beforeOnu);
        } finally { process.off('unhandledRejection', observe); }
        // Same CPF, two authenticated tenants. Public config is deliberately forged.
        for (const tenant of ['a', 'b']) {
            const result = await post('/get-invoices', { cpfCnpj: '12345678901' }, tenant);
            assert.equal(result.status, 200);
        }
        assert.ok(received.some(item => item.body.includes('token=synthetic-a') && item.body.includes('app=app-a')));
        assert.ok(received.some(item => item.body.includes('token=synthetic-b') && item.body.includes('app=app-b')));
        const count = received.length;
        for (const forged of [{ token: 'forged' }, { app: 'forged' }, { sgpBaseUrl: 'http://127.0.0.1' }, { sgpParams: { token: 'forged' } }]) assert.equal((await post('/get-invoices', { cpfCnpj: '12345678901', ...forged })).status, 400);
        assert.equal((await post('/get-invoices', { cpfCnpj: '12345678901', providerId: 'b' })).status, 403);
        await assert.rejects(api.ensureSgpCredentials({ cpfCnpj: '12345678901' }));
        assert.ok(!reads.some(path => path.startsWith('clientes/')));
        for (const providerId of ['incomplete', 'absent']) await assert.rejects(api.ensureSgpCredentials({ providerId }));
        lookupFailure = true;
        await assert.rejects(api.ensureSgpCredentials({ providerId: 'lookup-fails' }));
        lookupFailure = false;
        assert.equal(received.length, count);
        const a = await api.ensureSgpCredentials({ providerId: 'a' });
        // The same function exported for worker jobs enforces origin/credentials.
        const url = api.formatSgpUrl(a.sgpBaseUrl, '/api/ura/clientes/');
        await assert.rejects(api.callSgpApi({ ...a.sgpParams, url: 'http://evil.synthetic.test/api/ura/clientes/' }));
        await assert.rejects(api.callSgpApi({ ...a.sgpParams, token: 'synthetic-b', url }));
        await assert.rejects(api.callSgpApi({ ...a.sgpParams, app: 'forged', url }));
        mixedDns = true; await assert.rejects(api.callSgpApi({ ...a.sgpParams, url })); mixedDns = false;
        failLookup = true; await assert.rejects(api.callSgpApi({ ...a.sgpParams, url })); failLookup = false;
        assert.equal(received.length, count);
        for (const path of ['/api/ura/clientes/', '/api/ura/liberacaopromessa/', '/api/fttx/onu/list/']) await api.callSgpApi({ ...a.sgpParams, url: api.formatSgpUrl(a.sgpBaseUrl, path) });
        assert.ok(received.at(-1).url.includes('token=synthetic-a')); assert.equal(received.at(-1).method, 'GET');
        redirect = true; await assert.rejects(api.callSgpApi({ ...a.sgpParams, url }));
        assert.equal(received.length, count + 4);
        assert.ok(!JSON.stringify(received).includes('synthetic-global-never-send'));
        assert.ok(!JSON.stringify(received).includes('forged'));
    } finally {
        server.closeAllConnections(); await new Promise(resolve => server.close(resolve));
        upstreamServer.closeAllConnections(); await new Promise(resolve => upstreamServer.close(resolve));
        for (const [key, value] of Object.entries(before)) if (value === undefined) delete process.env[key]; else process.env[key] = value;
    }
});
