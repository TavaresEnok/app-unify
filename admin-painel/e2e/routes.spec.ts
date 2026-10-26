import { expect, test } from "@playwright/test";

test("login route renders on desktop and mobile", async ({ page }) => {
  await page.goto("/login");
  await expect(page.locator("body")).toBeVisible({ timeout: 15_000 });
  await expect(page.getByLabel(/e-mail|email/i)).toBeVisible({ timeout: 15_000 });
  await expect(page.getByLabel(/senha/i)).toBeVisible({ timeout: 15_000 });
});

test("protected route redirects anonymous users", async ({ page }) => {
  await page.goto("/dashboard");
  await expect(page).toHaveURL(/\/login$/, { timeout: 15_000 });
});
