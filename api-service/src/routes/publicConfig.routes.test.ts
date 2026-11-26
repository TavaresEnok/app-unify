import express from "express";
import request from "supertest";
import { beforeEach, expect, it, vi } from "vitest";

const state = vi.hoisted(() => ({ docs: new Map<string, any>(), reads: 0 }));

vi.mock("../services/postgres", () => ({
  requirePgPool: () => ({
    query: async (sql: string, params: unknown[]) => {
      if (!sql.includes("FROM providers")) return { rows: [] };
      state.reads++;
      const id = String(params?.[0] || "");
      const row = state.docs.get(id);
      if (!row) return { rows: [] };
      return {
        rows: [{
          id,
          name: row.name || id,
          active: row.active !== false,
          data: row,
          created_at: new Date("2026-11-24T00:00:00Z"),
          updated_at: new Date("2026-11-24T00:00:00Z"),
        }],
      };
    },
  }),
  getPgPool: () => null,
  ensureCoreSchema: async () => undefined,
}));
vi.mock("../middlewares/rateLimits", () => ({ publicConfigLimiter: (_req: unknown, _res: unknown, next: () => void) => next() }));

import { clearPublicConfigCache, publicConfigRouter } from "./publicConfig.routes";
import { errorHandler } from "../middlewares/errorHandler";

const app = express();
app.use("/public", publicConfigRouter);
app.use(errorHandler);

beforeEach(() => {
  state.docs.clear();
  state.reads = 0;
  clearPublicConfigCache();
  state.docs.set("vibe", {
    name: "Vibe", layoutType: "layout_05", themeColor: "#112233",
    apiUrl: "http://10.0.0.5:8034",
    integrations: { apiToken: "synthetic-secret", sgpBaseUrl: "https://sgp.example" },
    details: { systemUrl: "https://sgp.example", apiToken: "synthetic-secret", phone: "8899" },
    config: { faq: [{ id: "1", question: "Q", answer: "A", password: "synthetic-secret" }], integrations: { apiToken: "synthetic-secret" } },
    menuConfig: { order: ["invoices"], items: { invoices: { enabled: true, name: "Faturas" } } },
    logoFraming: { shape: "wide", fit: "cover", zoom: 1.4, x: 35, y: 65, password: "synthetic-secret" },
    unknownField: "synthetic",
  });
});

it("serves the sanitized personalization without login", async () => {
  const response = await request(app).get("/public/providers/vibe/config").expect(200);
  expect(response.headers["cache-control"]).toBe("public, max-age=30");
  const data = response.body.data;
  expect(data).toMatchObject({
    id: "vibe", name: "Vibe", layoutType: "layout_05", themeColor: "#112233",
    menuConfig: { order: ["invoices"], items: { invoices: { enabled: true, name: "Faturas" } } },
  });
  expect(data.logoFraming).toEqual({ shape: "wide", fit: "cover", zoom: 1.4, x: 35, y: 65 });
  expect(data.config.faq).toEqual([{ id: "1", question: "Q", answer: "A" }]);
  expect(data.details).toEqual({ phone: "8899" });
  const body = JSON.stringify(data);
  for (const secret of ["synthetic-secret", "sgp.example", "integrations", "apiUrl", "10.0.0.5", "unknownField"]) {
    expect(body).not.toContain(secret);
  }
});

it("returns 404 for unknown providers and 400 for malformed ids without reading", async () => {
  await request(app).get("/public/providers/missing/config").expect(404);
  const reads = state.reads;
  await request(app).get("/public/providers/..%2Fsecrets/config").expect(400);
  await request(app).get(`/public/providers/${"a".repeat(65)}/config`).expect(400);
  expect(state.reads).toBe(reads);
});

it("caches briefly to spare PostgreSQL reads", async () => {
  await request(app).get("/public/providers/vibe/config").expect(200);
  await request(app).get("/public/providers/vibe/config").expect(200);
  expect(state.reads).toBe(1);
});

it("coalesces simultaneous app startup reads and isolates providers", async () => {
  state.docs.set("other", { name: "Other", themeColor: "#fff" });
  const responses = await Promise.all(Array.from({ length: 40 }, (_, i) => request(app).get(`/public/providers/${i % 2 ? "vibe" : "other"}/config`)));
  expect(state.reads).toBe(2);
  responses.forEach((r, i) => { expect(r.status).toBe(200); expect(r.body.data.id).toBe(i % 2 ? "vibe" : "other"); });
});

it("returns generated privacy links when the provider has none, and keeps a custom one", async () => {
  const data = (await request(app).get("/public/providers/vibe/config").expect(200)).body.data;
  expect(data.privacyPolicyUrl).toBe("https://appisp.com.br/api/public/providers/vibe/privacidade");
  expect(data.dataDeletionUrl).toBe("https://appisp.com.br/api/public/providers/vibe/exclusao-de-dados");
  state.docs.set("custom", { name: "Custom", other: { privacyPolicyUrl: "https://custom.example/privacidade" } });
  const custom = (await request(app).get("/public/providers/custom/config").expect(200)).body.data;
  expect(custom.privacyPolicyUrl).toBe("https://custom.example/privacidade");
});

it("serves appVersion normalized for the app", async () => {
  state.docs.set("upd", { name: "Upd", applicationId: "br.com.provedores.upd", appVersion: { minVersion: "1.0.20", latestVersion: "1.0.25", forceUpdate: true } });
  const forced = (await request(app).get("/public/providers/upd/config").expect(200)).body.data;
  expect(forced.appVersion).toMatchObject({ minVersion: "1.0.20", latestVersion: "1.0.25", storeUrl: "https://play.google.com/store/apps/details?id=br.com.provedores.upd" });
  clearPublicConfigCache();
  state.docs.set("upd", { name: "Upd", appVersion: { minVersion: "1.0.20", latestVersion: "1.0.25", forceUpdate: false, storeUrls: { android: "https://play.google.com/store/apps/details?id=x.y" } } });
  const soft = (await request(app).get("/public/providers/upd/config").expect(200)).body.data;
  expect(soft.appVersion.minVersion).toBeUndefined();
  expect(soft.appVersion).toMatchObject({ latestVersion: "1.0.25", storeUrl: "https://play.google.com/store/apps/details?id=x.y" });
  expect((await request(app).get("/public/providers/vibe/config").expect(200)).body.data.appVersion).toBeUndefined();
});

it("serves privacy and data deletion pages as escaped HTML", async () => {
  state.docs.set("pg", {
    name: "Pg <script>alert(1)</script>", themeColor: "#123456",
    details: { email: "contato@pg.example", telefone: "(85) 4000-0000", razaoSocial: "PG Telecom LTDA", cnpj: "00.000.000/0001-00" },
    supportChannels: [{ id: "1", type: "whatsapp", value: "5585999990000", name: "WhatsApp" }],
  });
  const privacy = await request(app).get("/public/providers/pg/privacidade").expect(200);
  expect(privacy.headers["content-type"]).toContain("text/html");
  expect(privacy.text).toContain("Política de privacidade");
  expect(privacy.text).toContain("CPF ou CNPJ");
  expect(privacy.text).toContain("localização");
  expect(privacy.text).toContain("mailto:contato@pg.example");
  expect(privacy.text).toContain("https://wa.me/5585999990000");
  expect(privacy.text).not.toContain("<script>alert(1)</script>");
  expect(privacy.text).toContain("&lt;script&gt;");
  const deletion = await request(app).get("/public/providers/pg/exclusao-de-dados").expect(200);
  expect(deletion.text).toContain("Exclusão de dados");
  expect(deletion.text).toContain("/public/providers/pg/privacidade");
  await request(app).get("/public/providers/missing/privacidade").expect(404);
});

it("serves terms of use as plain escaped text and links them in the config", async () => {
  state.docs.set("tos", {
    name: "Tos",
    termsOfUse: "<h2>Uso</h2><p>Primeira <b>regra</b> &amp; mais.</p><script>alert(1)</script><p onclick=\"x()\">Segunda</p>",
  });
  const page = await request(app).get("/public/providers/tos/termos").expect(200);
  expect(page.text).toContain("Termos de uso");
  expect(page.text).toContain("<p>Primeira regra &amp; mais.</p>");
  expect(page.text).toContain("<p>Segunda</p>");
  expect(page.text).not.toContain("alert(1)");
  expect(page.text).not.toContain("onclick");
  const config = (await request(app).get("/public/providers/tos/config").expect(200)).body.data;
  expect(config.termsUrl).toBe("https://appisp.com.br/api/public/providers/tos/termos");

  state.docs.set("tos2", { name: "Sem termos", termsOfUse: "<p>Estes são os termos de uso padrão. Por favor, edite-os no painel.</p>" });
  expect((await request(app).get("/public/providers/tos2/config").expect(200)).body.data.termsUrl).toBeUndefined();
});
