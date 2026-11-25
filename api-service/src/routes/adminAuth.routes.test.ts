import express from "express";
import request from "supertest";
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { clearKeyCacheForTests, hashPassword, signJwt, verifyJwt } from "../services/self-auth";

interface AdminRow {
  uid: string;
  email: string;
  password_hash: string;
  role: "superAdmin" | "providerAdmin";
  provider_id: string | null;
  disabled: boolean;
  token_version: number;
}

const admins = new Map<string, AdminRow>();

vi.mock("../services/postgres", () => ({
  ensureCoreSchema: async () => undefined,
  requirePgPool: () => ({
    query: async (sql: string, params: unknown[] = []) => {
      if (sql.includes("FROM admin_users") && sql.includes("LOWER(email) = $1")) {
        const email = String(params[0] || "").toLowerCase();
        const found = Array.from(admins.values()).find((row) => row.email.toLowerCase() === email);
        return { rows: found ? [found] : [] };
      }
      if (sql.includes("FROM admin_users") && sql.includes("WHERE uid = $1")) {
        const found = admins.get(String(params[0] || ""));
        return { rows: found ? [found] : [] };
      }
      if (sql.includes("UPDATE admin_users SET token_version = token_version + 1")) {
        const found = admins.get(String(params[0] || ""));
        if (found) found.token_version += 1;
        return { rows: [] };
      }
      return { rows: [] };
    },
  }),
}));

const { adminAuthRouter } = await import("./adminAuth.routes");
const { errorHandler } = await import("../middlewares/errorHandler");

const app = express();
app.use(express.json());
app.use("/admin/auth", adminAuthRouter);
app.use(errorHandler);

const prevJwt = process.env.JWT_SECRET;
const prevSec = process.env.APP_SECRETS_KEY;

describe("adminAuthRouter", () => {
  beforeAll(() => {
    process.env.JWT_SECRET = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    process.env.APP_SECRETS_KEY = "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210";
    clearKeyCacheForTests();
  });

  afterAll(() => {
    if (prevJwt === undefined) delete process.env.JWT_SECRET;
    else process.env.JWT_SECRET = prevJwt;
    if (prevSec === undefined) delete process.env.APP_SECRETS_KEY;
    else process.env.APP_SECRETS_KEY = prevSec;
    clearKeyCacheForTests();
  });

  beforeEach(() => {
    admins.clear();
    admins.set("u-super", {
      uid: "u-super",
      email: "super@test.local",
      password_hash: hashPassword("Secret123!"),
      role: "superAdmin",
      provider_id: null,
      disabled: false,
      token_version: 1,
    });
  });

  it("logs in, validates /me, reauthenticates, and revokes on /logout", async () => {
    const bad = await request(app).post("/admin/auth/login").send({ email: "super@test.local", password: "wrong" });
    expect(bad.status).toBe(401);

    const ok = await request(app).post("/admin/auth/login").send({ email: "Super@Test.Local", password: "Secret123!" });
    expect(ok.status).toBe(200);
    expect(ok.body.user).toMatchObject({ uid: "u-super", email: "super@test.local", superAdmin: true, providerId: null });
    const claims = verifyJwt(ok.body.token);
    expect(claims.uid).toBe("u-super");

    const me = await request(app).get("/admin/auth/me").set("Authorization", `Bearer ${ok.body.token}`);
    expect(me.status).toBe(200);
    expect(me.body.user.superAdmin).toBe(true);

    const reauthBad = await request(app).post("/admin/auth/reauthenticate").set("Authorization", `Bearer ${ok.body.token}`).send({ password: "bad" });
    expect(reauthBad.status).toBe(403);

    const reauthOk = await request(app).post("/admin/auth/reauthenticate").set("Authorization", `Bearer ${ok.body.token}`).send({ password: "Secret123!" });
    expect(reauthOk.status).toBe(200);
    expect(typeof reauthOk.body.token).toBe("string");

    const logout = await request(app).post("/admin/auth/logout").set("Authorization", `Bearer ${reauthOk.body.token}`).send({});
    expect(logout.status).toBe(200);
    expect(admins.get("u-super")?.token_version).toBe(2);

    const meAfterLogout = await request(app).get("/admin/auth/me").set("Authorization", `Bearer ${ok.body.token}`);
    expect(meAfterLogout.status).toBe(401);
  });

  it("denies disabled admin accounts", async () => {
    const token = signJwt({ uid: "u-super", email: "super@test.local", role: "superAdmin", superAdmin: true, tv: 1 });
    admins.get("u-super")!.disabled = true;

    const login = await request(app).post("/admin/auth/login").send({ email: "super@test.local", password: "Secret123!" });
    expect(login.status).toBe(403);

    const me = await request(app).get("/admin/auth/me").set("Authorization", `Bearer ${token}`);
    expect(me.status).toBe(401);
  });
});
