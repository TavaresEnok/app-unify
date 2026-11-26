import { expect, test } from '@playwright/test';

test('login retries immediately and shows the panel while its single data request is pending', async ({ page }) => {
  // Self-hosted admin auth (POST /admin/auth/login) with isolated fixtures.
  // No production credentials, users or backend data are used by this test.
  const uid = 'login-fixture', email = 'admin@example.test';
  const now = Math.floor(Date.now() / 1000);
  const jwt = [
    { alg: 'HS256', typ: 'JWT' },
    { uid, iat: now, exp: now + 3600, auth_time: now, role: 'providerAdmin', providerId: 'fixture', email },
  ].map(value => Buffer.from(JSON.stringify(value)).toString('base64url')).join('.') + '.fixture';
  let attempts = 0, dashboardRequests = 0;
  await page.route('**/admin/auth/login', async route => {
    attempts++;
    if (attempts <= 6) return route.fulfill({ status: 401, json: { error: { code: 'unauthenticated', message: 'Credenciais inválidas.' } } });
    return route.fulfill({ json: { token: jwt, user: { uid, email, role: 'providerAdmin', superAdmin: false, providerId: 'fixture', authTime: now } } });
  });
  await page.route('**/admin/auth/me', route => route.fulfill({ json: { user: { uid, email, role: 'providerAdmin', superAdmin: false, providerId: 'fixture', authTime: now } } }));
  let release!: () => void;
  await page.route('**/admin/performance', route => route.fulfill({ status: 204 }));
  const gate = new Promise<void>(resolve => { release = resolve; });
  await page.route('**/admin/dashboard/panel/providers/**', async route => {
    dashboardRequests++; await gate;
    await route.fulfill({ json: { data: { stats: { totalClients: 10, openTicketsCount: 0 }, recentTickets: [] } } });
  });
  await page.goto('/login');
  await page.getByLabel(/e-mail|email/i).fill(email); await page.getByLabel(/^senha$/i).fill('fixture-password');
  for (let index = 1; index <= 6; index++) {
    await page.getByRole('button', { name: 'Entrar', exact: true }).click();
    await expect.poll(() => attempts).toBe(index);
    await expect(page.getByRole('button', { name: 'Entrar', exact: true })).toBeEnabled();
  }
  const requestSent = page.waitForRequest(request => new URL(request.url()).pathname.endsWith('/admin/auth/login'), { timeout: 1500 });
  await page.getByRole('button', { name: 'Entrar', exact: true }).click();
  await requestSent;
  // A slow data response must not keep the entire panel hidden.
  await expect(page.getByRole('button', { name: 'Notificações', exact: true })).toBeVisible();
  expect(dashboardRequests).toBe(1);
  release();
  await expect(page.getByRole('heading', { name: 'Visão geral', exact: true, level: 2 })).toBeVisible();
  expect(dashboardRequests).toBe(1);
});
