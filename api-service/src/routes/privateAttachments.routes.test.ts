import express from "express";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import request from "supertest";
import { afterAll, beforeEach, expect, it, vi } from "vitest";

const state = vi.hoisted(() => ({
  tickets: new Map<string, any>(),
  diagnostics: new Map<string, any>(),
  attachments: new Map<string, any>(),
  messages: new Map<string, any>(),
  claims: new Map<string, any>(),
  failUpload: false,
  failCommit: false,
  authorityDown: false,
  revoked: false,
  reads: 0,
  writes: 0,
  afterDownload: undefined as undefined | (() => void | Promise<void>),
  uploadsDir: "",
}));

const identities: Record<string, any> = {
  a1: { uid: "a1", role: "subscriber", providerId: "A", superAdmin: false },
  a2: { uid: "a2", role: "subscriber", providerId: "A", superAdmin: false },
  b1: { uid: "b1", role: "subscriber", providerId: "B", superAdmin: false },
  pa: { uid: "pa", role: "providerAdmin", providerId: "A", superAdmin: false },
  pb: { uid: "pb", role: "providerAdmin", providerId: "B", superAdmin: false },
  saas: { uid: "saas", role: "superAdmin", superAdmin: true },
};

state.uploadsDir = await fs.mkdtemp(path.join(os.tmpdir(), "painel-att-test-"));
process.env.UPLOADS_DIR = state.uploadsDir;

vi.mock("node:fs/promises", async (importOriginal) => {
  const actual = await importOriginal<typeof import("node:fs/promises")>();
  const wrappedWriteFile = async (p: string, data: Buffer, opts: any) => {
    if (String(p).includes(path.join(state.uploadsDir, "private"))) {
      state.writes++;
      if (state.failUpload) throw Object.assign(new Error("offline"), { code: "EIO" });
    }
    return actual.writeFile(p, data, opts);
  };
  const wrappedReadFile = async (p: string) => {
    if (String(p).includes(path.join(state.uploadsDir, "private"))) {
      state.reads++;
      const buf = await actual.readFile(p);
      await state.afterDownload?.();
      return buf;
    }
    return actual.readFile(p);
  };
  return {
    ...actual,
    writeFile: wrappedWriteFile,
    readFile: wrappedReadFile,
    default: {
      ...actual,
      writeFile: wrappedWriteFile,
      readFile: wrappedReadFile,
    },
  };
});

vi.mock("../services/self-auth", () => ({
  verifyLiveSession: async (_pool: unknown, token: string) => {
    if (state.revoked) throw Object.assign(new Error("revoked"), { code: "auth/id-token-revoked" });
    if (state.authorityDown) throw new Error("authority down");
    const ident = identities[token];
    if (!ident) throw Object.assign(new Error("invalid"), { code: "auth/invalid-id-token" });
    const live = state.claims.get(ident.uid) || {};
    return { uid: ident.uid, ...live };
  },
}));

vi.mock("../services/postgres", () => ({
  requirePgPool: () => ({
    query: async (sql: string, params: unknown[]) => {
      if (sql.includes("FROM diagnostic_results")) {
        const resId = String(params[0]);
        const prov = String(params[1]);
        const row = state.diagnostics.get(`${prov}:${resId}`);
        return { rows: row ? [row] : [] };
      }
      if (sql.includes("FROM tickets")) {
        const ticketId = String(params[0]);
        const row = state.tickets.get(ticketId);
        return { rows: row ? [row] : [] };
      }
      if (sql.includes("SELECT * FROM private_attachments")) {
        const key = `${params[0]}:${params[1]}:${params[2]}`;
        const row = state.attachments.get(key);
        return { rows: row ? [row] : [] };
      }
      if (sql.includes("INSERT INTO private_attachments")) {
        const [, resource_kind, resource_id, attachment_id, provider_id, owner_uid, rel_path, checksum, size_bytes, mime] = params as any[];
        const key = `${resource_kind}:${resource_id}:${attachment_id}`;
        state.attachments.set(key, {
          id: params[0],
          resource_kind,
          resource_id,
          attachment_id,
          provider_id,
          owner_uid,
          rel_path,
          checksum,
          size_bytes,
          mime,
          state: "pending",
        });
        return { rows: [] };
      }
      if (sql.includes("UPDATE private_attachments SET state = 'committed'")) {
        if (state.failCommit) throw new Error("commit failed");
        const key = `${params[0]}:${params[1]}:${params[2]}`;
        const row = state.attachments.get(key);
        if (row) row.state = "committed";
        return { rows: [] };
      }
      if (sql.includes("UPDATE diagnostic_results SET report_attachment_id")) {
        const row = state.diagnostics.get(`${params[2]}:${params[0]}`);
        if (row) row.report_attachment_id = params[1];
        return { rows: [] };
      }
      if (sql.includes("INSERT INTO ticket_messages")) {
        const id = String(params[0]);
        if (!state.messages.has(id)) {
          state.messages.set(id, { id, ticket_id: params[1], attachment_id: params[5] });
        }
        return { rows: [] };
      }
      return { rows: [] };
    },
  }),
  getPgPool: () => null,
  ensureCoreSchema: async () => undefined,
}));

const { privateAttachmentsRouter } = await import("./privateAttachments.routes");
const { errorHandler } = await import("../middlewares/errorHandler");
const app = express();
app.use("/private", privateAttachmentsRouter);
app.use(errorHandler);

const png = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9Zl1sAAAAASUVORK5CYII=", "base64");
const pdf = Buffer.from("%PDF-1.7\nmock document\n%%EOF");
const ticket = "/private/tickets/t1/attachments/up1";
const report = "/private/providers/A/results/r1/reports/up1";
const put = (p = ticket, who = "a1", bytes = png, mime = "image/png") => request(app).put(p).auth(who, { type: "bearer" }).set("Content-Type", mime).send(bytes);
const get = (p = ticket, who = "a1") => request(app).get(p).auth(who, { type: "bearer" });

beforeEach(async () => {
  await fs.rm(path.join(state.uploadsDir, "private"), { recursive: true, force: true });
  state.tickets.clear();
  state.diagnostics.clear();
  state.attachments.clear();
  state.messages.clear();
  state.claims.clear();
  for (const identity of Object.values(identities)) {
    const { uid, ...claims } = identity;
    state.claims.set(uid, claims);
  }
  state.tickets.set("t1", { provider_id: "A", created_by_uid: "a1" });
  state.diagnostics.set("A:r1", { provider_id: "A", created_by_uid: "a1" });
  state.failUpload = state.failCommit = state.authorityDown = state.revoked = false;
  state.reads = state.writes = 0;
  state.afterDownload = undefined;
});

afterAll(async () => {
  await fs.rm(state.uploadsDir, { recursive: true, force: true }).catch(() => undefined);
});

it.each([[ticket, png, "image/png"], [report, pdf, "application/pdf"]])("isolates real HTTP resource %s by current role, owner and tenant", async (p, bytes, mime) => {
  expect((await put(p, "a1", bytes, mime)).status).toBe(200);
  for (const who of ["a1", "pa", "saas"]) {
    expect((await put(p, who, bytes, mime)).status).toBe(200);
    expect((await get(p, who)).status).toBe(200);
  }
  for (const who of ["a2", "b1", "pb"]) {
    const reads = state.reads, writes = state.writes;
    expect((await get(p, who)).status).toBe(403);
    expect((await put(p, who, bytes, mime)).status).toBe(403);
    expect((await request(app).delete(p).auth(who, { type: "bearer" })).status).toBe(404);
    expect(state.reads).toBe(reads);
    expect(state.writes).toBe(writes);
  }
  expect(JSON.stringify((await get(p)).headers)).not.toMatch(/downloadtoken|https:/i);
  state.claims.set("a1", { role: "subscriber", providerId: "B", superAdmin: false });
  expect((await get(p)).status).toBe(403);
});

it("closes revoked, absent and unavailable authority before disk I/O", async () => {
  expect((await request(app).get(ticket)).status).toBe(401);
  state.revoked = true;
  expect((await put()).status).toBe(401);
  state.revoked = false;
  state.authorityDown = true;
  expect((await put()).status).toBe(503);
  expect(state.writes).toBe(0);
});

it("keeps pending uploads unreadable, recovers exact retry and emits one stable message", async () => {
  state.failUpload = true;
  expect((await put()).status).toBe(503);
  expect((await get()).status).toBe(409);
  state.failUpload = false;
  state.failCommit = true;
  expect((await put()).status).toBe(500);
  expect((await get()).status).toBe(409);
  state.failCommit = false;
  expect((await put()).status).toBe(200);
  expect((await put()).status).toBe(200);
  expect([...state.messages.keys()]).toEqual(["att_up1"]);
  const changed = Buffer.from(png);
  changed[23] = 2;
  expect((await put(ticket, "a1", changed)).status).toBe(409);
});

it.each(["rel_path", "owner_uid", "provider_id", "checksum", "state", "size_bytes"])("fails closed on forged metadata %s", async (key) => {
  expect((await put()).status).toBe(200);
  const row = state.attachments.get("ticket:t1:up1");
  row[key] = key === "size_bytes" ? 999999999 : "forged";
  expect((await get()).status).not.toBe(200);
});

it("denies stale ownership, missing object, changed bytes and mid-read revocation", async () => {
  expect((await put()).status).toBe(200);
  state.tickets.get("t1").created_by_uid = "a2";
  expect((await get()).status).toBe(403);
  expect((await get(ticket, "a2")).status).toBe(409);
  state.tickets.get("t1").created_by_uid = "a1";

  const diskFile = path.join(state.uploadsDir, "private", "A", "tickets", "t1", "up1");
  const diskBytes = await fs.readFile(diskFile);
  diskBytes[23] = 2;
  await fs.writeFile(diskFile, diskBytes);
  expect((await get()).status).toBe(409);

  await fs.writeFile(diskFile, png);
  state.afterDownload = () => { state.revoked = true; };
  expect((await get()).status).toBe(401);

  state.revoked = false;
  state.afterDownload = undefined;
  await fs.rm(diskFile);
  expect((await get()).status).toBe(409);
});

it("rejects arbitrary destinations, invalid MIME, oversized and forged binary without disk writes", async () => {
  for (const [bytes, mime] of [[png, "text/html"], [Buffer.from("fake"), "image/png"], [Buffer.alloc(5 * 1024 * 1024 + 1), "image/png"]] as const) {
    expect((await put(ticket, "a1", bytes, mime)).status).not.toBe(200);
  }
  expect((await put(ticket + "?path=elsewhere")).status).toBe(400);
  expect((await put("/private/tickets/t1/attachments/bad.path")).status).toBe(400);
  expect((await put(report, "a1", Buffer.from("%PDF-invalid"), "application/pdf")).status).toBe(415);
  expect(state.writes).toBe(0);
});

it("does not adopt diagnostics with missing owner", async () => {
  state.diagnostics.get("A:r1").created_by_uid = "";
  expect((await put(report, "a1", pdf, "application/pdf")).status).toBe(409);
  expect(state.writes).toBe(0);
});

it("bounds concurrent file buffers and releases slots after completion", async () => {
  expect((await put()).status).toBe(200);
  let release!: () => void;
  let entered!: () => void;
  let count = 0;
  const barrier = new Promise<void>((resolve) => { release = resolve; });
  const ready = new Promise<void>((resolve) => { entered = resolve; });
  state.afterDownload = () => { if (++count === 8) entered(); return barrier; };
  const pending = Array.from({ length: 8 }, () => get().then((response) => response.status));
  await ready;
  try {
    expect((await get()).status).toBe(503);
  } finally {
    release();
  }
  expect(await Promise.all(pending)).toEqual(Array(8).fill(200));
  state.afterDownload = undefined;
  expect((await get()).status).toBe(200);
});
