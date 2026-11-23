import { expect, test } from "@playwright/test";

test("login route renders on desktop and mobile", async ({ page }) => {
  const requests: string[] = [];
  page.on('request', request => requests.push(request.url()));
  await page.goto("/login");
  await expect(page.locator("body")).toBeVisible({ timeout: 15_000 });
  await expect(page.getByLabel(/e-mail|email/i)).toBeVisible({ timeout: 15_000 });
  const password = page.getByLabel(/^senha$/i);
  await expect(password).toBeVisible({ timeout: 15_000 });
  await expect(password).toHaveAttribute('type', 'password');
  await password.fill('fixture-password');
  const show = page.getByRole('button', { name: 'Mostrar senha', exact: true });
  await expect(show).toHaveAttribute('aria-pressed', 'false');
  await show.click();
  await expect(password).toHaveAttribute('type', 'text');
  await expect(password).toHaveValue('fixture-password');
  const hide = page.getByRole('button', { name: 'Ocultar senha', exact: true });
  await expect(hide).toHaveAttribute('aria-pressed', 'true');
  await hide.focus();
  await page.keyboard.press('Enter');
  await expect(password).toHaveAttribute('type', 'password');
  await expect(password).toHaveValue('fixture-password');
  await expect(page).toHaveURL(/\/login$/);
  expect(requests.some(url => /\/assets\/(editor-|firebase-firestore-|firebase-functions-|firebase-storage-)/.test(url))).toBe(false);
});

test("protected route redirects anonymous users", async ({ page }) => {
  await page.goto("/dashboard");
  await expect(page).toHaveURL(/\/login$/, { timeout: 15_000 });
});

test("login renders when hosted under /painel", async ({ page }) => {
  await page.goto("/painel/login");
  await expect(page.getByLabel(/e-mail|email/i)).toBeVisible({ timeout: 15_000 });
  await expect(page.getByLabel(/^senha$/i)).toBeVisible();
});

test("protected route keeps /painel when redirecting", async ({ page }) => {
  await page.goto("/painel/dashboard");
  await expect(page).toHaveURL(/\/painel\/login$/, { timeout: 15_000 });
});
