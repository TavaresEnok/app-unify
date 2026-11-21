import { afterEach, beforeEach, expect, it, vi } from 'vitest';
import type { User } from 'firebase/auth';
const mocks = vi.hoisted(() => ({ credential: vi.fn(), reauthenticate: vi.fn() }));
vi.mock('firebase/auth', () => ({ EmailAuthProvider: { credential: mocks.credential }, reauthenticateWithCredential: mocks.reauthenticate }));
import { confirmBuildSession, needsBuildConfirmation } from './buildSession';

const now = 1794500000;
beforeEach(() => { vi.clearAllMocks(); vi.useFakeTimers(); vi.setSystemTime(now * 1000); });
afterEach(() => vi.useRealTimers());
it.each([0, 239])('accepts a login made %s seconds ago', async age => {
    const user = { getIdTokenResult: vi.fn(async () => ({ claims: { auth_time: now - age } })) };
    expect(await needsBuildConfirmation(user as unknown as User)).toBe(false);
});
it.each([undefined, 'recent', NaN, Infinity, 0, now + 31, now - 240, now - 600])('requires confirmation for invalid or old authentication: %s', async auth_time => {
    const user = { getIdTokenResult: vi.fn(async () => ({ claims: { auth_time, iat: now, exp: now + 3600 } })) };
    expect(await needsBuildConfirmation(user as unknown as User)).toBe(true);
});
it('confirms the existing account with Firebase credentials rather than refreshing its token', async () => {
    const user = { email: 'manager@example.test' } as User;
    const credential = { providerId: 'password' };
    mocks.credential.mockReturnValue(credential);
    await confirmBuildSession(user, 'fixture-password');
    expect(mocks.credential).toHaveBeenCalledWith(user.email, 'fixture-password');
    expect(mocks.reauthenticate).toHaveBeenCalledWith(user, credential);
});
it('propagates rejected credentials and does not treat them as confirmation', async () => {
    mocks.reauthenticate.mockRejectedValueOnce({ code: 'auth/invalid-credential' });
    await expect(confirmBuildSession({ email: 'manager@example.test' } as User, 'wrong')).rejects.toMatchObject({ code: 'auth/invalid-credential' });
});
it('does not attempt confirmation without an email on the current account', async () => {
    await expect(confirmBuildSession({ email: null } as User, 'fixture-password')).rejects.toThrow();
    expect(mocks.reauthenticate).not.toHaveBeenCalled();
});
