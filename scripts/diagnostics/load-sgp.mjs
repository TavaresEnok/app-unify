// Synthetic workload against an isolated Redis and simulated SGP. Never calls production SGP.
import { createRequire } from 'node:module';
import { performance } from 'node:perf_hooks';
import assert from 'node:assert/strict';
const require = createRequire(new URL('../../proxy-sgp/package.json', import.meta.url));
const Redis = require('ioredis');
const { createUpstream } = require('../shared/runtime/upstream.js');
if (!process.env.REDIS_TEST_URL) throw new Error('Use REDIS_TEST_URL com Redis isolado para o teste.');
const redis = new Redis(process.env.REDIS_TEST_URL);
const upstream = createUpstream({ getRedis: () => redis });
const namespace = `load-${Date.now()}`;
const latency = Number(process.env.MOCK_SGP_LATENCY_MS || 50);
const total = Number(process.env.LOAD_REQUESTS || 2000);
const concurrency = Number(process.env.LOAD_CONCURRENCY || 100);
let next = 0, calls = 0, failures = 0;
const durations = [];
const started = performance.now();
try {
  await Promise.all(Array.from({ length: concurrency }, async () => {
    while (next < total) {
      const index = next++;
      const provider = `${namespace}-provider-${index % 20}`;
      const start = performance.now();
      try {
        const data = await upstream.execute({ providerId: provider, url: `https://${provider}.example/api/ura/titulos/`, body: { client: index % 20 }, ttl: 30000 }, async () => {
          calls++; await new Promise(resolve => setTimeout(resolve, latency)); return { provider };
        });
        assert.equal(data.provider, provider);
      } catch { failures++; }
      durations.push(performance.now() - start);
    }
  }));
  durations.sort((a, b) => a - b);
  const seconds = (performance.now() - started) / 1000;
  console.log(JSON.stringify({ kind: 'synthetic-cache-burst', providers: 20, requests: total, concurrency, mockLatencyMs: latency,
    upstreamCalls: calls, failures, elapsedSeconds: seconds, requestsPerSecond: total / seconds,
    p95Ms: durations[Math.ceil(durations.length * 0.95) - 1],
    limitation: 'Tests caching and isolation with repeated reads; does not establish production capacity or 100k concurrent users.' }, null, 2));
  assert.equal(failures, 0);
  assert.equal(calls, 20);
} finally { await redis.quit(); }
