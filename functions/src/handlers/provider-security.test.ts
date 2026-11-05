import { beforeEach, expect, test, vi } from "vitest";

const state = vi.hoisted(() => ({
  docs: new Map<string, Record<string, unknown>>(),
  writes: [] as Array<{ path: string; data: Record<string, unknown> }>,
}));

vi.mock("../app/firebase", () => {
  const collection = (path: string): any => ({ doc: (id: string) => {
    const docPath = `${path}/${id}`;
    return {
      path: docPath,
      get: async () => ({ exists: state.docs.has(docPath), data: () => state.docs.get(docPath) }),
      set: async (data: Record<string, unknown>) => { state.writes.push({ path: docPath, data }); },
      update: async (data: Record<string, unknown>) => { state.writes.push({ path: docPath, data }); },
      collection: (name: string) => collection(`${docPath}/${name}`),
    };
  } });
  return {
    auth: { getUser: async (uid: string) => ({ customClaims: uid === "root" ? { superAdmin: true } : { role: "providerAdmin", providerId: "alpha" } }) },
    db: { collection, batch: () => ({
      set: (ref: { path: string }, data: Record<string, unknown>) => state.writes.push({ path: ref.path, data }),
      commit: async () => {},
    }) },
  };
});
vi.mock("firebase-admin/firestore", () => ({ FieldValue: { serverTimestamp: () => "now", delete: () => "delete" } }));

import { backupProviderConfig, restoreProviderConfig } from "./backups";
import { updateProviderConfig, updateProviderDetails } from "./providers";

beforeEach(() => {
  state.docs.clear();
  state.writes.length = 0;
  state.docs.set("provedores/alpha", { name: "Alpha", config: { token: "old", theme: "blue" } });
  state.docs.set("provedores/alpha/secrets/sgp", { integrations: { apiToken: "current" } });
});

test("backups exclude nested credentials and old backups never restore secrets", async () => {
  await backupProviderConfig({ requestId: "b1", requesterUid: "admin", payload: { providerId: "alpha" } } as any);
  expect(state.writes).toEqual([{ path: "provedores/alpha/backups/b1", data: expect.objectContaining({ providerData: { name: "Alpha", config: { theme: "blue" } } }) }]);
  expect(state.writes[0].data).not.toHaveProperty("secrets");
  state.writes.length = 0;
  state.docs.set("provedores/alpha/backups/old", { providerData: { name: "Alpha", sgpBaseUrl: "https://attacker.test", details: { systemUrl: "https://attacker.test" }, nested: { apiToken: "old" } }, secrets: { integrations: { apiToken: "old" } } });
  await restoreProviderConfig({ requestId: "r1", requesterUid: "admin", payload: { providerId: "alpha", backupId: "old" } } as any);
  expect(state.writes).toEqual([{ path: "provedores/alpha", data: { name: "Alpha", nested: {}, updatedAt: "now" } }]);
});

test("provider administrators cannot change integrations through either handler", async () => {
  const base = { requestId: "r1", requesterUid: "admin" };
  await expect(updateProviderConfig({ ...base, payload: { providerId: "alpha", config: { integrations: { apiToken: "new" } } } } as any)).rejects.toMatchObject({ code: "permission-denied" });
  await expect(updateProviderConfig({ ...base, payload: { providerId: "alpha", config: { sgpBaseUrl: "https://example.test" } } } as any)).rejects.toMatchObject({ code: "permission-denied" });
  await expect(updateProviderDetails({ ...base, payload: { providerId: "alpha", details: { systemUrl: "https://example.test" } } } as any)).rejects.toMatchObject({ code: "permission-denied" });
  expect(state.writes).toEqual([]);
});

test("super admin retains ability to manage integrations", async () => {
  await updateProviderDetails({ requestId: "r1", requesterUid: "root", payload: { providerId: "alpha", details: { apiToken: "new" } } } as any);
  expect(state.writes).toContainEqual({ path: "provedores/alpha/secrets/sgp", data: { integrations: { apiToken: "new" } } });
});
