import { test, expect, beforeEach, vi } from "vitest";
const { add, set, serverTimestamp, fromDate } = vi.hoisted(() => {
const add = vi.fn();
const set = vi.fn();
const serverTimestamp = vi.fn(() => "SERVER_TIMESTAMP");
const fromDate = vi.fn((date: Date) => date);
return { add, set, serverTimestamp, fromDate };
});


vi.mock("./firebase", () => ({
  db: {
    collection: (name: string) => ({
      add: name === "audit_logs" ? add : undefined,
      doc: () => ({ set }),
    }),
  },
}));
vi.mock("firebase-admin/firestore", () => ({
  FieldValue: { serverTimestamp },
  Timestamp: { fromDate },
}));

import { recordAudit } from "./audit";
import { failureResponse, successResponse } from "./writeResponse";

beforeEach(() => {
  vi.clearAllMocks();
  add.mockResolvedValue(undefined);
  set.mockResolvedValue(undefined);
});

test("recordAudit recursively redacts credentials", async () => {
  await recordAudit({
    requestId: "request-1",
    type: "TEST",
    requesterUid: "user-1",
    outcome: "success",
    payload: { apiToken: "secret-value", nested: [{ password: "hidden", visible: true }] },
  });
  expect(add).toHaveBeenCalledWith(expect.objectContaining({
    payload: { apiToken: "[REDACTED]", nested: [{ password: "[REDACTED]", visible: true }] },
    createdAt: "SERVER_TIMESTAMP",
  }));
});

test("configuration audit records only metadata, never raw personalization", async () => {
  for (const type of ["UPDATE_PROVIDER_CONFIG", "UPDATE_PROVIDER_DETAILS"]) {
    await recordAudit({ requestId: "r", type, requesterUid: "admin", outcome: "success",
      payload: { config: { faq: [{ question: "synthetic-private-disguised-as-text" }] }, details: { systemUrl: "synthetic-private" } } });
  }
  for (const [entry] of add.mock.calls) {
    expect(entry.payload).toEqual({ configurationChanged: true });
    expect(JSON.stringify(entry)).not.toContain("synthetic-private");
  }
});

test("success envelope retains expiration and performs no unfenced write", () => {
  expect(successResponse("user-1", { ok: true })).toEqual(expect.objectContaining({
    result: { ok: true },
    requesterUid: "user-1",
    completedAt: "SERVER_TIMESTAMP",
    expiresAt: expect.any(Date),
  }));
  expect(set).not.toHaveBeenCalled();
});

test("failure envelope retains the public legacy fields and performs no unfenced write", () => {
  expect(failureResponse("user-1", "falhou", "internal")).toEqual(expect.objectContaining({
    error: "falhou",
    code: "internal",
    requesterUid: "user-1",
  }));
  expect(set).not.toHaveBeenCalled();
});


test("oversized responses fail before any Firestore write", async () => {
  expect(() => successResponse("user-1", { data: "x".repeat(710000) })).toThrow("Resultado muito grande");
  expect(set).not.toHaveBeenCalled();
});

test("uncertain response has no automatic expiration and requires reconciliation", () => {
  const envelope = failureResponse("user-1", "Não reenvie.", "conflict", true);
  expect(envelope.reconciliationRequired).toBe(true);
  expect(envelope.expiresAt).toBeUndefined();
  expect(set).not.toHaveBeenCalled();
});
