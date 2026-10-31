import { afterEach, expect, it, vi } from 'vitest';
import { createRequire } from 'node:module';
const { fixture } = createRequire(import.meta.url)('../../services/apk-builder/authorization-propagation.test.js');
const state = vi.hoisted(() => ({ endpoint: '' }));
vi.mock('./app/config', () => ({ apkBuilderUrl: { value: () => state.endpoint } }));
import { forwardGenerateApk } from './callables/generateApk';
const request = { auth: { uid: 'synthetic', token: { superAdmin: true } }, rawRequest: { headers: { authorization: 'Bearer synthetic' } }, data: { providerId: 'a', appName: 'A', logoUrl: 'https://logo.test', format: 'apk', endpoint: 'https://evil.test' } };
afterEach(() => { vi.unstubAllGlobals(); state.endpoint = ''; });
it('fails closed without configuration or authentication; no Python fallback', async () => {
  const fetcher = vi.fn(); vi.stubGlobal('fetch', fetcher);
  await expect(forwardGenerateApk(request)).rejects.toMatchObject({ code: 'failed-precondition' });
  state.endpoint = 'https://fixed.test/apk-builder';
  await expect(forwardGenerateApk({ ...request, auth: undefined })).rejects.toMatchObject({ code: 'permission-denied' });
  expect(fetcher).not.toHaveBeenCalled();
});
it.each([401, 403, 503])('preserves denial/unavailability from restricted flow %s', async status => {
  state.endpoint = 'https://fixed.test/apk-builder'; vi.stubGlobal('fetch', vi.fn(async () => ({ ok: false, status })));
  await expect(forwardGenerateApk(request)).rejects.toMatchObject({ code: status === 503 ? 'unavailable' : 'permission-denied' });
});
it('forwards bearer only to fixed builder with async polling contract and sanitized result', async () => {
  state.endpoint = 'https://fixed.test/apk-builder';
  const fetcher = vi.fn(async (_url: URL, _options: any) => ({ ok: true, json: async () => ({ success: true, jobId: 'job', status: 'running', logs: 'private' }) }));
  vi.stubGlobal('fetch', fetcher);
  expect(await forwardGenerateApk(request)).toEqual({ success: true, jobId: 'job', status: 'running' });
  expect(String(fetcher.mock.calls[0][0])).toBe('https://fixed.test/apk-builder/generate-apk');
  expect(JSON.parse(fetcher.mock.calls[0][1].body)).toEqual({ providerId: 'a', appName: 'A', logoUrl: 'https://logo.test', format: 'apk', async: true });
});

it.each([503, 'transport', 'timeout', 'invalid-json', 'invalid-body', 401, 403, 'binding', 'disabled', 'revoked', 'old-claim', 'provider', 'subscriber', 'tenant-b'])('real callable → HTTP builder → simulated authority preserves %s', async (failure) => {
  const cleanup: Array<() => Promise<void>> = [];
  const f = await fixture({ after: (fn: () => Promise<void>) => cleanup.push(fn) });
  const nativeFetch = globalThis.fetch;
  state.endpoint = 'https://fixed.test/apk-builder';
  if (failure === 'binding') f.state.badBinding = true;
  else if (['disabled', 'revoked', 'old-claim', 'provider', 'subscriber', 'tenant-b'].includes(String(failure))) f.state.access = failure;
  else f.state.failure = failure;
  vi.stubGlobal('fetch', (url: URL, options: RequestInit) => {
    expect(String(url)).toBe('https://fixed.test/apk-builder/generate-apk');
    return nativeFetch(f.base + '/generate-apk', options);
  });
  try {
    await expect(forwardGenerateApk({ ...request, rawRequest: { headers: { authorization: 'Bearer saas' } }, data: { providerId: 'isp-a', appName: 'Synthetic ISP', logoUrl: 'https://logo.test/a' } })).rejects.toMatchObject({
      code: [503, 'transport', 'timeout', 'invalid-json', 'invalid-body'].includes(failure) ? 'unavailable' : 'permission-denied',
    });
    expect(f.state.spawns).toBe(0); expect(f.state.downloads).toBe(0);
  } finally { for (const fn of cleanup) await fn(); }
});

it('real callable and HTTP builder accept the current SaaS authority binding', async () => {
  const cleanup: Array<() => Promise<void>> = [];
  const f = await fixture({ after: (fn: () => Promise<void>) => cleanup.push(fn) });
  f.state.defer = true;
  const nativeFetch = globalThis.fetch;
  state.endpoint = 'https://fixed.test/apk-builder';
  vi.stubGlobal('fetch', (_url: URL, options: RequestInit) => nativeFetch(f.base + '/generate-apk', options));
  try {
    const result = await forwardGenerateApk({ ...request, rawRequest: { headers: { authorization: 'Bearer saas' } }, data: { providerId: 'isp-a', appName: 'Synthetic ISP', logoUrl: 'https://logo.test/a' } });
    expect(result).toMatchObject({ success: true, status: 'running' });
    expect(f.state.spawns).toBe(1);
    expect(f.state.checks.map((check: any) => check.purpose)).toEqual(['request', 'spawn', 'spawn']);
    await nativeFetch(f.base + '/jobs/' + result.jobId + '/cancel', { method: 'POST', headers: { Authorization: 'Bearer saas' } });
  } finally { for (const fn of cleanup) await fn(); }
});
