import { afterEach, beforeEach, expect, it, vi } from 'vitest';
const state = vi.hoisted(() => ({ write: vi.fn(), listen: vi.fn(), stop: vi.fn(), callback: undefined as any, current: null as any }));
vi.mock('firebase/auth', () => ({ getAuth: () => ({ currentUser: state.current }) }));
vi.mock('firebase/firestore', () => ({ collection: () => ({}), doc: (...args: any[]) => ({ id: args[2] || 'request-id' }), serverTimestamp: () => 'server-time',
  setDoc: state.write, onSnapshot: (_ref: any, callback: any) => { state.callback = callback; state.listen(); return state.stop; } }));
import { callFunctionRequest } from './functionRequests';
const claims = { auth_time: 100, iat: 101, role: 'providerAdmin', providerId: 'a' };
beforeEach(() => {
  vi.clearAllMocks(); state.write.mockResolvedValue(undefined);
  state.current = { uid: 'u', getIdTokenResult: vi.fn().mockResolvedValue({ claims }) };
  vi.stubGlobal('window', { setTimeout });
});
afterEach(() => vi.unstubAllGlobals());
it('emits session metadata from Firebase identity, fixed tenant and server timestamp', async () => {
  const pending = callFunctionRequest({} as any, 'GET_PROVIDER_DASHBOARD_DATA', { providerId: 'b' }, { requesterUid: 'u', providerId: 'a', forceProviderScope: true });
  await Promise.resolve();
  expect(state.write).toHaveBeenCalledWith(expect.anything(), { type: 'GET_PROVIDER_DASHBOARD_DATA', requesterUid: 'u', payload: { providerId: 'a' }, createdAt: 'server-time', session: { authTime: 100, issuedAt: 101, role: 'providerAdmin', providerId: 'a', superAdmin: false } });
  state.callback({ exists: () => true, data: () => ({ result: { ok: true } }) });
  await expect(pending).resolves.toEqual({ ok: true });
});
it('refuses missing/mismatched identity or timestamps before writing', async () => {
  for (const user of [null, { uid: 'other' }, { uid: 'u', getIdTokenResult: async () => ({ claims: {} }) }]) {
    state.current = user;
    await expect(callFunctionRequest({} as any, 'GET_DASHBOARD_DATA', {}, { requesterUid: 'u' })).rejects.toMatchObject({ code: 'unauthenticated' });
  }
  expect(state.write).not.toHaveBeenCalled();
});
it('authority unavailable rejects once without retrying a mutation', async () => {
  const pending = callFunctionRequest({} as any, 'DELETE_PROVIDER', { providerId: 'a' }, { requesterUid: 'u' });
  await Promise.resolve();
  state.callback({ exists: () => true, data: () => ({ error: 'unavailable', code: 'authorization-unavailable' }) });
  await expect(pending).rejects.toMatchObject({ code: 'authorization-unavailable', message: expect.stringContaining('Preserve os dados') });
  expect(state.write).toHaveBeenCalledTimes(1); expect(state.stop).toHaveBeenCalledTimes(1);
});
