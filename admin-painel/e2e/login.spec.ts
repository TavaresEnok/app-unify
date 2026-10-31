import { expect, test } from '@playwright/test';

test('login retries immediately and shows the panel while its single data request is pending', async ({ page }) => {
  // Exercise the real Firebase client SDK with isolated Identity Toolkit fixtures.
  // No production credentials, users or backend data are used by this test.
  const uid = 'login-fixture', email = 'admin@example.test';
  const now = Math.floor(Date.now() / 1000);
  const jwt = [
    { alg: 'RS256', typ: 'JWT', kid: 'fixture' },
    { sub: uid, user_id: uid, aud: 'app-ajust-provedor', iss: 'https://securetoken.google.com/app-ajust-provedor',
      iat: now, exp: now + 3600, auth_time: now, role: 'providerAdmin', providerId: 'fixture', email,
      firebase: { sign_in_provider: 'password', identities: { email: [email] } } },
  ].map(value => Buffer.from(JSON.stringify(value)).toString('base64url')).join('.') + '.fixture';
  let attempts = 0, dashboardRequests = 0;
  await page.route('https://identitytoolkit.googleapis.com/**', async route => {
    const path = new URL(route.request().url()).pathname;
    if (path.endsWith('accounts:signInWithPassword')) {
      attempts++;
      if (attempts <= 6) return route.fulfill({ status: 400, json: { error: { code: 400, message: 'INVALID_LOGIN_CREDENTIALS' } } });
      return route.fulfill({ json: { localId: uid, email, idToken: jwt, refreshToken: 'fixture-refresh', expiresIn: '3600', registered: true } });
    }
    if (path.endsWith('accounts:lookup')) return route.fulfill({ json: { users: [{ localId: uid, email, emailVerified: true,
      providerUserInfo: [{ providerId: 'password', rawId: email, email }], validSince: String(now) }] } });
    return route.fulfill({ json: {} });
  });
  let release!: () => void;
  await page.route('**/admin/performance', route => route.fulfill({ status: 204 }));
  const gate = new Promise<void>(resolve => { release = resolve; });
  await page.route('**/admin/dashboard/panel/providers/**', async route => {
    dashboardRequests++; await gate;
    await route.fulfill({ json: { data: { stats: { totalClients: 10, openTicketsCount: 0 }, recentTickets: [] } } });
  });
  await page.goto('/login');
  await page.getByLabel(/e-mail|email/i).fill(email); await page.getByLabel(/senha/i).fill('fixture-password');
  for (let index = 1; index <= 6; index++) {
    await page.getByRole('button', { name: 'Entrar', exact: true }).click();
    await expect.poll(() => attempts).toBe(index);
    await expect(page.getByRole('button', { name: 'Entrar', exact: true })).toBeEnabled();
  }
  const requestSent = page.waitForRequest(request => new URL(request.url()).pathname.endsWith('accounts:signInWithPassword'), { timeout: 1500 });
  await page.getByRole('button', { name: 'Entrar', exact: true }).click();
  await requestSent;
  // A slow data response must not keep the entire panel hidden.
  await expect(page.getByRole('button', { name: 'Notificações', exact: true })).toBeVisible();
  expect(dashboardRequests).toBe(1);
  release();
  await expect(page.getByRole('heading', { name: 'Visão geral', exact: true })).toBeVisible();
  expect(dashboardRequests).toBe(1);
});
