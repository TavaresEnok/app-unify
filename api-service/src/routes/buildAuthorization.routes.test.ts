import express from 'express';
import request from 'supertest';
import { beforeEach, expect, it, vi } from 'vitest';
const state = vi.hoisted(() => ({ mode: 'saas', checked: [] as boolean[] }));
vi.mock('../services/firebaseAdmin', () => ({ firebaseAuth: {
  verifyIdToken: async (_token: string, revoked: boolean) => {
    state.checked.push(revoked);
    if (['revoked', 'outage'].includes(state.mode)) throw Error('unavailable');
    return { uid: 'real-user', superAdmin: true, auth_time: Math.floor(Date.now()/1000) - (state.mode === 'stale' ? 600 : 0) };
  },
  getUser: async () => ({ uid: 'real-user', disabled: state.mode === 'disabled', customClaims: { superAdmin: ['saas', 'stale', 'disabled'].includes(state.mode) } }),
}, firestore: { collection: () => ({ doc: (tenant: string) => ({ get: async () => ({ exists: tenant === 'a', data: () => ({ active: true }) }) }) }) } }));
import { buildAuthorizationRouter } from './buildAuthorization.routes';
const app = express(); app.use(express.json()); app.use('/internal/builds', buildAuthorizationRouter);
const post = (extra = {}) => request(app).post('/internal/builds/authorize').set('Authorization', 'Bearer synthetic').send({ providerId: 'a', jobId: 'job-1', purpose: 'request', ...extra });
beforeEach(() => { state.mode = 'saas'; state.checked = []; });
it.each(['subscriber', 'provider', 'old-claim', 'disabled', 'revoked', 'stale', 'outage'])('denies %s using current identity', async mode => {
  state.mode = mode;
  expect((await post({ superAdmin: true, tenant: 'a' })).status).toBe(403); expect(state.checked).toEqual([true]);
});
it('binds SaaS authorization to existing tenant, job and purpose', async () => {
  expect((await post()).body).toEqual({ authorized: true, uid: 'real-user', providerId: 'a', jobId: 'job-1', purpose: 'request' });
  expect((await post({ purpose: 'spawn' })).status).toBe(200);
  expect((await post({ purpose: 'publish' })).status).toBe(200);
  expect((await post({ purpose: 'publish', jobId: 'unaccepted' })).status).toBe(403);
  expect((await post({ purpose: 'publish', providerId: 'b' })).status).toBe(403);
  state.mode = 'revoked'; expect((await post({ purpose: 'publish' })).status).toBe(403); state.mode = 'saas';
  expect((await post({ providerId: 'b' })).status).toBe(403);
  expect((await post({ purpose: 'sign-anything' })).status).toBe(400);
  expect((await request(app).post('/internal/builds/authorize').send({ providerId: 'a', jobId: 'j', purpose: 'spawn' })).status).toBe(403);
});
