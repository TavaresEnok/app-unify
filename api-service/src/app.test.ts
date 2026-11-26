import { describe, expect, it, vi } from "vitest";
import request from "supertest";

vi.mock("./services/postgres", async (importOriginal) => {
  const actual = await importOriginal<typeof import("./services/postgres")>();
  return {
    ...actual,
    getPgPool: () => ({ query: async () => ({ rows: [] }) }) as any,
    requirePgPool: () => ({ query: async () => ({ rows: [] }) }) as any,
    ensureCoreSchema: async () => undefined,
    ensureNotificationSchema: async () => undefined,
  };
});

vi.mock("./services/self-auth", async (importOriginal) => {
  const actual = await importOriginal<typeof import("./services/self-auth")>();
  return {
    ...actual,
    verifyLiveSession: async (_pool: unknown, token: string) => {
      if (token === "test-root") return { uid: "root", sub: "root", role: "superAdmin", superAdmin: true, auth_time: 1, iat: 1, exp: 9999999999 };
      if (token === "test-provider") return { uid: "provider", sub: "provider", role: "providerAdmin", providerId: "one", superAdmin: false, auth_time: 1, iat: 1, exp: 9999999999 };
      if (token === "test-sub") return { uid: "subscriber", sub: "subscriber", role: "subscriber", providerId: "one", cpfCnpj: "12345678901", superAdmin: false, auth_time: 1, iat: 1, exp: 9999999999 };
      throw Object.assign(Error("Invalid test token"), { code: "auth/invalid-id-token" });
    },
  };
});

const { createApp } = await import("./app");

describe("api app", () => {
  const app = createApp();

  it("exposes a health check", async () => {
    const response = await request(app).get("/health").expect(200);
    expect(response.body.status).toBe("ok");
    expect(response.headers["x-correlation-id"]).toBeTruthy();
  });

  it("returns the standard error envelope for unknown routes", async () => {
    const response = await request(app).get("/missing").expect(404);
    expect(response.body.error.code).toBe("not-found");
    expect(response.body.error.correlationId).toBeTruthy();
  });

  it("rejects protected routes without a token", async () => {
    const response = await request(app).get("/admin/providers").expect(401);
    expect(response.body.error.code).toBe("unauthenticated");
  });

  it("limits performance reporting to administrators and viewing to SaaS admin", async () => {
    const data = { flow: "login", totalMs: 1500, authMs: 1000, apiMs: 300 };
    await request(app).post("/admin/performance").send(data).expect(401);
    await request(app).post("/admin/performance").set("Authorization", "Bearer test-sub").send(data).expect(403);
    await request(app).post("/admin/performance").set("Authorization", "Bearer test-provider").send(data).expect(204);
    await request(app).get("/admin/metrics").set("Authorization", "Bearer test-provider").expect(403);
    const response = await request(app).get("/admin/metrics").set("Authorization", "Bearer test-root").expect(200);
    expect(response.body.panel.some((sample: { role: string }) => sample.role === "providerAdmin")).toBe(true);
    await request(app).post("/admin/performance").set("Authorization", "Bearer test-root").send({ ...data, email: "private@example.test" }).expect(400);
  });

  it("answers malformed and oversized JSON as client errors, not 500", async () => {
    const bad = await request(app).post("/admin/auth/login").set("Content-Type", "application/json").send("{bad").expect(400);
    expect(bad.body.error.message).toBe("JSON inválido.");
    const big = JSON.stringify({ email: "a@b.c", password: "x".repeat(1_200_000) });
    const tooLarge = await request(app).post("/admin/auth/login").set("Content-Type", "application/json").send(big).expect(413);
    expect(tooLarge.body.error.message).toBe("Corpo da requisição muito grande.");
  });

  it("validates the subscriber login before calling the ERP proxy", async () => {
    const response = await request(app).post("/check-cpf").send({ providerId: "vibe", cpf: "123" }).expect(401);
    expect(response.body.error.message).toBe("Credenciais inválidas.");
    await request(app).post("/check-cpf").send({ providerId: "../x", cpf: "12345678901" }).expect(401);
  });
});
