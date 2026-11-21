import { beforeEach, expect, it, vi } from "vitest";
const mocks = vi.hoisted(() => ({ snapshot: vi.fn(), rpc: vi.fn() }));
vi.mock("@/features/providers/providerService", () => ({ subscribeProvider: mocks.snapshot }));
vi.mock("@/firebase/config", () => ({ db: {}, auth: { currentUser: { uid: "provider" } } }));
vi.mock("@/shared/api/panelHttp", () => ({ panelRequest: mocks.rpc, clearPanelReads: vi.fn() }));
import { subscribeProviderSettings, saveProviderSettings } from "./providerSettingsService";
import { DEFAULT_PROVIDER_CONFIG } from "@/features/provider-settings/defaults";
beforeEach(() => vi.clearAllMocks());
it("subscribes only to public config and strips legacy fields", async () => {
 mocks.snapshot.mockImplementation((_path, emit) => { emit({ themeColor: "#abc", integrations: { apiToken: "private" }, details: { systemUrl: "private" } }); return () => {}; });
 const emit = vi.fn();
 await subscribeProviderSettings("a", emit, vi.fn());
 expect(mocks.snapshot).toHaveBeenCalledTimes(1);
 expect(mocks.snapshot.mock.calls[0][0]).toBe("a");
 expect(JSON.stringify(emit.mock.calls)).not.toContain("private");
});
it("saves customization by validated HTTP without a private write", async () => {
 await saveProviderSettings("a", DEFAULT_PROVIDER_CONFIG);
 expect(mocks.rpc).toHaveBeenCalledWith("/admin/providers/a/config", { method: "PATCH", body: DEFAULT_PROVIDER_CONFIG });
 await expect(saveProviderSettings("a", { ...DEFAULT_PROVIDER_CONFIG, integrations: { apiToken: "injected" } })).rejects.toThrow();
 expect(mocks.rpc).toHaveBeenCalledTimes(1);
});
