import express from "express";
import request from "supertest";
import { beforeEach, expect, it, vi } from "vitest";

const state = vi.hoisted(() => ({
  identity: { uid: "a", role: "providerAdmin", providerId: "a", superAdmin: false } as any,
  failure: "",
  checks: [] as string[],
}));

vi.mock("../services/postgres", () => ({
  requirePgPool: () => ({ query: async () => ({ rows: [] }) }),
  getPgPool: () => ({ query: async () => ({ rows: [] }) }),
}));

vi.mock("../services/self-auth", () => ({
  verifyLiveSession: async (_pool: unknown, token: string) => {
    state.checks.push(token);
    if (state.failure === "revoked") throw Object.assign(Error(), { code: "auth/id-token-revoked" });
    if (state.failure === "disabled") throw Object.assign(Error(), { code: "auth/user-disabled" });
    if (state.failure === "removed") return { uid: "a", role: "", superAdmin: false };
    if (state.failure === "tenant") throw Object.assign(Error(), { code: "access/scope-changed" });
    if (state.failure === "subscriber-old-admin") throw Object.assign(Error(), { code: "access/scope-changed" });
    if (state.failure === "outage") throw Error("private");
    return state.identity;
  },
}));

import { verifyToken, verifyAdmin, canAccessProvider, authenticateIfPresent } from "./auth";
import { errorHandler } from "./errorHandler";

const app = express();
app.use((req, _res, next) => { req.user = { uid: "forged", superAdmin: true } as any; next(); });
app.get("/:tenant", verifyToken, verifyAdmin, (req, res) => res.status(canAccessProvider(req, req.params.tenant) ? 200 : 403).json({ uid: req.user?.uid }));
app.use(errorHandler);

beforeEach(() => {
  state.identity = { uid: "a", role: "providerAdmin", providerId: "a", superAdmin: false };
  state.failure = "";
  state.checks = [];
});

const get = (tenant = "a") => request(app).get("/" + tenant).set("Authorization", "Bearer synthetic");

it("uses verified identity and current tenant, never preexisting req.user", async () => {
  expect((await get()).body.uid).toBe("a");
  expect(state.checks).toEqual(["synthetic"]);
  await get("b").expect(403);
  await request(app).get("/a").expect(401);
});

it.each(["revoked", "disabled", "removed", "tenant", "subscriber-old-admin", "outage"])("denies %s without data", async (mode) => {
  state.failure = mode;
  const result = await get();
  expect(result.status).toBe(mode === "outage" ? 503 : ["disabled", "revoked"].includes(mode) ? 401 : 403);
  if (mode === "outage") expect(result.body.error.code).toBe("authorization-unavailable");
  expect(result.body.uid).toBeUndefined();
});

it("verifies once per HTTP request, still checks every new request and rejects changed credentials", async () => {
  const routed = express();
  routed.use(authenticateIfPresent);
  routed.get("/a", verifyToken, verifyAdmin, (_req, res) => res.json({ ok: true }));
  routed.get("/changed", (req, _res, next) => { req.headers.authorization = "Bearer changed"; next(); }, verifyToken, (_req, res) => res.json({ ok: true }));
  routed.use(errorHandler);

  await request(routed).get("/a").set("Authorization", "Bearer synthetic").expect(200);
  expect(state.checks).toEqual(["synthetic"]);
  await request(routed).get("/a").set("Authorization", "Bearer synthetic").expect(200);
  expect(state.checks).toEqual(["synthetic", "synthetic"]);
  await request(routed).get("/changed").set("Authorization", "Bearer synthetic").expect(200);
  expect(state.checks).toHaveLength(4);
  state.failure = "revoked";
  await request(routed).get("/a").set("Authorization", "Bearer synthetic").expect(401);
});
