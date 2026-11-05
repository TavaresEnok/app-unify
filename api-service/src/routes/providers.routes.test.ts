import { describe, expect, it, vi } from "vitest";
import express from "express";
import request from "supertest";

const { set } = vi.hoisted(() => ({ set: vi.fn(async () => {}) }));
vi.mock("../services/firebaseAdmin", () => ({
  firestore: { collection: () => ({ doc: () => ({ set }) }) },
  serverTimestamp: () => "now",
  firebaseAuth: { verifyIdToken: async () => ({ uid: "admin", role: "providerAdmin", providerId: "alpha" }) },
}));
vi.mock("../services/auditService", () => ({ recordAdminAudit: vi.fn(async () => {}) }));
import { providersRouter, sanitizeProviderData } from "./providers.routes";

describe("provider public data", () => {
  it("removes credentials recursively while preserving public configuration and SDK values", () => {
    const date = new Date();
    expect(sanitizeProviderData({ date, details: { api_token: "secret", name: "ISP" },
      config: { items: [[{ integrations: { token: "secret" }, label: "Menu" }]] } }))
      .toEqual({ date, details: { name: "ISP" }, config: { items: [[{ label: "Menu" }]] } });
  });

  it("does not allow a provider administrator to redirect the legacy SGP destination", async () => {
    const app = express();
    app.use(express.json());
    app.use("/providers", providersRouter);
    await request(app).post("/providers").set("Authorization", "Bearer test").send({
      id: "alpha", sgpBaseUrl: "https://attacker.test", appName: "forged",
      details: { systemUrl: "https://attacker.test", appName: "forged", nomeFantasia: "Alpha" },
      config: { nested: { apiToken: "secret", theme: "blue" } },
    }).expect(200);
    expect(set).toHaveBeenCalledWith({ details: { nomeFantasia: "Alpha" }, config: { nested: { theme: "blue" } }, updatedAt: "now" }, { merge: true });
  });
});
