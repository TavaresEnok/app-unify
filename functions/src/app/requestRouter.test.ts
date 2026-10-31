import { test, expect, beforeEach, afterEach, vi } from "vitest";

// Optimistic transactional store: isolated staged writes, read versions checked
// at commit, atomic publication, callback reentry on contention, no writes on failure.
const mem = vi.hoisted(() => {
  const rows = new Map<string, { data: any; revision: number; created: number }>();
  let revision = 0;
  const controls = { conflicts: 0, callbacks: 0, failGet: "", failSet: "", failAdd: "",
    failCommit: null as null | ((writes: any[]) => boolean), loseAck: false, missingCreateTime: false };
  const value = (v: any): any => v && typeof v.toMillis === "function" ? v.toMillis() : v;
  const put = (path: string, data: any, created = rows.get(path)?.created ?? Date.now()) =>
    rows.set(path, { data, revision: ++revision, created });
  const snap = (path: string) => {
    if (controls.failGet === path) { controls.failGet = ""; throw new Error("synthetic unavailable"); }
    const row = rows.get(path);
    return { id: path.split("/").at(-1), ref: doc(path), exists: !!row, data: () => row?.data,
      createTime: row && !controls.missingCreateTime ? { toMillis: () => row.created } : undefined,
      updateTime: row ? { seconds: 0, nanoseconds: row.revision } : undefined };
  };
  const doc = (path: string): any => ({
    path, id: path.split("/").at(-1), get: async () => snap(path),
    set: async (data: any) => {
      if (controls.failSet === path) { controls.failSet = ""; throw new Error("synthetic write unavailable"); }
      put(path, data);
    },
    delete: async () => { rows.delete(path); revision++; },
    collection: (name: string) => query(path + "/" + name),
  });
  const query = (path: string, filters: any[] = [], orders: string[] = [], cap = Infinity, cursor?: any[]): any => ({
    doc: (id: string) => doc(path + "/" + id),
    add: async (data: any) => {
      if (controls.failAdd === path) { controls.failAdd = ""; throw new Error("synthetic private journal failure"); }
      const ref = doc(path + "/auto-" + (++revision)); await ref.set(data); return ref;
    },
    where: (field: string, op: string, expected: any) => query(path, [...filters, [field, op, expected]], orders, cap, cursor),
    orderBy: (field: string) => query(path, filters, [...orders, field], cap, cursor),
    limit: (n: number) => query(path, filters, orders, n, cursor),
    startAfter: (...after: any[]) => query(path, filters, orders, cap, after),
    count: () => ({ get: async () => ({ data: () => ({ count: 0 }) }) }),
    get: async () => {
      if (controls.failGet === path) { controls.failGet = ""; throw new Error("synthetic query unavailable"); }
      let docs = [...rows.keys()].filter(p => p.startsWith(path + "/") && p.split("/").length === path.split("/").length + 1).map(snap);
      docs = docs.filter(d => filters.every(([field, op, expected]) => {
        const actual = value(d.data()[field]), target = value(expected);
        if (actual === undefined) return false;
        return op === "<=" ? actual <= target : op === ">=" ? actual >= target :
          op === "in" ? target.includes(actual) : actual === target;
      }));
      const key = (d: any, field: string) => field === "__name__" ? d.id : value(d.data()[field]);
      docs.sort((a, b) => {
        for (const field of orders) {
          if (key(a, field) !== key(b, field)) return key(a, field) < key(b, field) ? -1 : 1;
        }
        return 0;
      });
      if (cursor) docs = docs.filter(d => {
        for (let i = 0; i < orders.length; i++) {
          const actual = key(d, orders[i]), bound = value(cursor[i]);
          if (actual !== bound) return actual > bound;
        }
        return false;
      });
      docs = docs.slice(0, cap);
      return { docs, size: docs.length, empty: docs.length === 0 };
    },
  });
  const db = {
    collection: (path: string) => query(path),
    runTransaction: async (callback: any) => {
      for (let attempt = 0; attempt < 30; attempt++) {
        controls.callbacks++;
        const reads = new Map<string, number>();
        const writes: any[] = [];
        let wrote = false;
        const result = await callback({
          get: async (ref: any) => {
            if (wrote) throw new Error("Firestore forbids reads after writes");
            const snapshot = snap(ref.path);
            reads.set(ref.path, rows.get(ref.path)?.revision ?? 0);
            return snapshot;
          },
          set: (ref: any, data: any) => { wrote = true; writes.push({ path: ref.path, data }); },
          delete: (ref: any) => { wrote = true; writes.push({ path: ref.path, remove: true }); },
        });
        if (controls.conflicts > 0) { controls.conflicts--; continue; }
        if ([...reads].some(([path, version]) => (rows.get(path)?.revision ?? 0) !== version)) continue;
        if (controls.failCommit?.(writes)) { controls.failCommit = null; throw new Error("synthetic commit unavailable"); }
        for (const write of writes) {
          if (write.remove) { rows.delete(write.path); revision++; } else put(write.path, write.data);
        }
        if (controls.loseAck && writes.some(w => w.path.startsWith("function_responses/"))) {
          controls.loseAck = false;
          throw new Error("synthetic response acknowledgement lost");
        }
        return result;
      }
      throw new Error("synthetic transaction retry exhausted");
    },
  };
  return { db, put, rows, controls, get: (path: string) => rows.get(path)?.data,
    getUser: vi.fn(), send: vi.fn(), audit: vi.fn(), logs: vi.fn(), schedules: [] as any[], triggers: [] as any[] };
});
vi.mock("./firebase", () => ({ db: mem.db, auth: { getUser: mem.getUser }, messaging: { send: mem.send } }));
vi.mock("./audit", () => ({ recordAudit: mem.audit }));
vi.mock("firebase-functions/logger", () => ({ info: mem.logs, warn: mem.logs, error: mem.logs }));
vi.mock("./config", () => ({ proxySecretParam: {}, proxyUrlSecret: {} }));
vi.mock("../callables/uploadProviderLogo", () => ({ uploadProviderLogo: {} }));
vi.mock("../callables/generateApk", () => ({ generateApk: {} }));
vi.mock("firebase-functions/v2/scheduler", () => ({
  onSchedule: (options: any, handler: any) => { mem.schedules.push(options); return handler; },
}));
vi.mock("firebase-functions/v2/firestore", () => ({
  onDocumentCreated: (options: any, handler: any) => { mem.triggers.push(options); return handler; },
}));

import { Timestamp } from "firebase-admin/firestore";
import { createRequestRouter, RetryableRpcError, type HandlerRegistry } from "./requestRouter";
import { claimRequest, startRequest, finishRequest, renewRequest, heartbeat, LEASE_MS, LeaseLost, UNKNOWN_MESSAGE } from "./requestLease";
import { REQUEST_POLICIES, replayPolicy } from "./requestPolicy";
import { FUNCTION_REQUEST_TYPES, type FunctionRequest } from "../contracts";
import { AppError } from "./errors";
import { requireRequester } from "./permissions";
import { handlers } from "../handlers";
import { recoverFunctionRequests, cleanupFunctionDocuments, handleFunctionRequest } from "../index";

const session = { authTime: 1793448000, issuedAt: 1793448000, role: "", providerId: "", superAdmin: true };
const read = { type: "GET_DASHBOARD_DATA", requesterUid: "user-1", payload: {}, session };
const push = { type: "SEND_PUSH_NOTIFICATION", requesterUid: "user-1", session,
  payload: { providerId: "tenant-a", title: "private-title", body: "private-body", targetAll: true } };
const source = (id = "r", request: any = read) => mem.put("function_requests/" + id, { ...request, createdAt: Timestamp.now() });
const lock = (id = "r") => mem.get("function_locks/" + id);
const response = (id = "r") => mem.get("function_responses/" + id);
const registry = (handler: any) => new Proxy({}, { get: () => handler }) as HandlerRegistry;
const scheduled = async () => (recoverFunctionRequests as any)();
const cleanup = async () => (cleanupFunctionDocuments as any)();

beforeEach(() => {
  vi.useFakeTimers();
  vi.setSystemTime(new Date("2026-10-31T12:00:00Z"));
  vi.stubEnv("RPC_SESSION_RULES_ACTIVE_AFTER", "2026-10-31T11:58:00.000Z");
  mem.rows.clear();
  Object.assign(mem.controls, { conflicts: 0, callbacks: 0, failGet: "", failSet: "", failAdd: "", failCommit: null, loseAck: false, missingCreateTime: false });
  vi.clearAllMocks();
  mem.getUser.mockResolvedValue({ uid: "user-1", customClaims: { superAdmin: true } });
  mem.send.mockResolvedValue({ messageId: "synthetic" });
  mem.audit.mockResolvedValue(undefined);
});
afterEach(() => { expect(vi.getTimerCount()).toBe(0); vi.useRealTimers(); vi.unstubAllEnvs(); });

test.each(['trigger', 'scheduled', 'claimed', 'running'])("pre-Rules forged session cannot execute via %s", async mode => {
  const forged = { ...push, session: { ...session, authTime: session.authTime - 30, issuedAt: session.issuedAt - 30 } };
  source('r', forged);
  if (mode === 'claimed' || mode === 'running') {
    const lease = (await claimRequest('r', forged))!;
    if (mode === 'running') await startRequest(lease);
    vi.advanceTimersByTime(LEASE_MS + 1);
  }
  // Canonical server creation precedes the strict Rules. Updating client fields
  // or the snapshot updateTime cannot turn it into a post-cutover source.
  mem.put('function_requests/r', { ...forged, createdAt: Timestamp.now() }, Date.now() - 300_000);
  mem.getUser.mockResolvedValue({ uid: 'user-1', customClaims: { superAdmin: true },
    tokensValidAfterTime: new Date((session.authTime - 60) * 1000).toISOString() });
  if (mode === 'trigger') await createRequestRouter(handlers)('r', forged);
  else await scheduled();
  expect(mem.send).not.toHaveBeenCalled();
  expect(mem.getUser).not.toHaveBeenCalled();
  expect(lock().state).toBe(['claimed', 'running'].includes(mode) ? 'unknown' : 'completed');
  expect(response().code).toBe(['claimed', 'running'].includes(mode) ? 'conflict' : 'unauthenticated');
  await scheduled();
  expect(mem.send).not.toHaveBeenCalled();
});

test.each(['', 'invalid', '2026-11-01T00:00:00.000Z', '2026-10-31T12:00:00.000Z'])("missing/invalid/future/equal cutover %s fails closed", async cutoff => {
  source('r', push);
  vi.stubEnv('RPC_SESSION_RULES_ACTIVE_AFTER', cutoff);
  await createRequestRouter(handlers)('r', push);
  expect(mem.send).not.toHaveBeenCalled();
  expect(response().code).toBe('unauthenticated');
});

test.each(['missing', 'future'])("canonical creation timestamp %s cannot prove provenance", async mode => {
  source('r', push);
  if (mode === 'missing') mem.controls.missingCreateTime = true;
  else mem.put('function_requests/r', { ...push, createdAt: Timestamp.now() }, Date.now() + 1);
  await createRequestRouter(handlers)('r', push);
  expect(mem.send).not.toHaveBeenCalled();
  expect(response().code).toBe('unauthenticated');
});

test('real push handler authority outage on second lookup stays authorization-unavailable without replay', async () => {
  source('r', push);
  mem.getUser.mockResolvedValueOnce({ uid: 'user-1', customClaims: { superAdmin: true } })
    .mockRejectedValueOnce(Error('private authority outage'));
  await createRequestRouter(handlers)('r', push);
  expect(mem.getUser).toHaveBeenCalledTimes(2);
  expect(mem.send).not.toHaveBeenCalled();
  expect(mem.get('notifications/auto-1')).toBeUndefined();
  expect(response()).toMatchObject({ code: 'authorization-unavailable' });
  expect(response().reconciliationRequired).not.toBe(true);
  expect(lock().state).toBe('completed');
  await scheduled();
  expect(mem.getUser).toHaveBeenCalledTimes(2);
});

test('later authority outage after a possible effect remains unknown and never replays', async () => {
  source('r', push);
  mem.getUser.mockResolvedValueOnce({ uid: 'user-1', customClaims: { superAdmin: true } })
    .mockResolvedValueOnce({ uid: 'user-1', customClaims: { superAdmin: true } })
    .mockRejectedValueOnce(Error('private authority outage'));
  const handler = vi.fn(async () => {
    await requireRequester('user-1');
    await mem.send({ topic: 'synthetic' });
    await requireRequester('user-1');
  });
  await createRequestRouter(registry(handler))('r', push);
  expect(response()).toMatchObject({ code: 'conflict', reconciliationRequired: true });
  expect(lock().state).toBe('unknown');
  await scheduled();
  expect(mem.send).toHaveBeenCalledTimes(1);
});

test.each(['missing', 'future', 'revoked-queued', 'old-session-new-token', 'scope-changed', 'outage'])("session gate denies %s before effect", async mode => {
  const request = { ...push, session: mode === 'missing' ? undefined : { ...session } };
  if (mode === 'future') request.session!.issuedAt = Math.floor(Date.now() / 1000) + 600;
  if (mode === 'old-session-new-token') {
    vi.advanceTimersByTime(2000);
    request.session!.issuedAt = Math.floor(Date.now() / 1000);
    // A refreshed token issued after revocation cannot rehabilitate an older auth_time.
    expect(request.session!.issuedAt).toBeGreaterThan(session.authTime + 1);
  }
  source('r', request);
  if (mode === 'revoked-queued') {
    const lease = (await claimRequest('r', request))!;
    expect(lease).toBeDefined(); vi.advanceTimersByTime(LEASE_MS + 1);
  }
  if (['revoked-queued', 'old-session-new-token'].includes(mode)) mem.getUser.mockResolvedValue({ uid: 'user-1', tokensValidAfterTime: new Date((session.authTime + 1) * 1000).toISOString(), customClaims: { superAdmin: true } });
  if (mode === 'scope-changed') mem.getUser.mockResolvedValue({ uid: 'user-1', customClaims: { role: 'providerAdmin', providerId: 'b' } });
  if (mode === 'outage') mem.getUser.mockRejectedValue(Error('private authority failure'));
  await createRequestRouter(handlers)('r', request);
  expect(mem.send).not.toHaveBeenCalled();
  expect(response().code).toBe(mode === 'outage' ? 'authorization-unavailable' : mode === 'scope-changed' ? 'permission-denied' : 'unauthenticated');
  expect(lock().state).toBe('completed');
});

test('canonical session cannot be replaced by delivery metadata', async () => {
  source();
  await expect(createRequestRouter(handlers)('r', { ...read, session: { ...session, authTime: session.authTime + 1 } })).rejects.toBeInstanceOf(RetryableRpcError);
  expect(mem.send).not.toHaveBeenCalled(); expect(response()).toBeUndefined();
});

test("every real command is explicitly classified; unknown is denied; SGP sync is never replayable", () => {
  expect(Object.keys(REQUEST_POLICIES).sort()).toEqual([...FUNCTION_REQUEST_TYPES].sort());
  expect(Object.keys(handlers).sort()).toEqual([...FUNCTION_REQUEST_TYPES].sort());
  expect(() => replayPolicy({ type: "UNKNOWN", payload: {} } as any)).toThrow();
  for (const action of ["get", "get_single", "status", "sync"]) {
    expect(replayPolicy({ type: "SGP_API_PROXY", payload: { action } } as FunctionRequest))
      .toBe(action === "sync" ? "uncertain-effect" : "read");
  }
});

test("two concurrent real trigger deliveries and transaction conflict invoke FCM exactly once locally", async () => {
  source("r", push);
  mem.controls.conflicts = 1;
  const event = { params: { requestId: "r" }, data: { data: () => push } };
  await Promise.all([(handleFunctionRequest as any)(event), (handleFunctionRequest as any)(event)]);
  expect(mem.send).toHaveBeenCalledTimes(1);
  expect(lock().state).toBe("completed");
  expect(response().result.success).toBe(true);
  expect(mem.controls.callbacks).toBeGreaterThan(4);
  expect(mem.triggers[0].retry).toBe(true);
});

test("a transient claim error rejects, writes no response, and next delivery really executes", async () => {
  source();
  mem.controls.failGet = "function_locks/r";
  const handler = vi.fn().mockResolvedValue({ ok: true });
  const route = createRequestRouter(registry(handler));
  await expect(route("r", read)).rejects.toBeInstanceOf(RetryableRpcError);
  expect(response()).toBeUndefined();
  expect(handler).not.toHaveBeenCalled();
  await route("r", read);
  expect(handler).toHaveBeenCalledTimes(1);
});

test.each(["claimed", "running"])("failed %s persistence invokes no handler and safely recovers", async state => {
  source("r", push);
  mem.controls.failCommit = writes => writes.some(w => w.path === "function_locks/r" && w.data?.state === state);
  await expect(createRequestRouter(handlers)("r", push)).rejects.toBeInstanceOf(RetryableRpcError);
  expect(mem.send).not.toHaveBeenCalled();
  expect(response()).toBeUndefined();
  vi.advanceTimersByTime(LEASE_MS + 1);
  await scheduled();
  expect(mem.send).toHaveBeenCalledTimes(1);
  expect(lock().state).toBe("completed");
});

test("completed response or permanent tombstone prevents rerun even after TTL cleanup", async () => {
  source();
  const handler = vi.fn().mockResolvedValue({ ok: true });
  const route = createRequestRouter(registry(handler));
  await route("r", read);
  await route("r", read);
  vi.advanceTimersByTime(8 * 86400_000);
  await cleanup();
  expect(response()).toBeUndefined();
  expect(mem.get("function_requests/r")).toBeUndefined();
  await route("r", read);
  expect(handler).toHaveBeenCalledTimes(1);
  expect(lock().state).toBe("completed");
});

test("unknown/anonymous input denied; divergent legacy identity cannot reach any handler", async () => {
  const handler = vi.fn();
  const route = createRequestRouter(registry(handler));
  source("anonymous", { type: "UNKNOWN", payload: {} });
  source("invalid", { type: "UNKNOWN", requesterUid: "user-1", payload: {} });
  source("forged", { type: "SET_SUPER_ADMIN_BY_EMAIL", requesterUid: "victim-super-admin",
    payload: { requesterUid: "attacker", email: "attacker@example.invalid" } });
  for (const id of ["anonymous", "invalid", "forged"]) await route(id, mem.get("function_requests/" + id));
  expect(handler).not.toHaveBeenCalled();
  expect(response("anonymous")).toBeUndefined();
  expect(response("invalid")).toMatchObject({ code: "invalid-argument", requesterUid: "user-1" });
  expect(response("forged")).toMatchObject({ code: "invalid-argument", requesterUid: "victim-super-admin" });
});

test("legacy UID without trusted session is denied without invoking a handler", async () => {
  const request = { type: read.type, payload: { requesterUid: "legacy-user" } };
  source("r", request);
  const handler = vi.fn().mockResolvedValue({ total: 1 });
  await createRequestRouter(registry(handler))("r", request);
  expect(handler).not.toHaveBeenCalled();
  expect(response()).toMatchObject({ requesterUid: "legacy-user", code: "unauthenticated" });
});

test("persisted request binds command, requester and private payload; forged delivery cannot bind ID", async () => {
  source("r", push);
  const handler = vi.fn();
  const route = createRequestRouter(registry(handler));
  await expect(route("r", { ...push, requesterUid: "attacker" })).rejects.toBeInstanceOf(RetryableRpcError);
  await expect(route("r", { ...push, payload: { ...push.payload, providerId: "tenant-b" } })).rejects.toBeInstanceOf(RetryableRpcError);
  expect(handler).not.toHaveBeenCalled();
  expect(lock()).toBeUndefined();
  const lease = (await claimRequest("r", push))!;
  source("r", { ...push, payload: { ...push.payload, body: "changed" } });
  await expect(startRequest(lease)).rejects.toBeInstanceOf(LeaseLost);
  vi.advanceTimersByTime(LEASE_MS + 1);
  await route("r", mem.get("function_requests/r"));
  expect(lock().state).toBe("unknown");
});

test("live lease blocks delivery, expired pre-start claim resumes safely with fresh authorization", async () => {
  source("r", push);
  const first = (await claimRequest("r", push))!;
  await createRequestRouter(handlers)("r", push);
  expect(mem.send).not.toHaveBeenCalled();
  vi.advanceTimersByTime(LEASE_MS + 1);
  await createRequestRouter(handlers)("r", push);
  expect(mem.send).toHaveBeenCalledTimes(1);
  expect(lock().fence).toBe(first.fence + 1);
  await expect(startRequest(first)).rejects.toBeInstanceOf(LeaseLost);
});

test("expired running read resumes, stale owner cannot renew or overwrite new atomic response", async () => {
  source();
  const first = (await claimRequest("r", read))!;
  await startRequest(first);
  vi.advanceTimersByTime(LEASE_MS + 1);
  await createRequestRouter(registry(vi.fn().mockResolvedValue({ fresh: true })))("r", read);
  await expect(finishRequest(first, { result: "stale" })).rejects.toBeInstanceOf(LeaseLost);
  await expect(renewRequest(first)).rejects.toBeInstanceOf(LeaseLost);
  expect(response().result).toEqual({ fresh: true });
  expect(lock().state).toBe("completed");
});

test.each(["before-effect", "after-effect"])("expired running mutation %s is unknown and never invoked by recovery", async point => {
  source("r", push);
  const lease = (await claimRequest("r", push))!;
  await startRequest(lease);
  if (point === "after-effect") await handlers.SEND_PUSH_NOTIFICATION({ requestId: "r", ...push } as any);
  vi.advanceTimersByTime(LEASE_MS + 1);
  await scheduled();
  await scheduled();
  expect(mem.send).toHaveBeenCalledTimes(point === "after-effect" ? 1 : 0);
  expect(lock().state).toBe("unknown");
  expect(response()).toMatchObject({ code: "conflict", error: UNKNOWN_MESSAGE, reconciliationRequired: true });
  expect(response().expiresAt).toBeUndefined();
});

test("FCM effect followed by response commit failure propagates and recovery never repeats FCM", async () => {
  source("r", push);
  mem.controls.failCommit = writes => writes.some(w => w.path === "function_responses/r");
  await expect(createRequestRouter(handlers)("r", push)).rejects.toBeInstanceOf(RetryableRpcError);
  expect(mem.send).toHaveBeenCalledTimes(1);
  expect(lock().state).toBe("running");
  expect(response()).toBeUndefined();
  vi.advanceTimersByTime(LEASE_MS + 1);
  await scheduled();
  expect(mem.send).toHaveBeenCalledTimes(1);
  expect(lock().state).toBe("unknown");
});

test("atomic terminal commit with lost acknowledgement is recognized as completed on redelivery", async () => {
  source("r", push);
  mem.controls.loseAck = true;
  await expect(createRequestRouter(handlers)("r", push)).rejects.toBeInstanceOf(RetryableRpcError);
  await createRequestRouter(handlers)("r", push);
  expect(mem.send).toHaveBeenCalledTimes(1);
  expect(response().result.success).toBe(true);
  expect(lock().state).toBe("completed");
});

test("post-FCM journal failure is unknown, never a retry-inviting internal failure", async () => {
  source("r", push);
  mem.controls.failAdd = "notifications";
  await createRequestRouter(handlers)("r", push);
  await createRequestRouter(handlers)("r", push);
  expect(mem.send).toHaveBeenCalledTimes(1);
  expect(lock().state).toBe("unknown");
  expect(response().error).toBe(UNKNOWN_MESSAGE);
});

test("heartbeat keeps long work owned and stops all timers", async () => {
  source();
  let resolve!: (value: unknown) => void;
  const handler = vi.fn(() => new Promise(r => { resolve = r; }));
  const work = createRequestRouter(registry(handler))("r", read);
  await vi.waitFor(() => expect(handler).toHaveBeenCalled());
  await vi.advanceTimersByTimeAsync(3 * LEASE_MS);
  expect(lock().leaseUntil).toBeGreaterThan(Date.now());
  expect(await claimRequest("r", read)).toBeNull();
  resolve({ long: true });
  await work;
  expect(response().result).toEqual({ long: true });
});

test("renewal failure loses ownership; effect finishes locally but cannot publish; recovery is unknown", async () => {
  source("r", push);
  let resolve!: () => void;
  mem.send.mockImplementationOnce(() => new Promise<void>(r => { resolve = r; }));
  const work = createRequestRouter(handlers)("r", push);
  const rejected = expect(work).rejects.toBeInstanceOf(LeaseLost);
  await vi.waitFor(() => expect(mem.send).toHaveBeenCalled());
  mem.controls.failGet = "function_locks/r";
  await vi.advanceTimersByTimeAsync(30_000);
  resolve();
  await rejected;
  expect(response()).toBeUndefined();
  vi.advanceTimersByTime(LEASE_MS + 1);
  await scheduled();
  expect(mem.send).toHaveBeenCalledTimes(1);
  expect(lock().state).toBe("unknown");
});

test("old handler still alive cannot overwrite a read reclaimed by a new owner", async () => {
  source();
  let resolve!: (value: any) => void;
  const oldHandler = vi.fn(() => new Promise(r => { resolve = r; }));
  const work = createRequestRouter(registry(oldHandler))("r", read);
  const rejected = expect(work).rejects.toBeInstanceOf(LeaseLost);
  await vi.waitFor(() => expect(oldHandler).toHaveBeenCalled());
  // Simulate a suspended worker: wall time moves without its timers running.
  vi.setSystemTime(Date.now() + LEASE_MS + 1);
  await createRequestRouter(registry(vi.fn().mockResolvedValue("new")))("r", read);
  resolve("old");
  await rejected;
  expect(response().result).toBe("new");
});

test.each(["removed-role", "disabled-account", "forged-tenant"])("real handler revalidates %s on expired read recovery", async scenario => {
  const request = { type: "GET_CLIENT_DETAILS", requesterUid: "user-1", session, payload: {
    providerId: scenario === "forged-tenant" ? "tenant-b" : "tenant-a", clientId: "c" },
    role: "superAdmin", tenant: "tenant-b" };
  source("r", request);
  mem.put("provedores/tenant-a/clientes/c", { nome: "synthetic" });
  const lease = (await claimRequest("r", request))!;
  await startRequest(lease);
  vi.advanceTimersByTime(LEASE_MS + 1);
  mem.getUser.mockResolvedValue({ uid: "user-1", disabled: scenario === "disabled-account", customClaims:
    scenario === "removed-role" ? {} : { role: "providerAdmin", providerId: "tenant-a" } });
  await scheduled();
  expect(response().code).toBe(scenario === "disabled-account" ? "unauthenticated" : "permission-denied");
  expect(response().result).toBeUndefined();
});

test("real mutation with revoked role after pre-start crash never sends FCM", async () => {
  source("r", push);
  await claimRequest("r", push);
  vi.advanceTimersByTime(LEASE_MS + 1);
  mem.getUser.mockResolvedValue({ uid: "user-1", customClaims: {} });
  await scheduled();
  expect(mem.send).not.toHaveBeenCalled();
  // Session rejection happens before the handler boundary; no effect is uncertain.
  expect(response().code).toBe("permission-denied");
  expect(lock().state).toBe("completed");
});

test("real schedule recovers no-claim crash, expired read and legacy lock, and leaves live lease alone", async () => {
  source("unclaimed");
  source("expired");
  source("live");
  source("legacy", push);
  await startRequest((await claimRequest("expired", read))!);
  vi.advanceTimersByTime(LEASE_MS + 1);
  await claimRequest("live", read);
  mem.put("function_locks/legacy", { claimedAt: Timestamp.fromMillis(Date.now() - 20 * 60_000) });
  await scheduled();
  expect(response("unclaimed").result.stats).toBeDefined();
  expect(lock("expired").state).toBe("completed");
  expect(lock("live").state).toBe("claimed");
  expect(lock("legacy").state).toBe("unknown");
  expect(mem.send).not.toHaveBeenCalled();
  expect(mem.schedules.some(s => s.schedule === "every 5 minutes" && s.maxInstances === 1)).toBe(true);
});

test("recovery source lookup failure is retryable and does not archive an expired request", async () => {
  source();
  await claimRequest("r", read);
  vi.advanceTimersByTime(LEASE_MS + 1);
  mem.controls.failGet = "function_requests/r";
  // The lock pass defers; the recent-source pass may safely recover it in the same run.
  await scheduled();
  expect(lock().state).toBe("completed");
  expect(response().result.stats).toBeDefined();
});

test("scheduler bounds recent orphan batch, persists cursor and advances past completed entries", async () => {
  for (let i = 0; i < 60; i++) source("r" + String(i).padStart(2, "0"));
  await scheduled();
  expect([...mem.rows.keys()].filter(p => p.startsWith("function_responses/"))).toHaveLength(25);
  await scheduled();
  expect([...mem.rows.keys()].filter(p => p.startsWith("function_responses/"))).toHaveLength(50);
  await scheduled();
  expect([...mem.rows.keys()].filter(p => p.startsWith("function_responses/"))).toHaveLength(60);
});

test("real scheduler stops starting requests once its time budget is used", async () => {
  for (const id of ["a", "b", "c"]) source(id);
  mem.getUser.mockImplementationOnce(async () => {
    vi.setSystemTime(Date.now() + 41_000);
    return { uid: "user-1", customClaims: { superAdmin: true } };
  });
  await scheduled();
  expect(response("a").result.stats).toBeDefined();
  expect(lock("b")).toBeUndefined();
  expect(lock("c")).toBeUndefined();
  expect(mem.get("maintenance_logs/rpc-recovery-cursor").id).toBe("a");
});

test("cleanup preserves live, pending, unknown and their original evidence", async () => {
  for (const state of ["claimed", "running", "unknown"]) {
    source(state, push);
    mem.put("function_locks/" + state, { state, leaseUntil: Date.now() + LEASE_MS });
    mem.put("function_responses/" + state, { expiresAt: Timestamp.fromMillis(Date.now() - 1),
      reconciliationRequired: state === "unknown" });
  }
  await cleanup();
  for (const state of ["claimed", "running", "unknown"]) {
    expect(mem.get("function_requests/" + state)).toBeDefined();
    expect(lock(state).state).toBe(state);
    expect(response(state)).toBeDefined();
  }
});

test("read failures remain retryable; AppError denial persists; audit failure cannot change terminal result", async () => {
  source();
  const handler = vi.fn().mockRejectedValueOnce(new Error("synthetic transient"))
    .mockRejectedValueOnce(new AppError("permission-denied", "negado"));
  const route = createRequestRouter(registry(handler));
  await expect(route("r", read)).rejects.toBeInstanceOf(RetryableRpcError);
  expect(response()).toBeUndefined();
  vi.advanceTimersByTime(LEASE_MS + 1);
  mem.audit.mockRejectedValueOnce(new Error("private-audit-error"));
  await route("r", read);
  expect(response()).toMatchObject({ code: "permission-denied", error: "negado" });
  expect(lock().state).toBe("completed");
  expect(mem.logs).toHaveBeenCalledWith("RPC audit unavailable", { requestId: "r" });
});

test("private payload, credentials, result and dynamic errors never enter lock, audit or RPC logs", async () => {
  const request = { type: "CREATE_ADMIN_USER", requesterUid: "user-1", session,
    payload: { email: "private@example.invalid", password: "private-password", role: "superAdmin" } };
  source("r", request);
  await createRequestRouter(registry(vi.fn().mockResolvedValue({ privateResult: "private-result" })))("r", request);
  expect(mem.audit).toHaveBeenCalledWith(expect.objectContaining({ payload: {}, outcome: "success" }));
  const auxiliary = JSON.stringify([lock(), mem.audit.mock.calls, mem.logs.mock.calls]);
  for (const secret of ["private@example.invalid", "private-password", "private-result"]) expect(auxiliary).not.toContain(secret);
});

test("runtime rejection stays retryable without exposing private SDK/handler errors or causes", async () => {
  source();
  const failure = new Error("private-body-and-secret");
  (failure as any).cause = { payload: "private-password" };
  const route = createRequestRouter(registry(vi.fn().mockRejectedValue(failure)));
  const error = await route("r", read).catch(error => error);
  expect(error).toBeInstanceOf(RetryableRpcError);
  expect(error.message).not.toContain("private");
  expect(error.cause).toBeUndefined();
  expect(response()).toBeUndefined();
  expect(lock().state).toBe("running");
});
