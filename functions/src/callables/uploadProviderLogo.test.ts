import { beforeEach, expect, it, vi } from 'vitest';
const state = vi.hoisted(() => ({ verify: vi.fn(), get: vi.fn(), save: vi.fn(), set: vi.fn() }));
vi.mock('firebase-functions/v2/https', async importOriginal => ({ ...await importOriginal<any>(), onCall: (_options: any, handler: any) => handler }));
vi.mock('../app/firebase', () => ({ auth: { verifyIdToken: state.verify, getUser: state.get }, storage: { bucket: () => ({ name: 'synthetic', file: () => ({ save: state.save }) }) }, db: { collection: () => ({ doc: () => ({ set: state.set }) }) } }));
import { uploadProviderLogo } from './uploadProviderLogo';
const now = Math.floor(Date.now() / 1000);
const invoke = (providerId = 'a') => (uploadProviderLogo as any)({ auth: { uid: 'u' }, rawRequest: { headers: { authorization: 'Bearer synthetic' } }, data: { providerId, imageBase64: 'data:image/png;base64,AQID' } });
beforeEach(() => {
  vi.clearAllMocks();
  state.verify.mockResolvedValue({ uid: 'u', auth_time: now, iat: now, role: 'providerAdmin', providerId: 'a' });
  state.get.mockResolvedValue({ uid: 'u', customClaims: { role: 'providerAdmin', providerId: 'a' } });
});
it('verifies revoked session and current scope before uploading', async () => {
  await expect(invoke()).resolves.toMatchObject({ success: true });
  expect(state.verify).toHaveBeenCalledWith('synthetic', true); expect(state.save).toHaveBeenCalledTimes(1);
});
it.each(['revoked', 'old-session', 'disabled', 'removed', 'tenant', 'outage', 'other-tenant'])('denies %s without writes', async mode => {
  if (mode === 'revoked') state.verify.mockRejectedValue(Object.assign(Error(), { code: 'auth/id-token-revoked' }));
  if (mode === 'old-session') state.get.mockResolvedValue({ customClaims: { role: 'providerAdmin', providerId: 'a' }, tokensValidAfterTime: new Date((now + 1) * 1000).toISOString() });
  if (mode === 'disabled') state.get.mockResolvedValue({ disabled: true });
  if (mode === 'removed') state.get.mockResolvedValue({ customClaims: {} });
  if (mode === 'tenant') state.get.mockResolvedValue({ customClaims: { role: 'providerAdmin', providerId: 'b' } });
  if (mode === 'outage') state.get.mockRejectedValue(Error('private'));
  await expect(invoke(mode === 'other-tenant' ? 'b' : 'a')).rejects.toMatchObject({ code: mode === 'outage' ? 'unavailable' : ['revoked', 'old-session', 'disabled'].includes(mode) ? 'unauthenticated' : 'permission-denied' });
  expect(state.save).not.toHaveBeenCalled(); expect(state.set).not.toHaveBeenCalled();
});
