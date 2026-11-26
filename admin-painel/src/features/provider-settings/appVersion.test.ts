import { describe, expect, it } from "vitest";
import { appVersionFormFromConfig, buildAppVersion, compareVersions, mergeAppVersion } from "./appVersion";
import { toFirestoreProviderConfig, fromFirestoreProviderConfig } from "./normalizers";
import { publicProviderData } from "./configBoundary";
import { DEFAULT_PROVIDER_CONFIG } from "./defaults";

describe("app version editor", () => {
  it("compares versions numerically", () => {
    expect(compareVersions("1.0.10", "1.0.9")).toBe(1);
    expect(compareVersions("1.0.5", "1.0.5")).toBe(0);
    expect(compareVersions("1.2", "1.2.0")).toBe(0);
  });

  it("validates and builds the contract shape", () => {
    expect(buildAppVersion({ minVersion: "1.2", latestVersion: "", storeUrl: "" })).toMatchObject({ ok: false });
    expect(buildAppVersion({ minVersion: "2.0.0", latestVersion: "1.0.0", storeUrl: "https://play.google.com/x" })).toMatchObject({ ok: false });
    expect(buildAppVersion({ minVersion: "1.0.0", latestVersion: "1.0.5", storeUrl: "" })).toMatchObject({ ok: false });
    expect(buildAppVersion({ minVersion: "1.0.0", latestVersion: "", storeUrl: "http://play.google.com/x" })).toMatchObject({ ok: false });
    expect(buildAppVersion({ minVersion: "", latestVersion: "", storeUrl: "" })).toMatchObject({ ok: true });
    const ok = buildAppVersion({ minVersion: " 1.0.0 ", latestVersion: "1.0.5", storeUrl: "https://play.google.com/store/apps/details?id=a" });
    expect(ok).toEqual({ ok: true, value: { minVersion: "1.0.0", latestVersion: "1.0.5", storeUrl: "https://play.google.com/store/apps/details?id=a", forceUpdate: true, storeUrls: { android: "https://play.google.com/store/apps/details?id=a" } } });
  });

  it("saves through the config boundary and loads back", () => {
    const result = buildAppVersion({ minVersion: "1.0.0", latestVersion: "1.0.5", storeUrl: "https://play.google.com/x" });
    if (!result.ok) throw new Error(result.error);
    const { publicConfig } = toFirestoreProviderConfig({ ...DEFAULT_PROVIDER_CONFIG, appVersion: result.value });
    expect(publicConfig.appVersion).toMatchObject({ minVersion: "1.0.0", latestVersion: "1.0.5", storeUrl: "https://play.google.com/x" });
    const loaded = fromFirestoreProviderConfig(publicProviderData({ id: "p", ...publicConfig }));
    expect(appVersionFormFromConfig(loaded)).toEqual({ minVersion: "1.0.0", latestVersion: "1.0.5", storeUrl: "https://play.google.com/x" });
  });

  it("reads the store link saved by the old editor", () => {
    expect(appVersionFormFromConfig({ appVersion: { minVersion: "1.0.0", storeUrls: { android: "https://old" } } }).storeUrl).toBe("https://old");
  });

  it("keeps the iOS link and custom message saved before", () => {
    const result = buildAppVersion({ minVersion: "1.1.0", latestVersion: "1.2.0", storeUrl: "https://play.google.com/new" });
    if (!result.ok) throw new Error(result.error);
    const previous = {
      minVersion: "1.0.0",
      forceUpdate: false,
      storeUrls: { android: "https://play.google.com/old", ios: "https://apps.apple.com/app/x" },
      updateMessage: { pt_BR: { title: "Atualize", message: "Nova versão", buttonText: "Ok" } },
    };
    const merged = mergeAppVersion(previous, result.value);
    expect(merged).toMatchObject({ minVersion: "1.1.0", latestVersion: "1.2.0", storeUrl: "https://play.google.com/new", forceUpdate: true });
    expect(merged.storeUrls).toEqual({ android: "https://play.google.com/new", ios: "https://apps.apple.com/app/x" });
    expect(merged.updateMessage?.pt_BR.title).toBe("Atualize");
    expect(mergeAppVersion(undefined, result.value).storeUrls).toEqual({ android: "https://play.google.com/new" });
  });
});
