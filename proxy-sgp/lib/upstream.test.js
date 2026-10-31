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
