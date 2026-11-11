import { Timestamp } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import { db } from "./firebase";
import { claimRequest } from "./requestLease";

type Router = (id: string, data: unknown) => Promise<void>;
const BATCH = 25;
const WINDOW_MS = 7 * 24 * 60 * 60 * 1000;

// Bounded starts, not cancellation of a handler already in flight. A running
// effect must finish or expire conservatively, never be retried on a race timer.
export async function recoverRequests(route: Router, now: () => number = Date.now): Promise<void> {
  const started = now();
  const withinBudget = () => now() - started < 40_000;
  const visit = async (id: string) => {
    const source = await db.collection("function_requests").doc(id).get();
    if (source.exists) await route(id, source.data());
    else await claimRequest(id, undefined, now());
  };
  const expired = await db.collection("function_locks").where("leaseUntil", "<=", started)
    .orderBy("leaseUntil").limit(BATCH).get();
  for (const document of expired.docs) {
    if (!withinBudget()) return;
    // A failed lookup never converts a request into a duplicate/archive.
    try { await visit(document.id); } catch { logger.warn("RPC recovery deferred", { requestId: document.id }); }
  }
  // Old-format locks carry no proof that an effect did not start. Quarantine
  // them rather than upgrading them into permission to replay.
  const legacy = await db.collection("function_locks")
    .where("claimedAt", "<=", Timestamp.fromMillis(started - 10 * 60_000)).limit(BATCH).get();
  for (const document of legacy.docs) {
    if (!withinBudget()) return;
    try { await visit(document.id); } catch { logger.warn("RPC legacy recovery deferred", { requestId: document.id }); }
  }
  if (!withinBudget()) return;
  // Covers crashes before the first claim, including delayed/missing redelivery.
  // A persisted cursor prevents repeatedly starving behind completed requests.
  // Requests older than seven days without a lock require engineering inspection.
  const checkpoint = db.collection("maintenance_logs").doc("rpc-recovery-cursor");
  const cursor = (await checkpoint.get()).data();
  let query = db.collection("function_requests")
    .where("createdAt", ">=", Timestamp.fromMillis(started - WINDOW_MS))
    .where("createdAt", "<=", Timestamp.fromMillis(started))
    .orderBy("createdAt").orderBy("__name__").limit(BATCH);
  if (cursor?.createdAt && typeof cursor.id === "string" &&
      cursor.createdAt.toMillis() >= started - WINDOW_MS) {
    query = query.startAfter(cursor.createdAt, cursor.id);
  }
  const sources = await query.get();
  for (const document of sources.docs) {
    if (!withinBudget()) return;
    try { await route(document.id, document.data()); } catch {
      logger.warn("RPC unclaimed recovery deferred", { requestId: document.id });
      // Keep the checkpoint before this failed claim; next schedule retries it.
      return;
    }
    await checkpoint.set({ createdAt: document.data().createdAt, id: document.id });
  }
  if (sources.size < BATCH) await checkpoint.delete();
}

export async function cleanupCompletedRequests(now = Date.now()): Promise<void> {
  const expired = await db.collection("function_responses")
    .where("expiresAt", "<=", Timestamp.fromMillis(now)).limit(100).get();
  for (const document of expired.docs) {
    const lockRef = db.collection("function_locks").doc(document.id);
    const sourceRef = db.collection("function_requests").doc(document.id);
    await db.runTransaction(async transaction => {
      const [lock, response] = await Promise.all([transaction.get(lockRef), transaction.get(document.ref)]);
      const data = response.data();
      if (!data || data.reconciliationRequired || !data.expiresAt || data.expiresAt.toMillis() > now) return;
      if (lock.exists && lock.data()?.state !== "completed") return;
      // Preserve permanent compact tombstones against delayed deliveries after
      // response TTL. Pending/unknown sources and locks are never deleted.
      if (!lock.exists) transaction.set(lockRef, { state: "completed", reason: "legacy-response" });
      transaction.delete(sourceRef);
      transaction.delete(document.ref);
    });
  }
}
