import { afterEach, expect, it, vi } from 'vitest';
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
  await expect(forwardGenerateApk(request)).rejects.toMatchObject({ code: status === 503 ? 'failed-precondition' : 'permission-denied' });
});
it('forwards bearer only to fixed builder with async polling contract and sanitized result', async () => {
  state.endpoint = 'https://fixed.test/apk-builder';
  const fetcher = vi.fn(async (_url: URL, _options: any) => ({ ok: true, json: async () => ({ success: true, jobId: 'job', status: 'running', logs: 'private' }) }));
  vi.stubGlobal('fetch', fetcher);
  expect(await forwardGenerateApk(request)).toEqual({ success: true, jobId: 'job', status: 'running' });
  expect(String(fetcher.mock.calls[0][0])).toBe('https://fixed.test/apk-builder/generate-apk');
  expect(JSON.parse(fetcher.mock.calls[0][1].body)).toEqual({ providerId: 'a', appName: 'A', logoUrl: 'https://logo.test', format: 'apk', async: true });
});
