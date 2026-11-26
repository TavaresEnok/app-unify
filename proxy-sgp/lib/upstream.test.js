'use strict';
const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const Redis = require('ioredis');
const { createUpstream } = require('./upstream');
const enabled = Boolean(process.env.REDIS_TEST_URL);
const redis = enabled ? new Redis(process.env.REDIS_TEST_URL) : null;
after(async () => { if (redis) await redis.quit(); });
function input(provider, path = '/api/ura/titulos/', body = {}) {
    return { providerId: provider, url: `https://${provider}.example${path}`, body, ttl: 30000 };
}

test('missing coordination storage fails closed before upstream execution', async () => {
    let called = false;
    await assert.rejects(createUpstream({ getRedis: () => null }).execute(input('none'), async () => { called = true; }), { status: 503 });
    assert.equal(called, false);
});
test('100 concurrent identical reads share a single upstream request across instances', { skip: !enabled }, async () => {
    const first = createUpstream({ getRedis: () => redis });
    const second = createUpstream({ getRedis: () => redis });
    let calls = 0;
    const provider = `shared-${Date.now()}`;
    const results = await Promise.all(Array.from({ length: 100 }, (_, i) => (i % 2 ? first : second).execute(input(provider), async () => {
        calls++; await new Promise(resolve => setTimeout(resolve, 40)); return { provider };
    })));
    assert.equal(calls, 1);
    assert.ok(results.every(value => value.provider === provider));
});
test('provider concurrency is bounded and another provider remains available', { skip: !enabled }, async () => {
    const upstream = createUpstream({ getRedis: () => redis, maxPerProvider: 2 });
    const provider = `slow-${Date.now()}`;
    let release;
    const blocked = new Promise(resolve => { release = resolve; });
    let started = 0;
    const operation = async () => { started++; await blocked; return 'done'; };
    const first = upstream.execute({ ...input(provider), ttl: 0 }, operation);
    const second = upstream.execute({ ...input(provider), ttl: 0 }, operation);
    while (started < 2) await new Promise(resolve => setTimeout(resolve, 5));
    await assert.rejects(upstream.execute({ ...input(provider), ttl: 0 }, operation), { status: 503 });
    assert.equal(await upstream.execute(input(`healthy-${Date.now()}`), async () => 'ok'), 'ok');
    release(); await Promise.all([first, second]);
    assert.equal(await upstream.execute({ ...input(provider), ttl: 0 }, async () => 'released'), 'released');
});
test('successful mutation invalidates shared reads without invalidating another provider', { skip: !enabled }, async () => {
    const upstream = createUpstream({ getRedis: () => redis });
    const a = input(`mutation-${Date.now()}`), b = input(`other-${Date.now()}`);
    let calls = 0;
    const operation = async () => ++calls;
    assert.equal(await upstream.execute(a, operation), 1);
    assert.equal(await upstream.execute(a, operation), 1);
    await upstream.execute(b, async () => 'other');
    await upstream.execute({ ...a, url: a.url.replace('titulos', 'liberacaopromessa'), ttl: 0, mutate: true }, async () => true);
    assert.equal(await upstream.execute(a, operation), 2);
    assert.equal(await upstream.execute(b, async () => 'wrong'), 'other');
});
test('repeated upstream failures open the circuit for only the failing host', { skip: !enabled }, async () => {
    const upstream = createUpstream({ getRedis: () => redis });
    const data = { ...input(`failing-${Date.now()}`), ttl: 0 };
    for (let i = 0; i < 5; i++) await assert.rejects(upstream.execute(data, async () => { throw new Error('upstream down'); }));
    let calls = 0;
    await assert.rejects(upstream.execute(data, async () => { calls++; }), { status: 503 });
    assert.equal(calls, 0);
    assert.equal(await upstream.execute(input(`working-${Date.now()}`), async () => 'ok'), 'ok');
});

test('background work reserves capacity for interactive requests', { skip: !enabled }, async () => {
    const background = createUpstream({ getRedis: () => redis, maxPerProvider: 2, maxPerHost: 4 });
    const interactive = createUpstream({ getRedis: () => redis, maxPerProvider: 4, maxPerHost: 8 });
    const data = { ...input(`reserved-${Date.now()}`), ttl: 0 };
    let release;
    const wait = new Promise(resolve => { release = resolve; });
    let started = 0;
    const operation = async () => { started++; await wait; return 'ok'; };
    const jobs = [background.execute(data, operation), background.execute(data, operation)];
    try {
        while (started < 2) await new Promise(resolve => setTimeout(resolve, 5));
        await assert.rejects(background.execute(data, operation), { status: 503 });
        jobs.push(interactive.execute(data, operation), interactive.execute(data, operation));
        while (started < 4) await new Promise(resolve => setTimeout(resolve, 5));
        assert.equal(started, 4);
    } finally { release(); await Promise.all(jobs); }
});

// Redis mínimo em memória: suficiente para leituras sem cache (ttl 0).
function memoryRedis() {
    const kv = new Map(); const zsets = new Map();
    return {
        kv,
        async get(key) { return kv.has(key) ? kv.get(key) : null; },
        async set(key, value) { kv.set(key, String(value)); return 'OK'; },
        async del(key) { kv.delete(key); return 1; },
        async exists(key) { return kv.has(key) ? 1 : 0; },
        async incr(key) { const next = Number(kv.get(key) || 0) + 1; kv.set(key, String(next)); return next; },
        async expire() { return 1; },
        async zrem(key, member) { zsets.get(key)?.delete(member); return 1; },
        async eval(_script, _n, providerKey, hostKey, token, maxProvider, maxHost) {
            const p = zsets.get(providerKey) || new Set(); const h = zsets.get(hostKey) || new Set();
            if (p.size >= Number(maxProvider) || h.size >= Number(maxHost)) return 0;
            p.add(token); h.add(token); zsets.set(providerKey, p); zsets.set(hostKey, h); return 1;
        },
    };
}

test('DNS failures never open the ERP circuit breaker', async () => {
    const redis = memoryRedis();
    const upstream = createUpstream({ getRedis: () => redis });
    const data = { ...input('dns-provider'), ttl: 0 };
    for (let i = 0; i < 8; i++) {
        await assert.rejects(upstream.execute(data, async () => { throw Object.assign(new Error('dns'), { status: 503, dnsFailure: true }); }), { status: 503 });
    }
    assert.equal(await upstream.execute(data, async () => 'reachable'), 'reachable');
    assert.ok(![...redis.kv.keys()].some(key => key.startsWith('sgp:open:')));
    for (let i = 0; i < 5; i++) await assert.rejects(upstream.execute(data, async () => { throw new Error('connection reset'); }));
    assert.ok([...redis.kv.keys()].some(key => key.startsWith('sgp:open:')), 'real connection failures still open the breaker');
});

test('a full slot pool waits briefly for a free slot instead of failing at once', async () => {
    const redis = memoryRedis();
    const upstream = createUpstream({ getRedis: () => redis, maxPerProvider: 1, slotWaitMs: 1000, slotPollMs: 10 });
    const data = { ...input('busy-provider'), ttl: 0 };
    let release;
    const first = upstream.execute(data, () => new Promise(resolve => { release = resolve; }));
    await new Promise(resolve => setTimeout(resolve, 5));
    const second = upstream.execute(data, async () => 'second');
    setTimeout(() => release('first'), 50);
    assert.deepEqual(await Promise.all([first, second]), ['first', 'second']);
    const impatient = createUpstream({ getRedis: () => redis, maxPerProvider: 1, slotWaitMs: 0 });
    let hold;
    const holding = upstream.execute(data, () => new Promise(resolve => { hold = resolve; }));
    await new Promise(resolve => setTimeout(resolve, 5));
    await assert.rejects(impatient.execute(data, async () => 'x'), { status: 503 });
    hold('done'); await holding;
});

test('per-call limits raise the provider cap (IXC) and a full pool answers a friendly busy error', async () => {
    const redis = memoryRedis();
    const upstream = createUpstream({ getRedis: () => redis, maxPerProvider: 1, maxPerHost: 8, slotWaitMs: 0 });
    const data = { ...input('ixc-provider'), ttl: 0 };
    let release;
    const gate = new Promise(resolve => { release = resolve; });
    const held = [upstream.execute(data, () => gate)];
    await new Promise(resolve => setTimeout(resolve, 5));
    const busy = await upstream.execute(data, async () => 'x').then(() => null, error => error);
    assert.equal(busy.status, 503); assert.equal(busy.busy, true);
    assert.equal(busy.publicMessage, 'Muitos acessos agora. Tente novamente em alguns segundos.');
    const ixc = { ...data, limits: { maxPerProvider: 3, maxPerHost: 3 } };
    held.push(upstream.execute(ixc, () => gate), upstream.execute(ixc, () => gate));
    await new Promise(resolve => setTimeout(resolve, 5));
    await assert.rejects(upstream.execute(ixc, async () => 'x'), { status: 503, busy: true });
    release('ok'); await Promise.all(held);
});
