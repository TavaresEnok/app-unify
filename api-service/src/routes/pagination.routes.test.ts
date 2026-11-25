import express from "express";
import request from "supertest";
import { beforeEach, expect, it, vi } from "vitest";

const state = vi.hoisted(() => ({ tickets: [] as any[], users: [] as any[], limits: [] as number[] }));

vi.mock("../services/self-auth", async (importOriginal) => {
  const actual = await importOriginal<typeof import("../services/self-auth")>();
  return {
    ...actual,
    verifyLiveSession: async (_pool: unknown, token: string) => {
      if (token === "root") return { uid: "root", sub: "root", role: "superAdmin", superAdmin: true, auth_time: 1, iat: 1, exp: 9999999999 };
      if (token === "sub") return { uid: "sub", sub: "sub", role: "subscriber", providerId: "a", cpfCnpj: "123", superAdmin: false, auth_time: 1, iat: 1, exp: 9999999999 };
      if (token === "a" || token === "b") return { uid: token, sub: token, role: "providerAdmin", providerId: token, superAdmin: false, auth_time: 1, iat: 1, exp: 9999999999 };
      throw Object.assign(Error("invalid"), { code: "auth/invalid-id-token" });
    },
  };
});

vi.mock("../services/postgres", () => ({
  requirePgPool: () => ({
    query: async (sql: string, params: unknown[]) => {
      if (sql.includes("FROM tickets")) {
        const limit = Number(params[params.length - 1]);
        state.limits.push(limit);
        let rows = [...state.tickets];
        let idx = 0;
        if (sql.includes("provider_id = $")) {
          const pid = String(params[idx++]);
          rows = rows.filter((r) => r.provider_id === pid);
        }
        rows.sort((a, b) => (b.updated_at.getTime() - a.updated_at.getTime()) || b.id.localeCompare(a.id));
        if (sql.includes("(updated_at, id) <")) {
          const ts = new Date(params[idx++] as Date).getTime();
          const id = String(params[idx++]);
          rows = rows.filter((r) => r.updated_at.getTime() < ts || (r.updated_at.getTime() === ts && r.id.localeCompare(id) < 0));
        }
        return { rows: rows.slice(0, limit) };
      }
      if (sql.includes("FROM admin_users")) {
        const limit = Number(params[params.length - 1]);
        state.limits.push(limit);
        let rows = state.users.filter((u) => ["superAdmin", "providerAdmin"].includes(u.role));
        rows.sort((a, b) => a.uid.localeCompare(b.uid));
        if (sql.includes("uid > $1")) {
          const afterUid = String(params[0]);
          rows = rows.filter((u) => u.uid.localeCompare(afterUid) > 0);
        }
        return { rows: rows.slice(0, limit) };
      }
      return { rows: [] };
    },
  }),
  getPgPool: () => null,
  ensureCoreSchema: async () => undefined,
  ensureNotificationSchema: async () => undefined,
}));

import { ticketsRouter } from "./tickets.routes";
import { usersRouter } from "./users.routes";
import { errorHandler } from "../middlewares/errorHandler";

const app = express();
app.use("/tickets", ticketsRouter);
app.use("/users", usersRouter);
app.use(errorHandler);
const get = (path: string, user = "root") => request(app).get(path).set("Authorization", `Bearer ${user}`);

beforeEach(() => {
  state.limits = [];
  const fixedTime = new Date(1000);
  state.tickets = Array.from({ length: 10000 }, (_, i) => ({
    id: String(i).padStart(5, "0"),
    provider_id: i % 2 ? "b" : "a",
    provider_name: "P",
    subject: `Ticket ${i}`,
    status: "Aberto",
    created_by_uid: "u",
    created_by_email: "u@test",
    cpfcnpj: "",
    last_message: "",
    created_at: fixedTime,
    updated_at: fixedTime,
  }));
  state.users = Array.from({ length: 60 }, (_, i) => ({
    uid: `u${String(i).padStart(2, "0")}`,
    role: i === 59 ? "subscriber" : "providerAdmin",
    email: `${i}@example.test`,
    provider_id: "a",
    disabled: false,
  }));
});

it("paginates 5000 tenant tickets with stable tie ordering and a bounded read", async () => {
  const first = await get("/tickets/page", "a").expect(200);
  const second = await get(`/tickets/page?cursor=${first.body.nextCursor}`, "a").expect(200);
  expect(first.body.data).toHaveLength(25);
  expect(second.body.data).toHaveLength(25);
  expect(new Set([...first.body.data, ...second.body.data].map((d) => d.id)).size).toBe(50);
  expect([...first.body.data, ...second.body.data].every((d) => d.providerId === "a")).toBe(true);
  expect(state.limits).toEqual([26, 26]);
  await get(`/tickets/page?cursor=${first.body.nextCursor}`, "b").expect(400);
  await get(`/tickets/page?cursor=${first.body.nextCursor}`, "root").expect(400);
  await get("/tickets/page", "sub").expect(403);
  expect(state.limits).toHaveLength(2);
});

it("rejects malformed limits and cursors before querying", async () => {
  for (const suffix of ["limit=0", "limit=1000", "limit=-1", "limit=1.5", "limit=abc", "cursor=malformed"]) {
    await get(`/tickets/page?${suffix}`).expect(400);
  }
  expect(state.limits).toEqual([]);
});

it("pages all administrators beyond the first page, excludes subscribers and denies provider access", async () => {
  let cursor = null;
  const ids: string[] = [];
  do {
    const response = await get("/users/page?limit=25" + (cursor ? `&cursor=${cursor}` : "")).expect(200);
    ids.push(...response.body.data.map((u: any) => u.uid));
    cursor = response.body.nextCursor;
  } while (cursor);
  expect(ids).toHaveLength(59);
  expect(new Set(ids).size).toBe(59);
  expect(state.limits).toEqual([26, 26, 26]);
  await get("/users/page", "a").expect(403);
});
