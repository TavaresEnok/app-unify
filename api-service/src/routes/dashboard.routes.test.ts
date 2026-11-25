import express from "express";
import request from "supertest";
import { beforeEach, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  users: new Map<string, any>(),
  global: vi.fn(),
  provider: vi.fn(),
  verifyCount: 0,
}));

vi.mock("../services/postgres", () => ({
  requirePgPool: () => ({ query: async () => ({ rows: [] }) }),
  getPgPool: () => ({ query: async () => ({ rows: [] }) }),
  ensureCoreSchema: async () => undefined,
}));

vi.mock("../services/self-auth", () => ({
  verifyLiveSession: async (_pool: unknown, token: string) => {
    mocks.verifyCount++;
    const user = mocks.users.get(token);
    if (!user) throw Object.assign(Error("invalid"), { code: "auth/invalid-id-token" });
    if (user.disabled) throw Object.assign(Error("disabled"), { code: "auth/user-disabled" });
    return { uid: token, ...user.claims };
  },
}));

vi.mock("../services/dashboardPg", () => ({
  loadGlobalDashboardPg: mocks.global,
  loadProviderDashboardPg: mocks.provider,
}));

let app: express.Express;
beforeEach(async () => {
  vi.resetModules();
  vi.clearAllMocks();
  mocks.users.clear();
  mocks.verifyCount = 0;
  mocks.users.set("root", { disabled: false, claims: { role: "superAdmin", superAdmin: true } });
  mocks.users.set("admin-a", { disabled: false, claims: { role: "providerAdmin", providerId: "a", superAdmin: false } });
  mocks.users.set("sub", { disabled: false, claims: { role: "subscriber", providerId: "a", superAdmin: false } });
  mocks.global.mockResolvedValue({ stats: { providerCount: 2 }, chartData: [], recentTickets: [] });
  mocks.provider.mockImplementation(async (_db, providerId) => ({ stats: { totalClients: providerId === "a" ? 10 : 99 }, recentTickets: [] }));
  const { dashboardRouter } = await import("./dashboard.routes");
  const { errorHandler } = await import("../middlewares/errorHandler");
  app = express();
  app.use("/dashboard", dashboardRouter);
  app.use(errorHandler);
});

const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

it("serves dashboard reads directly and coalesces/caches reads after fresh role checks", async () => {
  const responses = await Promise.all([1, 2].map(() => request(app).get("/dashboard/panel").set(auth("root")).expect(200)));
  expect(responses[0].body.data.stats.providerCount).toBe(2);
  expect(responses[0].headers["cache-control"]).toBe("private, no-store");
  expect(mocks.global).toHaveBeenCalledTimes(1);
  expect(mocks.verifyCount).toBe(2);
});

it("rejects anonymous, subscriber and provider access to the global dashboard", async () => {
  await request(app).get("/dashboard/panel").expect(401);
  for (const token of ["sub", "admin-a"]) await request(app).get("/dashboard/panel").set(auth(token)).expect(403);
  expect(mocks.global).not.toHaveBeenCalled();
});

it("isolates provider data even after another provider is cached", async () => {
  await request(app).get("/dashboard/panel/providers/b").set(auth("root")).expect(200);
  await request(app).get("/dashboard/panel/providers/b").set(auth("admin-a")).expect(403);
  const response = await request(app).get("/dashboard/panel/providers/a").set(auth("admin-a")).expect(200);
  expect(response.body.data.stats.totalClients).toBe(10);
});

it("rejects disabled/revoked accounts despite old tokens and cached dashboard data", async () => {
  await request(app).get("/dashboard/panel").set(auth("root")).expect(200);
  mocks.users.set("root", { disabled: true, claims: { role: "superAdmin", superAdmin: true } });
  await request(app).get("/dashboard/panel").set(auth("root")).expect(401);
  mocks.users.set("root", { disabled: false, claims: { role: "subscriber", superAdmin: false } });
  await request(app).get("/dashboard/panel").set(auth("root")).expect(403);
  expect(mocks.global).toHaveBeenCalledTimes(1);
});

it("does not cache failures", async () => {
  mocks.global.mockRejectedValueOnce(Error("temporary"));
  await request(app).get("/dashboard/panel").set(auth("root")).expect(500);
  await request(app).get("/dashboard/panel").set(auth("root")).expect(200);
  expect(mocks.global).toHaveBeenCalledTimes(2);
});
