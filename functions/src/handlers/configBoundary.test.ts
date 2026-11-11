import { beforeEach, expect, it, vi } from "vitest";
const state = vi.hoisted(() => ({ docs: new Map<string, any>(), reads: [] as string[], writes: [] as string[] }));
function ref(path: string): any {
  return { id: path.split("/").pop(), path,
    get: async () => { state.reads.push(path); return { exists: state.docs.has(path), data: () => state.docs.get(path) }; },
    set: async (data: any, options?: any) => { state.writes.push(path); state.docs.set(path, options?.merge ? { ...state.docs.get(path), ...data } : data); },
    update: async (data: any) => {
      state.writes.push(path);
      const next = structuredClone(state.docs.get(path));
      for (const [key, value] of Object.entries(data)) {
        if (key.startsWith("details.")) next.details[key.slice(8)] = value;
        else next[key] = value;
      }
      state.docs.set(path, next);
    },
    collection: (name: string) => col(path + "/" + name),
  };
}
function col(path: string): any { return { doc: (id: string) => ref(path + "/" + id), orderBy: () => ({
  get: async () => ({ docs: [...state.docs].filter(([k]) => k.startsWith(path + "/")).map(([k, v]) => ({ id: k.split("/").pop(), data: () => v })) }),
}) }; }
vi.mock("../app/firebase", () => ({
 db: { collection: col, runTransaction: async (fn: any) => fn({ get: (r: any) => r.get(), set: (r: any, d: any) => r.set(d) }) },
 auth: { getUser: async (uid: string) => ({ disabled: uid === "disabled", customClaims: uid === "saas" ? { superAdmin: true } : { role: uid === "subscriber" ? "subscriber" : "providerAdmin", providerId: uid === "other" ? "b" : "a" } }) },
}));
import { createProvider, updateProviderConfig, updateProviderDetails } from "./providers";
import { backupProviderConfig, restoreProviderConfig, listProviderBackups, deleteProviderBackup } from "./backups";
const invoke = (fn: any, uid: string, payload: any) => fn({ requesterUid: uid, requestId: "new", payload: { providerId: "a", ...payload } });
beforeEach(() => {
 state.docs.clear(); state.reads.length = 0; state.writes.length = 0;
 state.docs.set("provedores/a", { name: "A", applicationId: "br.original", active: true, permissions: ["original"], themeColor: "new", backgroundColor: "remove", config: { logoUrl: "remove", apiUrl: "preserve" }, details: { systemUrl: "operational" } });
 state.docs.set("provedores/a/secrets/sgp", { integrations: { apiToken: "synthetic-operational", sgpBaseUrl: "https://original.test", appName: "original" } });
});
it("denies roles and tenants before reads or effects", async () => {
 for (const uid of ["other", "subscriber", "disabled"]) for (const fn of [updateProviderConfig, updateProviderDetails, backupProviderConfig, restoreProviderConfig, listProviderBackups])
   await expect(invoke(fn, uid, { config: {}, details: {}, backupId: "old" })).rejects.toHaveProperty("code");
 expect(state.reads).toEqual([]); expect(state.writes).toEqual([]);
});
it("rejects unknown and nested sensitive config for SaaS too, without reading secrets", async () => {
 for (const uid of ["provider", "saas"]) for (const config of [
   { integrations: { apiToken: "injected" } }, { apiUrl: "https://injected" }, { appName: "injected" },
   { faq: [{ question: "Q", answer: "A", password: "injected" }] },
   { typography: { fontFamily: "Inter", custom: { token: "injected" } } },
   { menuConfig: { items: { invoices: { enabled: true, secretRef: "injected" } } } },
   { strings: { unknown: "injected" } }, { themeColor: { token: "injected" } },
 ]) await expect(invoke(updateProviderConfig, uid, { config })).rejects.toMatchObject({ code: "invalid-argument" });
 for (const details of [{ apiToken: "injected" }, { systemUrl: "injected" }, { appName: "injected" }])
   await expect(invoke(updateProviderDetails, "provider", { details })).rejects.toMatchObject({ code: "invalid-argument" });
 expect(state.writes).toEqual([]);
});
it("personalization works without any secret read or write", async () => {
 await invoke(updateProviderConfig, "provider", { config: { themeColor: "#fff", faq: [{ question: "Q", answer: "A" }] } });
 expect(state.docs.get("provedores/a").themeColor).toBe("#fff");
 expect(state.reads.some(p => p.includes("/secrets/"))).toBe(false);
 expect(state.writes).toEqual(["provedores/a"]);
});
it("rejects unknown RPC envelope fields before persistence", async () => {
 for (const uid of ["provider", "saas"]) {
  await expect(invoke(updateProviderConfig, uid, { config: {}, secretRef: "synthetic" })).rejects.toMatchObject({ code: "invalid-argument" });
  await expect(invoke(updateProviderDetails, uid, { details: {}, integrations: { apiToken: "synthetic" } })).rejects.toMatchObject({ code: "invalid-argument" });
 }
 await expect(invoke(createProvider, "saas", { name: "New", config: { apiToken: "synthetic" } })).rejects.toMatchObject({ code: "invalid-argument" });
 expect(state.writes).toEqual([]);
});
it("new backup contains only schema fields and never reads private credentials", async () => {
 await invoke(backupProviderConfig, "provider", {});
 const backup = state.docs.get("provedores/a/backups/new");
 expect(backup.schemaVersion).toBe(1);
 expect(backup.providerData).toEqual({ themeColor: "new", backgroundColor: "remove", logoUrl: "remove" });
 expect(backup.secrets).toBeUndefined();
 expect(state.reads).toEqual(["provedores/a"]);
});
it.each(["provider", "saas"])("new backup resolves split maps and restores the exact snapshot for %s", async uid => {
 const provider = state.docs.get("provedores/a");
 Object.assign(provider, {
  config: {
   ...provider.config,
   strings: { hello_prefix: "Legado", plan_prefix: "Antigo" },
   typography: { fontFamily: "Inter", bodySize: "small" },
   features: { faq: true, tips: false },
   menuConfig: { items: { invoices: { name: "Legado", enabled: true } }, order: ["invoices", "support"] },
   imageCarousel: ["legacy"],
  },
  strings: { plan_prefix: "Plano", layoutThemes: JSON.stringify({ layout_06: { themeColor: "#123456" } }) },
  typography: { bodySize: "large" }, features: { tips: true },
  menuConfig: { items: { invoices: { name: "Atual" } }, order: ["invoices"] },
  imageCarousel: ["root"],
 });
 const privateBefore = structuredClone(state.docs.get("provedores/a/secrets/sgp"));
 await invoke(backupProviderConfig, uid, {});
 const snapshot = structuredClone(state.docs.get("provedores/a/backups/new").providerData);
 expect(snapshot).toMatchObject({
  strings: { hello_prefix: "Legado", plan_prefix: "Plano" },
  typography: { fontFamily: "Inter", bodySize: "large" }, features: { faq: true, tips: true },
  menuConfig: { items: { invoices: { name: "Atual", enabled: true } }, order: ["invoices"] },
  imageCarousel: ["root"],
 });
 provider.strings = { terms_title: "Posterior" };
 provider.config.typography.titleSize = "remove";
 provider.config.features.contract = true;
 provider.config.menuConfig.items.support = { name: "remove" };
 await invoke(restoreProviderConfig, uid, { backupId: "new" });
 const restored = state.docs.get("provedores/a");
 for (const key of ["strings", "typography", "features", "menuConfig", "imageCarousel"]) expect(restored[key]).toEqual(snapshot[key]);
 expect(restored.config).toEqual({ apiUrl: "preserve" });
 expect(restored.applicationId).toBe("br.original");
 expect(restored.permissions).toEqual(["original"]);
 expect(state.docs.get("provedores/a/secrets/sgp")).toEqual(privateBefore);
 expect(state.reads.some(p => p.includes("/secrets/"))).toBe(false);
});
it.each(["provider", "saas"])("old mixed backup merges only sanitized fields before exact restore for %s", async uid => {
 const privateBefore = structuredClone(state.docs.get("provedores/a/secrets/sgp"));
 state.docs.set("provedores/a/backups/split", { providerData: {
  config: {
   strings: { hello_prefix: "Legado", plan_prefix: "Antigo", apiToken: "synthetic" },
   typography: { fontFamily: "Inter", bodySize: "small" },
   menuConfig: { items: { invoices: { name: "Legado", enabled: true } } },
   imageCarousel: ["legacy"], apiUrl: "https://synthetic.test",
  },
  strings: { plan_prefix: "Plano", layoutThemes: JSON.stringify({ layout_06: { themeColor: "#123456", secretRef: "synthetic" } }) },
  typography: { bodySize: "large", token: "synthetic" },
  menuConfig: { items: { invoices: { name: "Atual", apiToken: "synthetic" } } },
  imageCarousel: [], applicationId: "br.bad", permissions: ["bad"],
 }, secrets: { apiToken: "synthetic" } });
 await invoke(restoreProviderConfig, uid, { backupId: "split" });
 const restored = state.docs.get("provedores/a");
 expect(restored.strings).toEqual({ hello_prefix: "Legado", plan_prefix: "Plano", layoutThemes: JSON.stringify({ layout_06: { themeColor: "#123456" } }) });
 expect(restored.typography).toEqual({ fontFamily: "Inter", bodySize: "large" });
 expect(restored.menuConfig).toEqual({ items: { invoices: { name: "Atual", enabled: true } } });
 expect(restored.imageCarousel).toEqual([]);
 expect(restored.backgroundColor).toBeUndefined();
 expect(restored.config).toEqual({ apiUrl: "preserve" });
 expect(restored.details).toEqual({ systemUrl: "operational" });
 expect(restored.applicationId).toBe("br.original");
 expect(restored.permissions).toEqual(["original"]);
 expect(state.docs.get("provedores/a/secrets/sgp")).toEqual(privateBefore);
 expect(state.reads.some(p => p.includes("/secrets/"))).toBe(false);
 expect(state.writes).toEqual(["provedores/a"]);
});
it("rejects malformed or unsupported backups without erasing customization", async () => {
 const original = structuredClone(state.docs.get("provedores/a"));
 for (const data of [
  { providerData: [] }, { providerData: "invalid" }, { providerData: null },
  { schemaVersion: 2, providerData: { themeColor: "#123" } },
 ]) {
  state.docs.set("provedores/a/backups/invalid", data);
  await expect(invoke(restoreProviderConfig, "provider", { backupId: "invalid" })).rejects.toMatchObject({ code: "invalid-argument" });
 }
 expect(state.docs.get("provedores/a")).toEqual(original);
 expect(state.writes).toEqual([]);
 expect(state.reads.some(p => p.includes("/secrets/"))).toBe(false);
});
it("rejects backup document paths and non-string IDs before reading or deleting", async () => {
 for (const backupId of [null, {}, [], "", " ", ".", "..", "old/data/mixed"]) {
  for (const handler of [restoreProviderConfig, deleteProviderBackup]) {
   await expect(invoke(handler, "provider", { backupId })).rejects.toMatchObject({ code: "invalid-argument" });
  }
 }
 expect(state.reads).toEqual([]);
 expect(state.writes).toEqual([]);
});
it("does not return arbitrary legacy backup metadata objects", async () => {
 state.docs.set("provedores/a/backups/mixed", {
  name: { apiToken: "synthetic" }, createdBy: { password: "synthetic" },
  createdAt: { secretReference: "synthetic" }, secrets: { apiToken: "synthetic" },
 });
 expect(await invoke(listProviderBackups, "provider", {})).toEqual([
  { id: "mixed", name: "", createdBy: "", createdAt: null },
 ]);
 await expect(invoke(backupProviderConfig, "provider", { name: { apiToken: "synthetic" } })).rejects.toMatchObject({ code: "invalid-argument" });
 expect(state.writes).toEqual([]);
});
it("company edits preserve operational legacy destination and native flags", async () => {
 const current = state.docs.get("provedores/a");
 current.details.hasAndroidApp = true;
 await invoke(updateProviderDetails, "provider", { details: { city: "Cidade" } });
 expect(state.docs.get("provedores/a").details).toEqual({ systemUrl: "operational", hasAndroidApp: true, city: "Cidade" });
 expect(state.reads.some(p => p.includes("/secrets/"))).toBe(false);
});
it.each(["provider", "saas"])("old mixed restore is exact and preserves private/native/admin state for %s", async uid => {
 const original = structuredClone(state.docs.get("provedores/a/secrets/sgp"));
 state.docs.set("provedores/a/backups/old", { name: "old", providerData: {
   name: "OLD", applicationId: "br.attacker", active: false, permissions: ["attacker"],
   config: { themeColor: "#123", integrations: { apiToken: "old-private" }, apiUrl: "https://old" },
   details: { systemUrl: "https://old" }, apiToken: "old-private", secretRef: "old",
 }, secrets: { integrations: { apiToken: "old-private" } } });
 await invoke(restoreProviderConfig, uid, { backupId: "old" });
 const current = state.docs.get("provedores/a");
 expect(current).toMatchObject({ name: "A", applicationId: "br.original", active: true, permissions: ["original"], themeColor: "#123", config: { apiUrl: "preserve" }, details: { systemUrl: "operational" } });
 expect(current.backgroundColor).toBeUndefined(); expect(current.config.logoUrl).toBeUndefined();
 expect(current.apiToken).toBeUndefined();
 expect(state.docs.get("provedores/a/secrets/sgp")).toEqual(original);
 expect(state.reads.some(p => p.includes("/secrets/"))).toBe(false);
 expect(state.writes).toEqual(["provedores/a"]);
 const list = await invoke(listProviderBackups, uid, {});
 expect(JSON.stringify(list)).not.toContain("old-private"); expect(list[0].providerData).toBeUndefined();
});
