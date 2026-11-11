import { afterEach, beforeEach, expect, it, vi } from 'vitest';
import type { User } from 'firebase/auth';
import { clearDashboardPrefetch, fetchDashboard } from './dashboard';

const fetchMock = vi.fn();
const user = (uid: string) => ({ uid, getIdToken: async () => `test-${uid}` }) as User;
beforeEach(() => {
  clearDashboardPrefetch();
  vi.stubGlobal('window', { location: { protocol: 'https:', hostname: 'panel.test', port: '', origin: 'https://panel.test' } });
  vi.stubGlobal('fetch', fetchMock); fetchMock.mockReset();
});
afterEach(() => { vi.unstubAllGlobals(); vi.useRealTimers(); });

it('shares the authenticated prefetch with the dashboard mount', async () => {
  let resolve!: (response: Response) => void;
  fetchMock.mockReturnValue(new Promise<Response>(done => { resolve = done; }));
  const prefetched = fetchDashboard(user('a'), 'provider-a');
  const mounted = fetchDashboard(user('a'), 'provider-a');
  expect(mounted).toBe(prefetched);
  await Promise.resolve();
  resolve(new Response(JSON.stringify({ data: { stats: { totalClients: 8 } } })));
  expect(await mounted).toEqual({ stats: { totalClients: 8 } });
  expect(fetchMock).toHaveBeenCalledTimes(1);
});
it('does not reuse data for another user or provider, and drops it on sign-out', async () => {
  fetchMock.mockImplementation(async () => new Response(JSON.stringify({ data: {} })));
  await fetchDashboard(user('a'), 'one'); await fetchDashboard(user('b'), 'one'); await fetchDashboard(user('a'), 'two');
  clearDashboardPrefetch(); await fetchDashboard(user('a'), 'one');
  expect(fetchMock).toHaveBeenCalledTimes(4);
});
it('retries failed requests and expires completed prefetches', async () => {
  fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({ error: { message: 'Temporário' } }), { status: 503 }));
  await expect(fetchDashboard(user('a'))).rejects.toThrow('Temporário');
  fetchMock.mockImplementation(async () => new Response(JSON.stringify({ data: {} })));
  await fetchDashboard(user('a'));
  const now = Date.now(); vi.spyOn(Date, 'now').mockReturnValue(now + 3000);
  await fetchDashboard(user('a'));
  expect(fetchMock).toHaveBeenCalledTimes(3);
  vi.restoreAllMocks();
});
