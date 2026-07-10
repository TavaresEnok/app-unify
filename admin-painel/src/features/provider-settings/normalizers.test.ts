import { describe, expect, it } from "vitest";
import { DEFAULT_PROVIDER_CONFIG } from "./defaults";
import {
  fromFirestoreProviderConfig,
  normalizeProviderConfig,
  toFirestoreProviderConfig,
} from "./normalizers";

describe("provider config normalizers", () => {
  it("fills all critical defaults for an empty document", () => {
    const config = normalizeProviderConfig({});
    expect(config.layoutType).toBe(DEFAULT_PROVIDER_CONFIG.layoutType);
    expect(config.themeColor).toBe(DEFAULT_PROVIDER_CONFIG.themeColor);
    expect(config.typography).toEqual(DEFAULT_PROVIDER_CONFIG.typography);
  });

  it("keeps root values ahead of legacy config values", () => {
    const config = fromFirestoreProviderConfig({
      themeColor: "#111111",
      config: { themeColor: "#222222", strings: { home_tab_title: "Legacy" } },
      strings: { home_tab_title: "Atual" },
    });
    expect(config.themeColor).toBe("#111111");
    expect(config.strings?.home_tab_title).toBe("Atual");
  });

  it("keeps integrations in the restricted payload", () => {
    const payload = toFirestoreProviderConfig({
      ...DEFAULT_PROVIDER_CONFIG,
      integrations: { apiToken: "secret", appName: "Unify" },
    });
    expect(payload.publicConfig.integrations).toBeUndefined();
    expect(payload.secrets).toEqual({ integrations: { apiToken: "secret", appName: "Unify" } });
  });
});
