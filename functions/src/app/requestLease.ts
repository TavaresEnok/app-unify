import { randomUUID } from "node:crypto";
import { isDeepStrictEqual } from "node:util";
import { isRecord, type FunctionRequest } from "../contracts";
import { db } from "./firebase";
import { normalizeRequest } from "./request";
import { replayPolicy, type ReplayPolicy } from "./requestPolicy";
import { failureResponse } from "./writeResponse";

// Deployment gate, set only after the session-binding Rules have been verified
// active. Never infer this boundary from client data or the source updateTime.
function hasSessionProvenance(source: FirebaseFirestore.DocumentSnapshot, now: number): boolean {
  const configured = process.env.RPC_SESSION_RULES_ACTIVE_AFTER;
  const cutoff = configured && /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/.test(configured)
    ? Date.parse(configured) : NaN;
  const created = source.createTime?.toMillis();
  return Number.isFinite(cutoff) && new Date(cutoff).toISOString() === configured && cutoff > 0 && cutoff <= now &&
    typeof created === "number" && Number.isFinite(created) && created > cutoff && created <= now;
}

export const LEASE_MS = 120_000;
export const UNKNOWN_MESSAGE = "Resultado desconhecido. Não reenvie esta operação. Contate o suporte SaaS com o identificador da requisição para reconciliação.";
export class LeaseLost extends Error {
  constructor() { super("RPC ownership lost; reconciliation may be required"); }
}
export interface Lease {
  requestId: string; owner: string; fence: number; sourceVersion: string;
  request: FunctionRequest; policy: ReplayPolicy;
}
function refs(id: string) {
  return { source: db.collection("function_requests").doc(id),
    lock: db.collection("function_locks").doc(id), response: db.collection("function_responses").doc(id) };
}
function version(snapshot: FirebaseFirestore.DocumentSnapshot): string {
  const time = snapshot.updateTime;
  if (!time) throw new Error("Missing immutable RPC source version");
  return `${time.seconds}:${time.nanoseconds}`;
}
function unknown(transaction: FirebaseFirestore.Transaction, id: string, lock: FirebaseFirestore.DocumentData) {
  const ref = refs(id);
  const { leaseUntil: _expiry, claimedAt: _legacy, ...evidence } = lock;
  transaction.set(ref.lock, { ...evidence, state: "unknown" });
  if (typeof lock.requesterUid === "string") {
    transaction.set(ref.response, failureResponse(lock.requesterUid, UNKNOWN_MESSAGE, "conflict", true));
  }
}

// Effects never run inside retryable transaction callbacks. No payload/hash,
// secret, handler result or raw error is stored in the lock.
export async function claimRequest(id: string, delivery: unknown, now = Date.now()): Promise<Lease | null> {
  const owner = randomUUID();
  const ref = refs(id);
  return db.runTransaction(async transaction => {
    const [source, response, previous] = await Promise.all([
      transaction.get(ref.source), transaction.get(ref.response), transaction.get(ref.lock),
    ]);
    const lock = previous.data();
    if (response.exists) {
      if (lock?.state !== "unknown" && lock?.state !== "completed") {
        transaction.set(ref.lock, { state: "completed", reason: "existing-response" });
      }
      return null;
    }
    if (lock?.state === "completed" || lock?.state === "unknown") return null;
    if (lock && Number(lock.leaseUntil) > now) return null;
    if (!source.exists) {
      if (lock) unknown(transaction, id, lock);
      return null;
    }
    if (!hasSessionProvenance(source, now)) {
      // A pre-cutover document may contain entirely forged session fields.
      // Preserve any previous execution uncertainty; never replay it on recovery.
      if (lock) unknown(transaction, id, lock);
      else {
        const raw = source.data();
        transaction.set(ref.lock, { state: "completed", reason: "unproven-session-origin" });
        if (isRecord(raw) && typeof raw.requesterUid === "string") {
          transaction.set(ref.response, failureResponse(raw.requesterUid,
            "Origem da sessão não comprovada. Atualize o cliente e autentique novamente.", "unauthenticated"));
        }
      }
      return null;
    }
    let request: FunctionRequest;
    try { request = normalizeRequest(source.data()); } catch {
      const raw = source.data();
      const uid = isRecord(raw) && typeof raw.requesterUid === "string" ? raw.requesterUid : undefined;
      if (lock) unknown(transaction, id, lock);
      else {
        transaction.set(ref.lock, { state: "completed", reason: "invalid-request" });
        if (uid) transaction.set(ref.response, failureResponse(uid, "Requisição inválida.", "invalid-argument"));
      }
      return null;
    }
    if (!isDeepStrictEqual(normalizeRequest(delivery), request)) throw new Error("RPC source mismatch");
    const sourceVersion = version(source);
    const policy = replayPolicy(request);
    if (lock && (lock.sourceVersion !== sourceVersion || lock.type !== request.type ||
        lock.requesterUid !== request.requesterUid || !["claimed", "running"].includes(lock.state) ||
        (lock.state === "running" && (lock.policy !== "read" || policy !== "read")))) {
      unknown(transaction, id, { ...lock, requesterUid: lock.requesterUid ?? request.requesterUid });
      return null;
    }
    const fence = Number(lock?.fence || 0) + 1;
    transaction.set(ref.lock, { state: "claimed", owner, fence, sourceVersion,
      type: request.type, requesterUid: request.requesterUid, policy, leaseUntil: now + LEASE_MS });
    return { requestId: id, owner, fence, sourceVersion, request, policy };
  });
}

async function owned(lease: Lease, now: number, action: (
  transaction: FirebaseFirestore.Transaction, ref: ReturnType<typeof refs>, lock: FirebaseFirestore.DocumentData,
) => void): Promise<void> {
  const ref = refs(lease.requestId);
  await db.runTransaction(async transaction => {
    const [snapshot, response, source] = await Promise.all([
      transaction.get(ref.lock), transaction.get(ref.response), transaction.get(ref.source),
    ]);
    const lock = snapshot.data();
    if (!lock || response.exists || !source.exists || version(source) !== lease.sourceVersion ||
        lock.owner !== lease.owner || lock.fence !== lease.fence || lock.leaseUntil <= now ||
        !["claimed", "running"].includes(lock.state)) throw new LeaseLost();
    action(transaction, ref, lock);
  });
}
export function startRequest(lease: Lease, now = Date.now()): Promise<void> {
  return owned(lease, now, (transaction, ref, lock) => {
    if (lock.state !== "claimed") throw new LeaseLost();
    transaction.set(ref.lock, { ...lock, state: "running", leaseUntil: now + LEASE_MS });
  });
}
export function renewRequest(lease: Lease, now = Date.now()): Promise<void> {
  return owned(lease, now, (transaction, ref, lock) => {
    transaction.set(ref.lock, { ...lock, leaseUntil: now + LEASE_MS });
  });
}
export function finishRequest(lease: Lease, response: Record<string, unknown>, uncertain = false, now = Date.now()): Promise<void> {
  return owned(lease, now, (transaction, ref, lock) => {
    const { leaseUntil: _expiry, ...evidence } = lock;
    transaction.set(ref.lock, { ...evidence, state: uncertain ? "unknown" : "completed" });
    transaction.set(ref.response, response);
  });
}

// One in-flight renewal, always drained on exit. A failed renewal loses local
// ownership. The durable running marker prevents unsafe replay after expiry.
export function heartbeat(lease: Lease, now: () => number = Date.now, interval = 30_000) {
  let stopped = false;
  let lost = false;
  let pending: Promise<void> = Promise.resolve();
  let timer: ReturnType<typeof setTimeout>;
  const schedule = () => {
    timer = setTimeout(() => {
      pending = renewRequest(lease, now()).catch(() => { lost = true; }).then(() => {
        if (!stopped && !lost) schedule();
      });
    }, interval);
  };
  schedule();
  return { async stop() {
    stopped = true;
    clearTimeout(timer);
    await pending;
    if (lost) throw new LeaseLost();
  } };
}
