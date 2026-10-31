import { expect, test } from "@playwright/test";

test("login route renders on desktop and mobile", async ({ page }) => {
  const requests: string[] = [];
  page.on('request', request => requests.push(request.url()));
  await page.goto("/login");
  await expect(page.locator("body")).toBeVisible({ timeout: 15_000 });
  await expect(page.getByLabel(/e-mail|email/i)).toBeVisible({ timeout: 15_000 });
  await expect(page.getByLabel(/senha/i)).toBeVisible({ timeout: 15_000 });
  expect(requests.some(url => /\/assets\/(editor-|firebase-firestore-|firebase-functions-|firebase-storage-)/.test(url))).toBe(false);
});

test("protected route redirects anonymous users", async ({ page }) => {
  await page.goto("/dashboard");
  await expect(page).toHaveURL(/\/login$/, { timeout: 15_000 });
});

test("login renders when hosted under /painel", async ({ page }) => {
  await page.goto("/painel/login");
  await expect(page.getByLabel(/e-mail|email/i)).toBeVisible({ timeout: 15_000 });
  await expect(page.getByLabel(/senha/i)).toBeVisible();
});

test("protected route keeps /painel when redirecting", async ({ page }) => {
  await page.goto("/painel/dashboard");
  await expect(page).toHaveURL(/\/painel\/login$/, { timeout: 15_000 });
});
