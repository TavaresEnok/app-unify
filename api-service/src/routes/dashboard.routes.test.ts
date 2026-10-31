import express from 'express';
import request from 'supertest';
import { beforeEach, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({ tokens: new Map<string, any>(), users: new Map<string, any>(), global: vi.fn(), provider: vi.fn(), getUser: vi.fn() }));
vi.mock('../services/firebaseAdmin', () => ({
  firestore: {},
  firebaseAuth: {
    verifyIdToken: async (token: string) => { const user = mocks.tokens.get(token); if (!user) throw Error('invalid'); return user; },
    getUser: (uid: string) => { mocks.getUser(uid); return Promise.resolve(mocks.users.get(uid)); },
  },
}));
vi.mock('../services/dashboardData', () => ({ loadGlobalDashboard: mocks.global, loadProviderDashboard: mocks.provider }));
let app: express.Express;
beforeEach(async () => {
  vi.resetModules(); vi.clearAllMocks(); mocks.tokens.clear(); mocks.users.clear();
  for (const [uid, claims] of [['root', { superAdmin: true }], ['admin-a', { role: 'providerAdmin', providerId: 'a' }], ['sub', { role: 'subscriber', providerId: 'a' }]] as const) {
    mocks.tokens.set(uid, { uid, ...claims }); mocks.users.set(uid, { uid, customClaims: claims, disabled: false });
  }
  mocks.global.mockResolvedValue({ stats: { providerCount: 2 }, chartData: [], recentTickets: [] });
  mocks.provider.mockImplementation(async (_db, providerId) => ({ stats: { totalClients: providerId === 'a' ? 10 : 99 }, recentTickets: [] }));
  const { dashboardRouter } = await import('./dashboard.routes');
  const { errorHandler } = await import('../middlewares/errorHandler');
  app = express(); app.use('/dashboard', dashboardRouter); app.use(errorHandler);
});
const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

it('serves dashboard reads directly and coalesces/caches reads after fresh role checks', async () => {
  const responses = await Promise.all([1, 2].map(() => request(app).get('/dashboard/panel').set(auth('root')).expect(200)));
  expect(responses[0].body.data.stats.providerCount).toBe(2);
  expect(responses[0].headers['cache-control']).toBe('private, no-store');
  expect(mocks.global).toHaveBeenCalledTimes(1); expect(mocks.getUser).toHaveBeenCalledTimes(2);
});
it('rejects anonymous, subscriber and provider access to the global dashboard', async () => {
  await request(app).get('/dashboard/panel').expect(401);
  for (const token of ['sub', 'admin-a']) await request(app).get('/dashboard/panel').set(auth(token)).expect(403);
  expect(mocks.global).not.toHaveBeenCalled();
});
it('isolates provider data even after another provider is cached', async () => {
  await request(app).get('/dashboard/panel/providers/b').set(auth('root')).expect(200);
  await request(app).get('/dashboard/panel/providers/b').set(auth('admin-a')).expect(403);
  const response = await request(app).get('/dashboard/panel/providers/a').set(auth('admin-a')).expect(200);
  expect(response.body.data.stats.totalClients).toBe(10);
});
it('rejects disabled/revoked accounts despite old tokens and cached dashboard data', async () => {
  await request(app).get('/dashboard/panel').set(auth('root')).expect(200);
  mocks.users.set('root', { disabled: true, customClaims: { superAdmin: true } });
  await request(app).get('/dashboard/panel').set(auth('root')).expect(403);
  mocks.users.set('root', { disabled: false, customClaims: { role: 'subscriber' } });
  await request(app).get('/dashboard/panel').set(auth('root')).expect(403);
  expect(mocks.global).toHaveBeenCalledTimes(1);
});
it('does not cache failures', async () => {
  mocks.global.mockRejectedValueOnce(Error('temporary'));
  await request(app).get('/dashboard/panel').set(auth('root')).expect(500);
  await request(app).get('/dashboard/panel').set(auth('root')).expect(200);
  expect(mocks.global).toHaveBeenCalledTimes(2);
});
