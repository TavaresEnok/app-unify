import { afterEach, expect, it, vi } from "vitest";
import { applicationDownloadPath, checkPublishedApp, externalHttpsUrl } from "./publishedApp";

afterEach(() => vi.unstubAllGlobals());

it("uses the same published filename as the builder and supports the provider name fallback", () => {
  expect(applicationDownloadPath({ name: "Vibe Telecom" })).toMatch(/\/public_apks\/app_Vibe_Telecom\.apk$/);
  expect(applicationDownloadPath({ name: "Vibe", details: { appName: "Meu app" } })).toMatch(/\/public_apks\/app_Meu_app\.apk$/);
  expect(applicationDownloadPath({})).toBeNull();
});

it("does not offer an HTML fallback or a missing file as an APK", async () => {
  const fetch = vi.fn().mockResolvedValueOnce(new Response("", { headers: { "content-type": "text/html" } }))
    .mockResolvedValueOnce(new Response("", { status: 404 }))
    .mockResolvedValueOnce(new Response("", { headers: { "content-type": "application/vnd.android.package-archive" } }));
  vi.stubGlobal("fetch", fetch);
  const signal = new AbortController().signal;
  expect(await checkPublishedApp("/app.apk", signal)).toBe(false);
  expect(await checkPublishedApp("/app.apk", signal)).toBe(false);
  expect(await checkPublishedApp("/app.apk", signal)).toBe(true);
  expect(fetch).toHaveBeenCalledWith("/app.apk", { method: "HEAD", cache: "no-store", signal });
});

it("keeps lookup failures distinct from an unpublished app and rejects unsafe store links", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response("", { status: 503 })));
  await expect(checkPublishedApp("/app.apk", new AbortController().signal)).rejects.toThrow();
  for (const value of ["javascript:alert(1)", "http://example.test", "https://user:pass@example.test", ""]) expect(externalHttpsUrl(value)).toBeNull();
  expect(externalHttpsUrl("https://play.google.com/store/apps/details?id=br.test.app")).toBeTruthy();
});
