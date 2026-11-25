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
        if (req.url === '/api/ura/titulos/' && new URLSearchParams(body).get('contrato') === '1') {
            const paid = new URLSearchParams(body).get('status') === 'pagos';
            return res.end(JSON.stringify({ titulos: paid ? [] : [
                { id: 41, contrato: 1, valor: '102,47', dataVencimento: '2026-09-01', codigoPix: 'test-sep', link: 'https://example.test/sep' },
                { id: 42, contrato: 1, valor: '99.90', dataVencimento: '2026-10-01', codigoPix: 'test-oct', link: 'https://example.test/oct' },
                { id: 43, contrato: 2, valor: 15 },
            ] }));
        }
        res.end(JSON.stringify({ contratos: [{ contratoId: '1', contratoCentralSenha: 'synthetic-password', contratoStatus: 'Ativo' }], clientes: [], titulos: [] }));
    });
    upstreamServer.listen(0, '127.0.0.1'); await once(upstreamServer, 'listening');
    const port = upstreamServer.address().port;
    const base = `http://sgp.synthetic.test:${port}`;
    const reads = []; let lookupFailure = false;
    const providersMap = new Map();
    const secretsMap = new Map();
    const subscribersMap = new Map();
    const sgpClientsSet = new Set();
    const adminUsersMap = new Map();
    const issued = []; let authOutage = false;

    const before = {
        SGP_TOKEN: process.env.SGP_TOKEN,
        NODE_ENV: process.env.NODE_ENV,
        JWT_SECRET: process.env.JWT_SECRET,
        APP_SECRETS_KEY: process.env.APP_SECRETS_KEY,
    };
    process.env.SGP_TOKEN = 'synthetic-global-never-send';
    process.env.NODE_ENV = 'test';
    process.env.JWT_SECRET = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
    process.env.APP_SECRETS_KEY = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';
    const selfAuth = require('./self-auth');
    selfAuth.clearKeyCacheForTests();

    for (const provider of ['a', 'b', 'incomplete']) {
        providersMap.set(provider, { id: provider, details: { systemUrl: base, appName: 'public-forged' } });
        secretsMap.set(provider, selfAuth.encryptSecret(JSON.stringify({
            sgpBaseUrl: base,
            appName: `app-${provider}`,
            ...(provider !== 'incomplete' ? { apiToken: `synthetic-${provider}` } : {}),
        })));
    }
    for (const provider of ['a', 'b']) {
        adminUsersMap.set(`provider:${provider}`, {
            uid: `provider:${provider}`,
            email: `${provider}@synthetic.test`,
            role: 'providerAdmin',
            provider_id: provider,
            disabled: false,
            token_version: 1,
        });
        sgpClientsSet.add(`${provider}:12345678901`);
    }

    const transport = runtime.createSgpTransport({ lookup: async () => {
        if (failLookup) throw new Error('synthetic DNS failure');
        return mixedDns ? [{ address: '8.8.8.8', family: 4 }, { address: '127.0.0.1', family: 4 }] : [{ address: '8.8.8.8', family: 4 }];
    }, connect: options => {
        assert.equal(options.host, '8.8.8.8');
        const socket = net.connect({ host: '127.0.0.1', port });
        Object.defineProperty(socket, 'remoteAddress', { get: () => '8.8.8.8' }); return socket;
    } });
    class FakeRedis { on() {} connect() { return Promise.resolve(); } }
    class FakePool {
        on() {}
        async query(sql, params = []) {
            const text = String(sql).trim();
            reads.push(text);
            if (/^(CREATE|ALTER)/i.test(text)) return { rows: [] };
            if (/FROM\s+providers\s+p/i.test(text)) {
                if (lookupFailure) throw new Error('synthetic lookup failure');
                const providerId = params[0];
                if (!providersMap.has(providerId)) return { rows: [] };
                return { rows: [{ id: providerId, ciphertext: secretsMap.get(providerId) || null }] };
            }
            if (/FROM\s+admin_users\b/i.test(text)) {
                if (authOutage) throw Error('synthetic authority outage');
                const row = adminUsersMap.get(params[0]);
                return { rows: row ? [row] : [] };
            }
            if (/SELECT\s+1\s+FROM\s+subscribers\b/i.test(text)) {
                const [providerId, cpfCnpj] = params;
                const found = sgpClientsSet.has(`${providerId}:${cpfCnpj}`)
                    || Array.from(subscribersMap.values()).some(s => s.provider_id === providerId && s.cpfcnpj === cpfCnpj);
                return { rows: found ? [{ '?column?': 1 }] : [] };
            }
            if (/SELECT\s+uid,\s*provider_id,\s*cpfcnpj,\s*email,\s*disabled,\s*token_version\s+FROM\s+subscribers\b/i.test(text)) {
                if (authOutage) throw Error('synthetic authority outage');
                const row = subscribersMap.get(params[0]);
                return { rows: row ? [row] : [] };
            }
            if (/INSERT\s+INTO\s+subscribers\b/i.test(text)) {
                if (authOutage) throw Error('synthetic authority outage');
                const [uid, providerId, cpfCnpj, nome, plano, status, contractStatus, contratoId, email] = params;
                const existing = subscribersMap.get(uid);
                if (existing && (existing.provider_id !== providerId || existing.cpfcnpj !== cpfCnpj)) {
                    return { rows: [] };
                }
                const next = {
                    uid,
                    provider_id: providerId,
                    cpfcnpj: cpfCnpj,
                    nome,
                    plano,
                    status,
                    contract_status: contractStatus,
                    contrato_id: contratoId,
                    email: email || existing?.email || '',
                    disabled: existing ? existing.disabled : false,
                    token_version: existing ? existing.token_version : 1,
                };
                subscribersMap.set(uid, next);
                return { rows: [next] };
            }
            return { rows: [] };
        }
    }
    const load = Module._load;
    let api;
    try {
        Module._load = function(name, parent, ...args) {
            if (parent?.filename === require.resolve('../index')) {
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
    const tokenFor = (name) => {
        if (name === 'provider:a' || name === 'provider:b') {
            const p = name.slice(9);
            return selfAuth.signJwt({ uid: name, role: 'providerAdmin', providerId: p, tv: 1 });
        }
        if (name === 'old-admin') {
            return selfAuth.signJwt({ uid: 'subscriber:a:12345678901', role: 'subscriber', providerId: 'b', cpfCnpj: '12345678901', tv: 1 });
        }
        if (name === 'revoked') {
            return selfAuth.signJwt({ uid: 'subscriber:incomplete:12345678901', role: 'subscriber', providerId: 'incomplete', cpfCnpj: '12345678901', tv: 0 });
        }
        return selfAuth.signJwt({ uid: `subscriber:${name}:12345678901`, role: 'subscriber', providerId: name, cpfCnpj: '12345678901', tv: 1 });
    };
    const post = (path, body, token = 'a') => fetch(`http://127.0.0.1:${server.address().port}${path}`, { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tokenFor(token)}` }, body: JSON.stringify(body), signal: AbortSignal.timeout(3000) });
    try {
        // Exercise the historical subscriber login: CPF/CNPJ + provider only.
        // The central password is resolved server-side solely for SGP calls.
        for (const tenant of ['a', 'b']) for (const status of [true, false]) {
            online = status;
            const start = received.length;
            const result = await post('/check-cpf', { providerId: tenant, cpf: '12345678901' });
            assert.equal(result.status, 200);
            const payload = await result.json();
            assert.equal(payload.status, status ? 'Online' : 'Offline');
            assert.equal(payload.tokenType, 'jwt');
            assert.ok(typeof payload.accessToken === 'string' && payload.accessToken.split('.').length === 3);
            assert.equal(selfAuth.verifyJwt(payload.accessToken).role, 'subscriber');
            issued.push(selfAuth.verifyJwt(payload.accessToken).uid);
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
        const uid = 'subscriber:a:12345678901';
        const login = () => post('/check-cpf', { providerId: 'a', cpf: '12345678901' });
        const beforeDenied = issued.length;
        for (const role of ['superAdmin', 'providerAdmin']) {
            adminUsersMap.set(uid, { uid, role, provider_id: 'a', disabled: false, token_version: 1 });
            assert.equal((await login()).status, 403);
        }
        adminUsersMap.delete(uid);
        subscribersMap.set(uid, { uid, provider_id: 'b', cpfcnpj: '12345678901', disabled: false, token_version: 1 });
        assert.equal((await login()).status, 403);
        subscribersMap.set(uid, { uid, provider_id: 'a', cpfcnpj: '12345678901', disabled: true, token_version: 1 });
        assert.equal((await login()).status, 401);
        authOutage = true; assert.equal((await login()).status, 503); authOutage = false;
        assert.equal(issued.length, beforeDenied);
        subscribersMap.set(uid, { uid, provider_id: 'a', cpfcnpj: '12345678901', disabled: false, token_version: 1 });
        for (const provider of ['a', 'b']) {
            assert.equal((await post('/diagnostic/analyze', { cpfCnpj: '12345678901', user: { superAdmin: true } }, 'provider:' + provider)).status, 501);
            assert.equal((await post('/diagnostic/analyze', { cpfCnpj: '12345678901', providerId: provider === 'a' ? 'b' : 'a' }, 'provider:' + provider)).status, 403);
        }
        assert.equal((await post('/diagnostic/analyze', { cpfCnpj: '12345678901', providerId: 'b' }, 'old-admin')).status, 403);
        subscribersMap.get(uid).disabled = true;
        assert.equal((await post('/diagnostic/analyze', { cpfCnpj: '12345678901' })).status, 401);
        subscribersMap.get(uid).disabled = false;
        subscribersMap.set('subscriber:incomplete:12345678901', { uid: 'subscriber:incomplete:12345678901', provider_id: 'incomplete', cpfcnpj: '12345678901', disabled: false, token_version: 1 });
        assert.equal((await post('/diagnostic/analyze', { cpfCnpj: '12345678901' }, 'revoked')).status, 401);
        authOutage = true;
        const unavailable = await post('/diagnostic/analyze', { cpfCnpj: '12345678901' });
        assert.equal(unavailable.status, 503); assert.equal((await unavailable.json()).error.code, 'authorization-unavailable'); authOutage = false;
        // Login legitimately migrates a subscriber profile. Credential resolution
        // and authenticated reads below must still never derive tenant from CPF.
        reads.length = 0;
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
        const scoped = await post('/get-invoices', { cpfCnpj: '12345678901', contratoId: 1 });
        assert.equal(scoped.status, 200);
        assert.deepEqual((await scoped.json()).data.map(({ id, valor, pix_copia_cola, link }) =>
            [id, valor, pix_copia_cola, link]), [
            ['41', 102.47, 'test-sep', 'https://example.test/sep'],
            ['42', 99.90, 'test-oct', 'https://example.test/oct'],
        ]);
        const beforeInvalid = received.filter(row => row.url === '/api/ura/liberacaopromessa/').length;
        assert.equal((await post('/get-invoices', { cpfCnpj: '12345678901', contratoId: 999 })).status, 404);
        assert.equal((await post('/unlock-trust', { cpfCnpj: '12345678901', contratoId: 999 })).status, 409);
        assert.equal(received.filter(row => row.url === '/api/ura/liberacaopromessa/').length, beforeInvalid);
        const count = received.length;
        for (const forged of [{ token: 'forged' }, { app: 'forged' }, { sgpBaseUrl: 'http://127.0.0.1' }, { sgpParams: { token: 'forged' } }]) assert.equal((await post('/get-invoices', { cpfCnpj: '12345678901', ...forged })).status, 400);
        assert.equal((await post('/get-invoices', { cpfCnpj: '12345678901', providerId: 'b' })).status, 403);
        const readsBeforeCred = reads.length;
        await assert.rejects(api.ensureSgpCredentials({ cpfCnpj: '12345678901' }));
        assert.ok(!reads.slice(readsBeforeCred).some(q => /subscribers/i.test(q)));
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
        selfAuth.clearKeyCacheForTests();
        for (const [key, value] of Object.entries(before)) if (value === undefined) delete process.env[key]; else process.env[key] = value;
    }
});
