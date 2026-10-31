import express from 'express';
import request from 'supertest';
import { beforeEach, expect, it, vi } from 'vitest';
const state = vi.hoisted(() => ({ token: {} as any, current: {} as any, failure: '', checks: [] as boolean[] }));
vi.mock('../services/firebaseAdmin', () => ({ firebaseAuth: {
  verifyIdToken: async (_: string, revoked: boolean) => {
    state.checks.push(revoked);
    if (state.failure === 'revoked') throw Object.assign(Error(), { code: 'auth/id-token-revoked' });
    return state.token;
  },
  getUser: async () => { if (state.failure === 'outage') throw Error('private'); return state.current; },
} }));
import { verifyToken, verifyAdmin, canAccessProvider } from './auth';
import { errorHandler } from './errorHandler';
const app = express();
app.use((req, _res, next) => { req.user = { uid: 'forged', superAdmin: true } as any; next(); });
app.get('/:tenant', verifyToken, verifyAdmin, (req, res) => res.status(canAccessProvider(req, req.params.tenant) ? 200 : 403).json({ uid: req.user?.uid }));
app.use(errorHandler);
beforeEach(() => { state.token = { uid: 'a', role: 'providerAdmin', providerId: 'a' }; state.current = { uid: 'a', customClaims: { role: 'providerAdmin', providerId: 'a' } }; state.failure = ''; state.checks = []; });
const get = (tenant = 'a') => request(app).get('/' + tenant).set('Authorization', 'Bearer synthetic');
it('uses verified identity and current tenant, never preexisting req.user', async () => {
  expect((await get()).body.uid).toBe('a'); expect(state.checks).toEqual([true]);
  await get('b').expect(403); await request(app).get('/a').expect(401);
});
it.each(['revoked', 'disabled', 'removed', 'tenant', 'subscriber-old-admin', 'outage'])('denies %s without data', async mode => {
  if (mode === 'disabled') state.current.disabled = true;
  if (mode === 'removed') state.current.customClaims = {};
  if (mode === 'tenant') state.current.customClaims.providerId = 'b';
  if (mode === 'subscriber-old-admin') { state.token = { uid: 'a', superAdmin: true }; state.current.customClaims = { role: 'subscriber', providerId: 'a' }; }
  state.failure = mode;
  const result = await get();
  expect(result.status).toBe(mode === 'outage' ? 503 : ['disabled', 'revoked'].includes(mode) ? 401 : 403);
  if (mode === 'outage') expect(result.body.error.code).toBe('authorization-unavailable');
  expect(result.body.uid).toBeUndefined();
});
