import { test, expect, vi } from 'vitest';
import { createServer, type Server } from 'node:http';
import { generateKeyPairSync, sign, verify } from 'node:crypto';
import { performance, monitorEventLoopDelay } from 'node:perf_hooks';
import { writeFileSync } from 'node:fs';

// No Firebase users, production records or real SGP are touched by this harness.
const fixture = vi.hoisted(() => ({ documents: new Map<string, any>(), mockUrl: '', publicKey: null as any, identities: new Map<string, any>(), authChecks: 0 }));
vi.mock('../src/services/firebaseAdmin', () => ({
  firestore: { collection: (name: string) => ({ doc: (id: string) => ({
    get: async () => ({ exists: fixture.documents.has(`${name}/${id}`), data: () => fixture.documents.get(`${name}/${id}`) }),
    collection: (child: string) => ({ doc: (key: string) => ({ get: async () => ({
      exists: fixture.documents.has(`${name}/${id}/${child}/${key}`), data: () => fixture.documents.get(`${name}/${id}/${child}/${key}`),
    }) }) }),
  }) }) },
  firebaseAuth: { getUser: async (uid: string) => { fixture.authChecks++; await new Promise(resolve => setTimeout(resolve, Number(process.env.AUTH_LATENCY_MS || 0))); return { uid, customClaims: fixture.identities.get(uid), disabled: false }; }, verifyIdToken: async (token: string, revoked: boolean) => {
    const [header, payload, signature] = token.split('.');
    if (!verify('RSA-SHA256', Buffer.from(`${header}.${payload}`), fixture.publicKey, Buffer.from(signature, 'base64url'))) throw new Error('Invalid test JWT');
    const claims = JSON.parse(Buffer.from(payload, 'base64url').toString());
    if (claims.exp < Date.now() / 1000) throw new Error('Expired test JWT');
    if (!revoked) throw Error('Revocation checking is required');
    fixture.authChecks++; await new Promise(resolve => setTimeout(resolve, Number(process.env.AUTH_LATENCY_MS || 0)));
    return claims;
  } },
}));
// Only the outbound transport is replaced. Real coordinator, Redis limits,
// caches, HTTP routes and cryptographic verification remain in the workload.
vi.mock('../src/services/sgp-outbound', () => ({ default: {
  parseSgpUrl: (url: string) => new URL(url),
  assertSafeSgpBaseUrl: async (url: string) => url,
  request: async (url: string, body: unknown) => {
    const response = await fetch(`${fixture.mockUrl}${new URL(url).pathname}`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
    });
    return { data: await response.json(), status: response.status };
  },
} }));
async function listen(server: Server) {
  await new Promise<void>(resolve => server.listen(0, '127.0.0.1', resolve));
  return `http://127.0.0.1:${(server.address() as any).port}`;
}
async function close(server: Server) {
  server.closeAllConnections();
  await new Promise<void>((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
}

test('HTTP API workload for 100 tenants and a synthetic 500000-subscriber identity space', async () => {
  const redisUrl = process.env.REDIS_TEST_URL;
  if (!redisUrl || !['127.0.0.1', 'localhost'].includes(new URL(redisUrl).hostname)) throw new Error('Use an isolated loopback REDIS_TEST_URL.');
  process.env.REDIS_URL = redisUrl; process.env.REDIS_CACHE_URL = redisUrl;
  process.env.NODE_ENV = 'production';
  const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 }); fixture.publicKey = publicKey;
  const namespace = `capacity-${Date.now()}`;
  const tenants = 100, subscriberPool = 500000;
  const subscriber = (index: number) => { if (index < 0 || index >= subscriberPool) throw Error('Fixture index out of range'); return { providerId: `${namespace}-p${index % tenants}`, cpfCnpj: String(Math.floor(index / tenants)).padStart(11, '0') }; };
  // The same CPF exists in different tenants to exercise isolation.
  for (let index = 0; index < tenants; index++) {
    const id = `${namespace}-p${index}`;
    fixture.documents.set(`provedores/${id}`, { name: id });
    fixture.documents.set(`provedores/${id}/secrets/sgp`, { integrations: { apiToken: id, appName: 'capacity', sgpBaseUrl: `https://${id}.sgp.test` } });
  }
  const tokens = new Map<number, string>();
  function token(index: number) {
    if (!tokens.has(index)) {
      const user = subscriber(index);
      const body = Buffer.from(JSON.stringify({ ...user, role: 'subscriber', uid: `${namespace}-${index}`, exp: Math.floor(Date.now() / 1000) + 3600 })).toString('base64url');
      fixture.identities.set(`${namespace}-${index}`, { ...user, role: 'subscriber' });
      const input = `${Buffer.from('{"alg":"RS256","typ":"JWT"}').toString('base64url')}.${body}`;
      tokens.set(index, `${input}.${sign('RSA-SHA256', Buffer.from(input), privateKey).toString('base64url')}`);
    }
    return tokens.get(index)!;
  }
  let latency = 50, upstreamCalls = 0, active = 0, peak = 0;
  const tenantActive = new Map<string, number>(); let tenantPeak = 0;
  const mock = createServer(async (req, res) => {
    const buffers = []; for await (const chunk of req) buffers.push(chunk);
    const body = JSON.parse(Buffer.concat(buffers).toString());
    const id = body.token || body.senha;
    upstreamCalls++; active++; peak = Math.max(peak, active);
    tenantActive.set(id, (tenantActive.get(id) || 0) + 1); tenantPeak = Math.max(tenantPeak, tenantActive.get(id)!);
    await new Promise(resolve => setTimeout(resolve, latency));
    const value = req.url?.includes('consultacliente') ? { contratos: [{ contratoId: 1, contratoCentralSenha: body.token,
      razaoSocial: `${body.token}:${body.cpfcnpj}`, servico_plano: '500 MEGA', contratoValorAberto: 0 }] } : { online: true };
    res.setHeader('content-type', 'application/json'); res.end(JSON.stringify(value));
    active--; tenantActive.set(id, tenantActive.get(id)! - 1);
  });
  fixture.mockUrl = await listen(mock);
  const { createApp } = await import('../src/app');
  const { redis, cacheRedis } = await import('../src/services/redis');
  const api = createServer(createApp()); const base = await listen(api);
  const results: any[] = [];
  async function workload(name: string, requests: number, concurrency: number, start: number, repeated = false, concentrated = false) {
    const indices = Array.from({length:requests}, (_, current) => start + (repeated ? current % tenants : concentrated ? Math.floor(current / 10) * tenants + current % 10 : current));
    // Token signing is load-generator setup, not server latency.
    indices.forEach(index => token(index));
    await new Promise(resolve => setTimeout(resolve, 20));
    const loop = monitorEventLoopDelay({ resolution: 20 }); loop.enable();
    const authBefore = fixture.authChecks;
    const before = upstreamCalls, byStatus = new Map<number, number[]>(), durations: number[] = [], statuses: Record<number, number> = {};
    let next = 0, mismatches = 0; const began = performance.now();
    await Promise.all(Array.from({ length: concurrency }, async () => {
      while (next < requests) {
        const current = next++, index = indices[current];
        const user = subscriber(index), beganRequest = performance.now();
        const response = await fetch(`${base}/getClientData`, { method: 'POST', headers: { authorization: `Bearer ${token(index)}`, 'content-type': 'application/json' }, body: JSON.stringify({ cpfCnpj: user.cpfCnpj }) });
        const body = await response.json(); statuses[response.status] = (statuses[response.status] || 0) + 1;
        if (response.ok && body.data?.userName !== `${user.providerId}:${user.cpfCnpj}`) mismatches++;
        const duration = performance.now() - beganRequest; durations.push(duration);
        const group = byStatus.get(response.status) || []; group.push(duration); byStatus.set(response.status, group);
      }
    }));
    durations.sort((a, b) => a - b);
    const elapsedSeconds = (performance.now() - began) / 1000;
    loop.disable();
    const result = { name, requests, concurrency, eventLoopP95Ms: loop.percentile(95) / 1e6, eventLoopMaxMs: loop.max / 1e6, mockSgpLatencyMs: latency, statuses, upstreamCalls: upstreamCalls - before,
      p50Ms: durations[Math.ceil(requests * .5) - 1], p95Ms: durations[Math.ceil(requests * .95) - 1], p99Ms: durations[Math.ceil(requests * .99) - 1],
      elapsedSeconds, requestsPerSecond: requests / elapsedSeconds, isolationMismatches: mismatches, rssMiB: process.memoryUsage().rss / 1048576, authAccountLookups: fixture.authChecks - authBefore,
      latencyByStatus: Object.fromEntries([...byStatus].map(([status, values]) => { values.sort((a,b) => a-b); return [status, { count: values.length, p95Ms: values[Math.ceil(values.length * .95)-1] }]; })) };
    results.push(result); console.log(JSON.stringify(result)); expect(mismatches).toBe(0);
    return result;
  }
  try {
    expect((await workload('warmup', tenants, 25, 0)).statuses).toEqual({ 200: tenants });
    const hot = await workload('repeated-read-burst', 2000, 100, 0, true);
    expect(hot.statuses).toEqual({ 200: 2000 }); expect(hot.upstreamCalls).toBe(0);
    expect((await workload('uncached-distinct-subscribers', 1000, 100, 1000)).statuses).toEqual({ 200: 1000 });
    latency = 500;
    expect((await workload('slow-sgp', 400, 100, 10000)).statuses).toEqual({ 200: 400 });
    const overload = await workload('concentrated-overload-protection', 1000, 200, 20000, false, true);
    expect(overload.statuses[503]).toBeGreaterThan(0); expect(Object.keys(overload.statuses).every(status => ['200', '503'].includes(status))).toBe(true);
    expect(tenantPeak).toBeLessThanOrEqual(4);
    latency = 50;
    const quotaStatuses: Record<number, number> = {};
    await Promise.all(Array.from({ length: 125 }, async () => {
      const response = await fetch(`${base}/getClientData`, { method: 'POST', headers: { authorization: `Bearer ${token(60000)}`, 'content-type': 'application/json' }, body: JSON.stringify({ cpfCnpj: subscriber(60000).cpfCnpj }) });
      await response.arrayBuffer(); quotaStatuses[response.status] = (quotaStatuses[response.status] || 0) + 1;
    }));
    expect(quotaStatuses).toEqual({ 200: 120, 429: 5 });
    expect((await workload('peer-after-user-quota', 1, 1, 60001)).statuses).toEqual({ 200: 1 });
    results.push({ name: 'individual-quota', requests: 125, statuses: quotaStatuses });
    const denied = await fetch(`${base}/getClientData`, { method: 'POST', headers: { authorization: `Bearer ${token(50000)}`, 'content-type': 'application/json' }, body: JSON.stringify({ cpfCnpj: subscriber(50100).cpfCnpj }) });
    expect(denied.status).toBe(403);
  } finally {
    await close(api); await close(mock); await redis?.quit(); await cacheRedis?.quit();
    const report = { recordedAt: new Date().toISOString(), kind: 'isolated-http-capacity', providers: tenants, syntheticSubscriberPool: subscriberPool, simulatedAuthLookupMs: Number(process.env.AUTH_LATENCY_MS || 0), peakUpstreamConcurrency: peak, peakPerTenant: tenantPeak, results,
      limitation: 'Real API HTTP, RSA verification, Redis/cache/limits; mocked Firestore and account authority, optional fixed latency on both Auth lookups, and local HTTP SGP. 500000 is a generated identity space, not a populated database. Excludes cloud latency, real upstream throughput, TLS ingress, Flutter devices and production background jobs. Not production capacity certification.' };
    writeFileSync(process.env.CAPACITY_REPORT || '/tmp/painel-capacity-report.json', JSON.stringify(report, null, 2), { mode: 0o600 });
  }
});
