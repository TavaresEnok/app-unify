import express from "express";
import request from "supertest";
import { beforeEach, expect, it, vi } from "vitest";

const state = vi.hoisted(() => ({ docs: new Map<string, any>(), reads: 0 }));
vi.mock("../services/firebaseAdmin", () => ({
  firestore: { collection: (name: string) => ({ doc: (id: string) => ({
    get: async () => { state.reads++; const path = `${name}/${id}`; return { exists: state.docs.has(path), data: () => state.docs.get(path) }; },
  }) }) },
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
  state.docs.set("provedores/vibe", {
    name: "Vibe", layoutType: "layout_05", themeColor: "#112233",
    apiUrl: "http://10.0.0.5:8034",
    integrations: { apiToken: "synthetic-secret", sgpBaseUrl: "https://sgp.example" },
    details: { systemUrl: "https://sgp.example", apiToken: "synthetic-secret", phone: "8899" },
    config: { faq: [{ id: "1", question: "Q", answer: "A", password: "synthetic-secret" }], integrations: { apiToken: "synthetic-secret" } },
    menuConfig: { order: ["invoices"], items: { invoices: { enabled: true, name: "Faturas" } } },
    unknownField: "synthetic",
  });
});

it("serves the sanitized personalization without login", async () => {
  const response = await request(app).get("/public/providers/vibe/config").expect(200);
  expect(response.headers["cache-control"]).toBe("public, max-age=60");
  const data = response.body.data;
  expect(data).toMatchObject({ id: "vibe", name: "Vibe", layoutType: "layout_05", themeColor: "#112233",
    menuConfig: { order: ["invoices"], items: { invoices: { enabled: true, name: "Faturas" } } } });
  expect(data.config.faq).toEqual([{ id: "1", question: "Q", answer: "A" }]);
  expect(data.details).toEqual({ phone: "8899" });
  const body = JSON.stringify(data);
  for (const secret of ["synthetic-secret", "sgp.example", "integrations", "apiUrl", "10.0.0.5", "unknownField"]) expect(body).not.toContain(secret);
});

it("returns 404 for unknown providers and 400 for malformed ids without reading", async () => {
  await request(app).get("/public/providers/missing/config").expect(404);
  const reads = state.reads;
  await request(app).get("/public/providers/..%2Fsecrets/config").expect(400);
  await request(app).get(`/public/providers/${"a".repeat(65)}/config`).expect(400);
  expect(state.reads).toBe(reads);
});

it("caches briefly to spare Firestore reads", async () => {
  await request(app).get("/public/providers/vibe/config").expect(200);
  await request(app).get("/public/providers/vibe/config").expect(200);
  expect(state.reads).toBe(1);
});
