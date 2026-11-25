import express from "express";
import request from "supertest";
import { beforeEach, expect, it, vi } from "vitest";

const state = vi.hoisted(() => ({ mode: "saas", checked: [] as string[] }));

vi.mock("../services/postgres", () => ({
  requirePgPool: () => ({
    query: async (sql: string, params: unknown[]) => {
      if (sql.includes("FROM providers")) {
        const id = String(params?.[0] || "");
        return id === "a" ? { rows: [{ id: "a", name: "A", active: true, data: {}, created_at: new Date(), updated_at: new Date() }] } : { rows: [] };
      }
      return { rows: [] };
    },
  }),
  getPgPool: () => null,
  ensureCoreSchema: async () => undefined,
}));

vi.mock("../services/self-auth", () => ({
  verifyLiveSession: async (_pool: unknown, token: string) => {
    state.checked.push(token);
    if (state.mode === "revoked") throw Object.assign(Error("unavailable"), { code: "auth/id-token-revoked" });
    if (state.mode === "disabled") throw Object.assign(Error("disabled"), { code: "auth/user-disabled" });
    if (state.mode === "outage") throw Object.assign(Error("unavailable"), { code: "authorization-unavailable" });
    const now = Math.floor(Date.now() / 1000);
    if (state.mode === "old-claim") return { uid: "real-user", role: "providerAdmin", providerId: "a", superAdmin: false, auth_time: now };
    if (state.mode === "stale") return { uid: "real-user", role: "superAdmin", superAdmin: true, auth_time: now - 600 };
    if (["subscriber", "provider", "client", "inconsistent-subscriber", "inconsistent-provider", "inconsistent-client"].includes(state.mode)) {
      const roleMap: Record<string, string> = {
        subscriber: "subscriber",
        provider: "providerAdmin",
        client: "client",
        "inconsistent-subscriber": "subscriber",
        "inconsistent-provider": "providerAdmin",
        "inconsistent-client": "client",
      };
      return {
        uid: "real-user",
        role: roleMap[state.mode],
        providerId: "a",
        superAdmin: state.mode.startsWith("inconsistent-"),
        auth_time: now,
      };
    }
    return { uid: "real-user", role: "superAdmin", superAdmin: true, auth_time: now };
  },
}));

import { buildAuthorizationRouter } from "./buildAuthorization.routes";

const app = express();
app.use(express.json());
app.use("/internal/builds", buildAuthorizationRouter);
const post = (extra = {}) => request(app).post("/internal/builds/authorize").set("Authorization", "Bearer synthetic").send({ providerId: "a", jobId: "job-1", purpose: "request", ...extra });

beforeEach(() => {
  state.mode = "saas";
  state.checked = [];
});

it.each(["subscriber", "provider", "client", "inconsistent-subscriber", "inconsistent-provider", "inconsistent-client", "old-claim", "disabled", "revoked", "stale", "outage"])("denies %s using current identity", async (mode) => {
  state.mode = mode;
  expect((await post({ superAdmin: true, tenant: "a" })).status).toBe(mode === "outage" ? 503 : 403);
  expect(state.checked).toEqual(["synthetic"]);
});

it("binds SaaS authorization to existing tenant, job and purpose", async () => {
  expect((await post()).body).toEqual({ authorized: true, uid: "real-user", providerId: "a", jobId: "job-1", purpose: "request" });
  expect((await post({ purpose: "spawn" })).status).toBe(200);
  expect((await post({ purpose: "publish" })).status).toBe(200);
  expect((await post({ purpose: "publish", jobId: "unaccepted" })).status).toBe(403);
  expect((await post({ purpose: "publish", providerId: "b" })).status).toBe(403);
  state.mode = "revoked";
  expect((await post({ purpose: "publish" })).status).toBe(403);
  state.mode = "saas";
  expect((await post({ providerId: "b" })).status).toBe(403);
  expect((await post({ purpose: "sign-anything" })).status).toBe(400);
  expect((await request(app).post("/internal/builds/authorize").send({ providerId: "a", jobId: "j", purpose: "spawn" })).status).toBe(403);
});
