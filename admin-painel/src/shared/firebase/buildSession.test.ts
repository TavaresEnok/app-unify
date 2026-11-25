import { afterEach, beforeEach, expect, it, vi } from 'vitest';
import type { SessionUser } from '@/shared/auth/session';
const mocks = vi.hoisted(() => ({ reauthenticate: vi.fn() }));
vi.mock('@/shared/auth/session', () => ({ reauthenticateWithPassword: mocks.reauthenticate }));
import { confirmBuildSession, needsBuildConfirmation } from './buildSession';

const now = 1794500000;
beforeEach(() => { vi.clearAllMocks(); vi.useFakeTimers(); vi.setSystemTime(now * 1000); });
afterEach(() => vi.useRealTimers());
it.each([0, 239])('accepts a login made %s seconds ago', async age => {
    const user = { getIdTokenResult: vi.fn(async () => ({ claims: { auth_time: now - age } })) };
    expect(await needsBuildConfirmation(user as unknown as SessionUser)).toBe(false);
});
it.each([undefined, 'recent', NaN, Infinity, 0, now + 31, now - 240, now - 600])('requires confirmation for invalid or old authentication: %s', async auth_time => {
    const user = { getIdTokenResult: vi.fn(async () => ({ claims: { auth_time, iat: now, exp: now + 3600 } })) };
    expect(await needsBuildConfirmation(user as unknown as SessionUser)).toBe(true);
});
it('confirms the existing account with backend password reauthentication', async () => {
    const user = { email: 'manager@example.test' } as SessionUser;
    await confirmBuildSession(user, 'fixture-password');
    expect(mocks.reauthenticate).toHaveBeenCalledWith('fixture-password');
});
it('propagates rejected credentials and does not treat them as confirmation', async () => {
    mocks.reauthenticate.mockRejectedValueOnce({ code: 'auth/invalid-credential' });
    await expect(confirmBuildSession({ email: 'manager@example.test' } as SessionUser, 'wrong')).rejects.toMatchObject({ code: 'auth/invalid-credential' });
});
it('does not attempt confirmation without an email on the current account', async () => {
    await expect(confirmBuildSession({ email: '' } as SessionUser, 'fixture-password')).rejects.toThrow();
    expect(mocks.reauthenticate).not.toHaveBeenCalled();
});
