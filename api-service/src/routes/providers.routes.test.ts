import express from "express";
import request from "supertest";
import { beforeEach, expect, it, vi } from "vitest";
import sgpOutbound from "../services/sgp-outbound";

const state = vi.hoisted(() => ({
  providers: new Map<string, any>(),
  secrets: new Map<string, any>(),
  audits: [] as any[],
  verified: [] as string[],
  access: "active",
}));

const claims = (token: string): any => ({
  uid: token,
  sub: token,
  auth_time: Math.floor(Date.now() / 1000),
  ...(token === "saas"
    ? { role: "superAdmin", superAdmin: true }
    : { role: token === "subscriber" ? "subscriber" : "providerAdmin", providerId: token === "other" ? "b" : "a", superAdmin: false }),
});

vi.mock("../services/postgres", () => ({
  requirePgPool: () => ({ query: async () => ({ rows: [] }) }),
  getPgPool: () => ({ query: async () => ({ rows: [] }) }),
  ensureCoreSchema: async () => undefined,
}));

vi.mock("../services/self-auth", async (importOriginal) => {
  const actual = await importOriginal<typeof import("../services/self-auth")>();
  return {
    ...actual,
    verifyLiveSession: async (_pool: unknown, token: string) => {
      state.verified.push(token);
      if (state.access === "revoked") throw Object.assign(new Error("revoked"), { code: "auth/id-token-revoked" });
      if (state.access === "disabled") throw Object.assign(new Error("disabled"), { code: "auth/user-disabled" });
      if (state.access === "demoted") return { uid: token, sub: token, role: "providerAdmin", providerId: "a", superAdmin: false, auth_time: Math.floor(Date.now() / 1000) };
      const c = claims(token);
      return { ...c, ...(state.access === "stale" ? { auth_time: Math.floor(Date.now() / 1000) - 600 } : {}) };
    },
  };
});

vi.mock("../services/providersStore", async () => {
  const { publicProviderData } = await import("../services/providerConfig");
  const serialize = (id: string, data: any) => {
    const clean = { ...data };
    delete clean.integrations;
    if (clean.config && typeof clean.config === "object") {
      clean.config = { ...clean.config };
      delete clean.config.integrations;
    }
    return { ...publicProviderData(clean), id };
  };
  return {
    listProviderRows: async () => [...state.providers.entries()].map(([id, data]) => ({ id, name: data.name || id, active: data.active !== false, data, created_at: new Date(), updated_at: new Date() })),
    getProviderRow: async (_p: unknown, id: string) => {
      const data = state.providers.get(id);
      return data ? { id, name: data.name || id, active: data.active !== false, data, created_at: new Date(), updated_at: new Date() } : null;
    },
    serializeProviderRow: (row: any) => serialize(row.id, row.data),
    upsertProvider: async (_p: unknown, id: string | null, input: Record<string, unknown>) => {
      const targetId = id || "generated-id";
      const next = { ...(state.providers.get(targetId) || {}), ...input };
      state.providers.set(targetId, next);
      return { id: targetId, name: String(next.name || targetId), active: next.active !== false, data: next, created_at: new Date(), updated_at: new Date() };
    },
    deleteProviderRow: async (_p: unknown, id: string) => state.providers.delete(id),
    saveProviderSecret: async (_p: unknown, id: string, kind: string, value: any) => { state.secrets.set(`${id}:${kind}`, value); },
    getProviderSecret: async (_p: unknown, id: string, kind: string) => state.secrets.get(`${id}:${kind}`) || null,
    listProviderBackups: async () => [],
    createProviderBackup: async () => ({ id: "b1", createdAt: new Date().toISOString() }),
    getProviderBackup: async () => null,
    deleteProviderBackup: async () => false,
  };
});

vi.mock("../services/auditService", () => ({ recordAdminAudit: async (data: any) => state.audits.push(data) }));
import { providersRouter } from "./providers.routes";
import { errorHandler } from "../middlewares/errorHandler";

const app = express();
app.use(express.json());
app.use(providersRouter);
app.use(errorHandler);
const post = (uid: string, path: string, data: any) => request(app).post(path).set("Authorization", "Bearer " + uid).send(data);

beforeEach(() => {
  state.access = "active";
  state.providers.clear();
  state.secrets.clear();
  state.audits.length = 0;
  state.verified.length = 0;
  state.providers.set("a", {
    name: "A",
    themeColor: "#123",
    details: { systemUrl: "private-url", appName: "private-app", apiToken: "synthetic" },
    config: { faq: [{ question: "Q", answer: "A", password: "synthetic" }], unknown: "synthetic" },
    unknown: "synthetic",
  });
  vi.spyOn(sgpOutbound, "assertSafeSgpBaseUrl").mockImplementation(async (url: string) => {
    const transport: any = sgpOutbound.createSgpTransport({ lookup: async () => [{ address: "8.8.8.8", family: 4 }] });
    return transport.assertSafeSgpBaseUrl(url);
  });
});

it("denies subscriber and cross tenant mutations", async () => {
  expect((await post("subscriber", "/", { id: "a", themeColor: "#fff" })).status).toBe(403);
  expect((await post("other", "/", { id: "a", themeColor: "#fff" })).status).toBe(403);
});

it("rejects root, nested, unknown and typed credential payloads without side effects", async () => {
  for (const uid of ["provider", "saas"]) {
    for (const data of [
      { details: { apiToken: "injected" } }, { config: { integrations: { apiToken: "injected" } } },
      { faq: [{ question: "Q", answer: "A", secret: "injected" }] }, { apiUrl: "injected" }, { mystery: {} },
      { typography: { fontFamily: { token: "injected" } } },
    ]) expect((await post(uid, "/", { id: "a", ...data })).status).toBe(400);
  }
  expect(state.audits).toEqual([]);
});

it("sanitizes legacy outputs for SaaS and provider while preserving branding", async () => {
  state.providers.get("a").apiUrl = "private-url";
  for (const uid of ["provider", "saas"]) {
    const result = await request(app).get("/").set("Authorization", "Bearer " + uid);
    expect(result.status).toBe(200);
    expect(JSON.stringify(result.body)).not.toMatch(/synthetic|private-url|private-app/);
    expect(result.body.data[0]).toMatchObject({ id: "a", themeColor: "#123", config: { faq: [{ question: "Q", answer: "A" }] } });
  }
});

it("rejects non-string IDs instead of silently creating a provider", async () => {
  expect((await post("saas", "/", { id: { token: "synthetic" }, name: "A" })).status).toBe(400);
  expect(state.audits).toEqual([]);
});

it("personalizes without altering private credentials", async () => {
  state.secrets.set("a:erp", { apiToken: "operational" });
  expect((await post("provider", "/", { id: "a", themeColor: "#fff" })).status).toBe(200);
  expect(state.secrets.get("a:erp")).toEqual({ apiToken: "operational" });
});

it("allows only SaaS private replacement, checks revocation and never returns stored value", async () => {
  const data = { apiToken: "replacement-synthetic", sgpBaseUrl: "https://sgp.test", appName: "new-app" };
  expect((await post("provider", "/a/integration", data)).status).toBe(403);
  const result = await post("saas", "/a/integration", data);
  expect(result.status).toBe(200);
  expect(result.body).toEqual({ success: true });
  expect(state.verified).toContain("saas");
  expect(state.secrets.get("a:erp")).toEqual(data);
  expect(JSON.stringify(state.audits)).not.toContain("replacement-synthetic");
  expect((await post("saas", "/a/integration", { ...data, unexpected: "injected" })).status).toBe(400);
});

it("grava integração IXC só com token e URL, sem app, e rejeita ERP desconhecido", async () => {
  const ixc = { erp: "ixc", apiToken: "ixc-synthetic", sgpBaseUrl: "https://ixc.test" };
  expect((await post("saas", "/a/integration", { ...ixc, appName: "ignorado" })).status).toBe(200);
  expect(state.secrets.get("a:erp")).toEqual(ixc);
  expect((await post("saas", "/a/integration", { ...ixc, erp: "outro" })).status).toBe(400);
  expect((await post("saas", "/a/integration", { apiToken: "x", sgpBaseUrl: "https://sgp.test", erp: "sgp" })).status).toBe(400);
  expect((await post("saas", "/a/integration", { apiToken: "s", sgpBaseUrl: "https://sgp.test", appName: "app", erp: "sgp" })).status).toBe(200);
  expect(state.secrets.get("a:erp")).toEqual({ apiToken: "s", sgpBaseUrl: "https://sgp.test", appName: "app" });
  expect(JSON.stringify(state.audits)).not.toContain("ixc-synthetic");
});

it.each(["https://127.1", "https://[::1]", "https://[::ffff:7f00:1]", "https://[2d00::1]", "https://[3000::1]", "https://[3ffe::1]", "https://user:pass@sgp.test/", "https://sgp.test/?token=forged", "https://sgp.test/#x"])("rejects unsafe SaaS candidate %s before persisting", async (sgpBaseUrl) => {
  const original = { apiToken: "synthetic-original", sgpBaseUrl: "https://original.test", appName: "original" };
  state.secrets.set("a:erp", original);
  expect((await post("saas", "/a/integration", { sgpBaseUrl, appName: "new", apiToken: "synthetic-candidate" })).status).toBe(400);
  expect(state.secrets.get("a:erp")).toEqual(original);
  expect(state.audits).toEqual([]);
});

it.each(["10.0.0.1", "2d00::1", "3000::1", "3ffe::1"])("rejects mixed DNS including %s at SaaS registration before persisting", async (address) => {
  const transport: any = sgpOutbound.createSgpTransport({ lookup: async () => [{ address: "8.8.8.8", family: 4 }, { address, family: address.includes(":") ? 6 : 4 }] });
  vi.mocked(sgpOutbound.assertSafeSgpBaseUrl).mockImplementation(transport.assertSafeSgpBaseUrl);
  expect((await post("saas", "/a/integration", { sgpBaseUrl: "https://sgp.test", appName: "new", apiToken: "synthetic-candidate" })).status).toBe(400);
  expect(state.secrets.has("a:erp")).toBe(false);
  expect(state.audits).toEqual([]);
});

it.each(["revoked", "disabled", "demoted", "stale"])("preserves private credentials when SaaS access is %s", async (access) => {
  const original = { apiToken: "synthetic-operational", sgpBaseUrl: "https://original.test", appName: "original" };
  state.secrets.set("a:erp", structuredClone(original));
  state.access = access;
  const result = await post("saas", "/a/integration", { apiToken: "synthetic-new", sgpBaseUrl: "https://new.test", appName: "new" });
  expect(result.status).toBe(["revoked", "disabled"].includes(access) ? 401 : 403);
  expect(state.secrets.get("a:erp")).toEqual(original);
  expect(state.audits).toEqual([]);
  expect(JSON.stringify(result.body)).not.toContain("synthetic");
});

it("loads one sanitized provider and denies cross-tenant reads", async () => {
  const response = await request(app).get("/a").set("Authorization", "Bearer provider").expect(200);
  expect(response.body.data.id).toBe("a");
  expect(JSON.stringify(response.body)).not.toContain("synthetic");
  await request(app).get("/a").set("Authorization", "Bearer other").expect(403);
  await request(app).get("/a").set("Authorization", "Bearer subscriber").expect(403);
  await request(app).get("/missing").set("Authorization", "Bearer saas").expect(404);
});

it("saves personalization over HTTP without widening the schema or altering secrets", async () => {
  state.secrets.set("a:erp", { apiToken: "private" });
  const patch = (uid: string, body: any) => request(app).patch("/a/config").set("Authorization", "Bearer " + uid).send(body);
  await patch("other", { themeColor: "#fff" }).expect(403);
  await patch("subscriber", { themeColor: "#fff" }).expect(403);
  for (const body of [{ details: { appName: "bad" } }, { config: { integrations: {} } }, { name: "bad" }, { faq: [{ question: "Q", answer: "A", token: "bad" }] }]) {
    await patch("provider", body).expect(400);
  }
  await patch("provider", { themeColor: "#fff", logoUrl: "https://example.test/logo.png" }).expect(200);
  expect(state.providers.get("a").themeColor).toBe("#fff");
  expect(state.secrets.get("a:erp")).toEqual({ apiToken: "private" });
  expect(state.audits).toHaveLength(1);
});
