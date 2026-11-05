import { afterEach, expect, it, vi } from 'vitest';
import type { User } from 'firebase/auth';
import { startLoginTiming, markPanelAuthReady, markDashboardRequest, markDashboardResponse, reportPanelReady } from './panelTiming';

afterEach(() => { vi.restoreAllMocks(); vi.unstubAllGlobals(); });
it('reports numeric phases once without sending account or subscriber fields', async () => {
  let now = 100;
  vi.spyOn(performance, 'now').mockImplementation(() => now);
  vi.stubGlobal('window', { location: { protocol: 'https:', hostname: 'panel.test', port: '', origin: 'https://panel.test' } });
  const post = vi.fn().mockResolvedValue(new Response(null, { status: 204 })); vi.stubGlobal('fetch', post);
  const user = { uid: 'private-uid', email: 'private@example.test', getIdToken: async () => 'fixture-token' } as User;
  startLoginTiming(); now = 800; markPanelAuthReady(); markDashboardRequest(); now = 1200; markDashboardResponse(); now = 1300;
  reportPanelReady(user); reportPanelReady(user); await Promise.resolve();
  expect(post).toHaveBeenCalledTimes(1);
  expect(JSON.parse(post.mock.calls[0][1].body)).toEqual({ flow: 'login', totalMs: 1200, authMs: 700, apiMs: 400 });
});
