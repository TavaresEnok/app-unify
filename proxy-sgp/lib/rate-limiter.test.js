'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createRateLimiter, INCR_WITH_TTL_SCRIPT } = require('./rate-limiter');

// Redis falso que emula a semântica do script (INCR, PTTL, PEXPIRE se sem TTL).
function fakeRedis(clock) {
    const store = new Map();
    return {
        store,
        evalCalls: 0,
        async eval(script, numKeys, key, windowMs) {
            assert.equal(script, INCR_WITH_TTL_SCRIPT);
            assert.equal(numKeys, 1);
            this.evalCalls++;
            let entry = store.get(key);
            if (entry && entry.expiresAt !== null && entry.expiresAt <= clock.now) {
                store.delete(key);
                entry = undefined;
            }
            if (!entry) {
                entry = { count: 0, expiresAt: null };
                store.set(key, entry);
            }
            entry.count++;
            if (entry.expiresAt === null) entry.expiresAt = clock.now + Number(windowMs);
            return [entry.count, entry.expiresAt - clock.now];
        },
    };
}

function fakeRes() {
    return {
        statusCode: 200,
        headers: {},
        body: undefined,
        set(name, value) { this.headers[name] = value; return this; },
        status(code) { this.statusCode = code; return this; },
        json(body) { this.body = body; return this; },
    };
}

async function hit(limiter, path = '/check-cpf', ip = '10.0.0.1') {
    const res = fakeRes();
    let nextCalled = false;
    await limiter({ path, ip, headers: {} }, res, () => { nextCalled = true; });
    return { res, nextCalled };
}

test('blocks after maxRequests and recovers once the Redis window expires', async () => {
    const clock = { now: 0 };
    const redis = fakeRedis(clock);
    const limiter = createRateLimiter({ getRedis: () => redis, windowMs: 1000, maxRequests: 2, now: () => clock.now });

    assert.equal((await hit(limiter)).nextCalled, true);
    assert.equal((await hit(limiter)).nextCalled, true);
    const blocked = await hit(limiter);
    assert.equal(blocked.nextCalled, false);
    assert.equal(blocked.res.statusCode, 429);
    assert.equal(blocked.res.headers['Retry-After'], '1');

    clock.now = 1001;
    assert.equal((await hit(limiter)).nextCalled, true);
});

test('heals a key left without TTL instead of blocking the client forever', async () => {
    const clock = { now: 0 };
    const redis = fakeRedis(clock);
    redis.store.set('rl:::1', { count: 45677, expiresAt: null });
    const limiter = createRateLimiter({ getRedis: () => redis, windowMs: 1000, maxRequests: 2, now: () => clock.now });

    const blocked = await hit(limiter, '/check-cpf', '::1');
    assert.equal(blocked.res.statusCode, 429);
    assert.equal(blocked.res.body.error.retryAfter, 1);
    assert.equal(redis.store.get('rl:::1').expiresAt, 1000);

    clock.now = 1001;
    assert.equal((await hit(limiter, '/check-cpf', '::1')).nextCalled, true);
});

test('never rate limits /health and /ready', async () => {
    const clock = { now: 0 };
    const redis = fakeRedis(clock);
    const limiter = createRateLimiter({ getRedis: () => redis, windowMs: 1000, maxRequests: 1, now: () => clock.now });

    for (let i = 0; i < 5; i++) {
        assert.equal((await hit(limiter, '/health')).nextCalled, true);
        assert.equal((await hit(limiter, '/ready')).nextCalled, true);
    }
    assert.equal(redis.evalCalls, 0);
});

test('falls back to in-memory when Redis is unavailable or fails', async () => {
    const clock = { now: 0 };
    const failing = { async eval() { throw new Error('connection lost'); } };
    for (const getRedis of [() => null, () => failing]) {
        const limiter = createRateLimiter({ getRedis, windowMs: 1000, maxRequests: 1, now: () => clock.now });
        clock.now = 0;
        assert.equal((await hit(limiter)).nextCalled, true);
        assert.equal((await hit(limiter)).res.statusCode, 429);
        clock.now = 1001;
        assert.equal((await hit(limiter)).nextCalled, true);
    }
});
