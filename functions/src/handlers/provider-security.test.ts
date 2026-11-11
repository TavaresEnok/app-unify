import { beforeEach, expect, test, vi } from "vitest";

const state = vi.hoisted(() => ({
  docs: new Map<string, Record<string, unknown>>(),
  writes: [] as Array<{ path: string; data: Record<string, unknown> }>,
}));

vi.mock("../app/firebase", () => {
  const collection = (path: string): any => ({ doc: (id: string) => {
    const docPath = `${path}/${id}`;
    return {
      id,
      path: docPath,
      get: async () => ({ exists: state.docs.has(docPath), data: () => state.docs.get(docPath) }),
      set: async (data: Record<string, unknown>) => { state.writes.push({ path: docPath, data }); },
      update: async (data: Record<string, unknown>) => { state.writes.push({ path: docPath, data }); },
      collection: (name: string) => collection(`${docPath}/${name}`),
    };
  } });
  return {
    auth: { getUser: async (uid: string) => ({ customClaims: uid === "root" ? { superAdmin: true } : { role: "providerAdmin", providerId: "alpha" } }) },
    db: {
      collection,
      batch: () => ({
        set: (ref: { path: string }, data: Record<string, unknown>) => state.writes.push({ path: ref.path, data }),
        commit: async () => {},
      }),
      runTransaction: async (fn: (tx: any) => Promise<unknown>) => fn({
        get: (ref: any) => ref.get(),
        set: (ref: { path: string }, data: Record<string, unknown>) => { state.writes.push({ path: ref.path, data }); },
      }),
    },
  };
});
vi.mock("firebase-admin/firestore", () => ({ FieldValue: { serverTimestamp: () => "now", delete: () => "delete" } }));

import { backupProviderConfig, restoreProviderConfig } from "./backups";
import { updateProviderConfig, updateProviderDetails } from "./providers";

beforeEach(() => {
  state.docs.clear();
  state.writes.length = 0;
  state.docs.set("provedores/alpha", { name: "Alpha", themeColor: "blue", config: { token: "old" } });
  state.docs.set("provedores/alpha/secrets/sgp", { integrations: { apiToken: "current" } });
});

test("backups exclude nested credentials and old backups never restore secrets", async () => {
  await backupProviderConfig({ requestId: "b1", requesterUid: "admin", payload: { providerId: "alpha" } } as any);
  expect(state.writes.map(write => write.path)).toEqual(["provedores/alpha/backups/b1"]);
  expect(state.writes[0].data).not.toHaveProperty("secrets");
  expect(JSON.stringify(state.writes[0].data)).not.toMatch(/token|current|"old"/i);

  state.writes.length = 0;
  state.docs.set("provedores/alpha/backups/old", {
    providerData: { name: "Alpha", themeColor: "red", sgpBaseUrl: "https://attacker.test", details: { systemUrl: "https://attacker.test" }, nested: { apiToken: "from-backup" } },
    secrets: { integrations: { apiToken: "from-backup" } },
  });
  await restoreProviderConfig({ requestId: "r1", requesterUid: "admin", payload: { providerId: "alpha", backupId: "old" } } as any);
  expect(state.writes.map(write => write.path)).toEqual(["provedores/alpha"]);
  expect(state.writes[0].data).toMatchObject({ themeColor: "red" });
  expect(JSON.stringify(state.writes[0].data)).not.toMatch(/attacker\.test|from-backup/);
});

test("provider administrators cannot change integrations through either handler", async () => {
  const base = { requestId: "r1", requesterUid: "admin" };
  const rejected = { code: expect.stringMatching(/^(permission-denied|invalid-argument)$/) };
  await expect(updateProviderConfig({ ...base, payload: { providerId: "alpha", config: { integrations: { apiToken: "new" } } } } as any)).rejects.toMatchObject(rejected);
  await expect(updateProviderConfig({ ...base, payload: { providerId: "alpha", config: { sgpBaseUrl: "https://example.test" } } } as any)).rejects.toMatchObject(rejected);
  await expect(updateProviderDetails({ ...base, payload: { providerId: "alpha", details: { systemUrl: "https://example.test" } } } as any)).rejects.toMatchObject(rejected);
  expect(state.writes).toEqual([]);
});

// A troca de integração SGP saiu destes RPCs: agora é exclusiva da rota SaaS
// reautenticada POST /admin/providers/:id/integration (api-service, coberta em
// providers.routes.test.ts). Nem o super admin grava segredos por aqui.
test("integration secrets are never written through the RPC, even by super admin", async () => {
  await expect(updateProviderDetails({ requestId: "r1", requesterUid: "root", payload: { providerId: "alpha", details: { apiToken: "new" } } } as any))
    .rejects.toMatchObject({ code: "invalid-argument" });
  expect(state.writes.filter(write => write.path.includes("/secrets/"))).toEqual([]);
});
