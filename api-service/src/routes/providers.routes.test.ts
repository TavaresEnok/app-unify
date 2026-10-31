import express from "express";
import request from "supertest";
import { beforeEach, expect, it, vi } from "vitest";
import sgpOutbound from "../services/sgp-outbound";
const state = vi.hoisted(() => ({ docs: new Map<string, any>(), audits: [] as any[], verified: [] as any[], access: "active" }));
const claims = (token: string): any => ({ uid: token, auth_time: Math.floor(Date.now()/1000), ...(token === "saas" ? { superAdmin: true } : { role: token === "subscriber" ? "subscriber" : "providerAdmin", providerId: token === "other" ? "b" : "a" }) });
function ref(path: string): any { return {
 get: async () => ({ id: path.split("/").pop(), exists: state.docs.has(path), data: () => state.docs.get(path) }),
 set: async (d: any) => state.docs.set(path, { ...state.docs.get(path), ...d }),
 collection: (n: string) => collection(path + "/" + n),
}; }
function collection(path: string): any { return { doc: (id: string) => ref(path + "/" + id), get: async () => ({ docs: [...state.docs].filter(([k]) => k.startsWith(path + "/") && !k.slice(path.length + 1).includes("/")).map(([k, v]) => ({ id: k.split("/").pop(), data: () => v })) }) }; }
vi.mock("../services/firebaseAdmin", () => ({ firestore: { collection }, serverTimestamp: () => "now", firebaseAuth: {
 verifyIdToken: async (token: string, revoked?: boolean) => {
  state.verified.push(revoked);
  if (revoked && state.access === "revoked") throw new Error("revoked");
  return { ...claims(token), ...(state.access === "stale" ? { auth_time: Math.floor(Date.now()/1000) - 600 } : {}) };
 },
 getUser: async (uid: string) => ({ disabled: state.access === "disabled", customClaims: state.access === "demoted" ? {} : claims(uid) }),
} }));
vi.mock("../services/auditService", () => ({ recordAdminAudit: async (data: any) => state.audits.push(data) }));
import { providersRouter } from "./providers.routes";
import { errorHandler } from "../middlewares/errorHandler";
const app = express(); app.use(express.json()); app.use(providersRouter); app.use(errorHandler);
const post = (uid: string, path: string, data: any) => request(app).post(path).set("Authorization", "Bearer " + uid).send(data);
beforeEach(() => { state.access = "active"; state.docs.clear(); state.audits.length = 0; state.verified.length = 0; state.docs.set("provedores/a", { name: "A", themeColor: "#123", details: { systemUrl: "private-url", appName: "private-app", apiToken: "synthetic" }, config: { faq: [{ question: "Q", answer: "A", password: "synthetic" }], unknown: "synthetic" }, unknown: "synthetic" });
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
 for (const uid of ["provider", "saas"]) for (const data of [
 { details: { apiToken: "injected" } }, { config: { integrations: { apiToken: "injected" } } },
 { faq: [{ question: "Q", answer: "A", secret: "injected" }] }, { apiUrl: "injected" }, { mystery: {} },
 { typography: { fontFamily: { token: "injected" } } },
 ]) expect((await post(uid, "/", { id: "a", ...data })).status).toBe(400);
 expect(state.audits).toEqual([]);
});
it("sanitizes legacy outputs for SaaS and provider while preserving branding", async () => {
 state.docs.get("provedores/a").apiUrl = "private-url";
 for (const uid of ["provider", "saas"]) {
  const result = await request(app).get("/").set("Authorization", "Bearer " + uid);
  expect(result.status).toBe(200); expect(JSON.stringify(result.body)).not.toMatch(/synthetic|private-url|private-app/);
  expect(result.body.data[0]).toMatchObject({ id: "a", themeColor: "#123", config: { faq: [{ question: "Q", answer: "A" }] } });
 }
});
it("rejects non-string IDs instead of silently creating a provider", async () => {
 expect((await post("saas", "/", { id: { token: "synthetic" }, name: "A" })).status).toBe(400);
 expect(state.audits).toEqual([]);
});
it("personalizes without altering private credentials", async () => {
 state.docs.set("provedores/a/secrets/sgp", { integrations: { apiToken: "operational" } });
 expect((await post("provider", "/", { id: "a", themeColor: "#fff" })).status).toBe(200);
 expect(state.docs.get("provedores/a/secrets/sgp")).toEqual({ integrations: { apiToken: "operational" } });
});
it("allows only SaaS private replacement, checks revocation and never returns stored value", async () => {
 const data = { apiToken: "replacement-synthetic", sgpBaseUrl: "https://sgp.test", appName: "new-app" };
 expect((await post("provider", "/a/integration", data)).status).toBe(403);
 const result = await post("saas", "/a/integration", data);
 expect(result.status).toBe(200); expect(result.body).toEqual({ success: true });
 expect(state.verified).toContain(true);
 expect(state.docs.get("provedores/a/secrets/sgp").integrations).toEqual(data);
 expect(JSON.stringify(state.audits)).not.toContain("replacement-synthetic");
 expect((await post("saas", "/a/integration", { ...data, unexpected: "injected" })).status).toBe(400);
});
it.each(["https://127.1", "https://[::1]", "https://[::ffff:7f00:1]", "https://[2d00::1]", "https://[3000::1]", "https://[3ffe::1]", "https://user:pass@sgp.test/", "https://sgp.test/?token=forged", "https://sgp.test/#x"])("rejects unsafe SaaS candidate %s before persisting", async sgpBaseUrl => {
 const original = { integrations: { apiToken: "synthetic-original", sgpBaseUrl: "https://original.test", appName: "original" } };
 state.docs.set("provedores/a/secrets/sgp", original);
 expect((await post("saas", "/a/integration", { sgpBaseUrl, appName: "new", apiToken: "synthetic-candidate" })).status).toBe(400);
 expect(state.docs.get("provedores/a/secrets/sgp")).toEqual(original); expect(state.audits).toEqual([]);
});
it.each(["10.0.0.1", "2d00::1", "3000::1", "3ffe::1"])("rejects mixed DNS including %s at SaaS registration before persisting", async address => {
 const transport: any = sgpOutbound.createSgpTransport({ lookup: async () => [{ address: "8.8.8.8", family: 4 }, { address, family: address.includes(":") ? 6 : 4 }] });
 vi.mocked(sgpOutbound.assertSafeSgpBaseUrl).mockImplementation(transport.assertSafeSgpBaseUrl);
 expect((await post("saas", "/a/integration", { sgpBaseUrl: "https://sgp.test", appName: "new", apiToken: "synthetic-candidate" })).status).toBe(400);
 expect(state.docs.has("provedores/a/secrets/sgp")).toBe(false); expect(state.audits).toEqual([]);
});
it.each(["revoked", "disabled", "demoted", "stale"])("preserves private credentials when SaaS access is %s", async access => {
 const original = { integrations: { apiToken: "synthetic-operational", sgpBaseUrl: "https://original.test", appName: "original" } };
 state.docs.set("provedores/a/secrets/sgp", structuredClone(original));
 state.access = access;
 const result = await post("saas", "/a/integration", { apiToken: "synthetic-new", sgpBaseUrl: "https://new.test", appName: "new" });
 expect(result.status).toBe(403);
 expect(state.docs.get("provedores/a/secrets/sgp")).toEqual(original);
 expect(state.audits).toEqual([]);
 expect(JSON.stringify(result.body)).not.toContain("synthetic");
});
