import { beforeEach, expect, it, vi } from "vitest";
import { DEFAULT_PROVIDER_CONFIG } from "@/features/provider-settings/defaults";

const mocks = vi.hoisted(() => ({
  onSnapshot: vi.fn((..._args: unknown[]) => () => {}),
  set: vi.fn(), update: vi.fn(), commit: vi.fn(async () => {}),
}));
vi.mock("@/firebase/config", () => ({ db: {} }));
vi.mock("firebase/firestore", () => ({
  doc: (_db: unknown, ...path: string[]) => path.join("/"),
  deleteField: () => "delete-field",
  onSnapshot: mocks.onSnapshot,
  writeBatch: () => ({ set: mocks.set, update: mocks.update, commit: mocks.commit }),
}));
import { saveProviderSettings, subscribeProviderSettings } from "./providerSettingsService";

beforeEach(() => vi.clearAllMocks());

it("does not subscribe to or write credentials when a provider administrator saves settings", async () => {
  await subscribeProviderSettings("alpha", () => {}, () => {});
  expect(mocks.onSnapshot).toHaveBeenCalledTimes(1);
  expect(mocks.onSnapshot.mock.calls[0][0]).toBe("provedores/alpha");
  await saveProviderSettings("alpha", { ...DEFAULT_PROVIDER_CONFIG, integrations: { apiToken: "do-not-write" } });
  expect(mocks.set).not.toHaveBeenCalled();
  expect(mocks.update).toHaveBeenCalledOnce();
  expect(mocks.update.mock.calls[0][1]).not.toHaveProperty("integrations.apiToken");
  expect(mocks.commit).toHaveBeenCalledOnce();
});

it("allows the SaaS administrator to subscribe to and save integrations", async () => {
  await subscribeProviderSettings("alpha", () => {}, () => {}, true);
  expect(mocks.onSnapshot).toHaveBeenCalledTimes(2);
  await saveProviderSettings("alpha", { ...DEFAULT_PROVIDER_CONFIG, integrations: { apiToken: "new" } }, true);
  expect(mocks.set).toHaveBeenCalledWith("provedores/alpha/secrets/sgp", { integrations: { apiToken: "new" } }, { merge: true });
});
