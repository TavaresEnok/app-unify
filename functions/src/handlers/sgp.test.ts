import { beforeEach, afterEach, expect, it, vi } from "vitest";
const state = vi.hoisted(() => ({ docs: new Map<string, any>(), fail: false }));
function ref(path: string): any { return {
  get: async () => { if (state.fail) throw new Error("synthetic lookup failure"); return { exists: state.docs.has(path), data: () => state.docs.get(path) }; },
  collection: (name: string) => ({ doc: (id: string) => ref(`${path}/${name}/${id}`) }),
}; }
vi.mock("../app/firebase", () => ({ db: { collection: (name: string) => ({ doc: (id: string) => ref(`${name}/${id}`) }) }, auth: {
  getUser: async (uid: string) => ({ customClaims: { role: "providerAdmin", providerId: uid } }),
} }));
vi.mock("../app/config", () => ({ proxySecretParam: { value: () => "synthetic-proxy-secret" }, proxyUrlSecret: { value: () => "http://proxy.synthetic.test" } }));
import { sgpApiProxy } from "./sgp";
const invoke = (providerId: string, extra: any = {}, uid = providerId) => sgpApiProxy({ requesterUid: uid, requestId: "synthetic", type: "SGP_API_PROXY", payload: { providerId, action: "sync", ...extra } } as any);
beforeEach(() => {
  state.docs.clear(); state.fail = false;
  for (const id of ["a", "b"]) {
    state.docs.set(`provedores/${id}`, { details: { systemUrl: "https://public-forged", appName: "public-forged" } });
    state.docs.set(`provedores/${id}/secrets/sgp`, { integrations: { sgpBaseUrl: `https://${id}.synthetic.test`, appName: `app-${id}`, apiToken: `synthetic-token-${id}` } });
  }
  vi.stubGlobal("fetch", vi.fn(async () => new Response('{"jobId":"synthetic"}', { status: 200 })));
});
afterEach(() => vi.unstubAllGlobals());
it("sends only authenticated tenant identity to proxy, never private SGP or public forged credentials", async () => {
  for (const id of ["a", "b"]) await invoke(id);
  const calls = vi.mocked(fetch).mock.calls;
  expect(calls).toHaveLength(2);
  for (let i = 0; i < calls.length; i++) {
    expect(JSON.parse(calls[i][1]!.body as string)).toEqual({ secret: "synthetic-proxy-secret", providerId: ["a", "b"][i] });
    expect(calls[i][1]!.redirect).toBe("error");
  }
  expect(JSON.stringify(calls)).not.toMatch(/synthetic-token|public-forged/);
});
it("fails closed for missing/incomplete tenants, lookup failure, cross tenant and forged fields", async () => {
  await expect(invoke("missing")).rejects.toThrow();
  await expect(invoke("b", {}, "a")).rejects.toThrow();
  for (const key of ["sgpBaseUrl", "apiToken", "appName"]) {
    state.docs.set("provedores/a/secrets/sgp", { integrations: { sgpBaseUrl: "https://a.synthetic.test", apiToken: "synthetic-token-a", appName: "app-a", [key]: "" } });
    await expect(invoke("a")).rejects.toThrow();
  }
  for (const field of ["url", "token", "app", "sgpBaseUrl", "sgpParams"]) {
    await expect(invoke("a", { [field]: "forged" })).rejects.toThrow();
    await expect(invoke("a", { params: { [field]: "forged" } })).rejects.toThrow();
  }
  state.fail = true; await expect(invoke("a")).rejects.toThrow();
  expect(fetch).not.toHaveBeenCalled();
});
