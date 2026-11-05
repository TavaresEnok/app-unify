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
import { writeFailure, writeSuccess } from "./writeResponse";

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

test("writeSuccess persists a response with expiration", async () => {
  await writeSuccess("request-1", "user-1", { ok: true });
  expect(set).toHaveBeenCalledWith(expect.objectContaining({
    result: { ok: true },
    requesterUid: "user-1",
    completedAt: "SERVER_TIMESTAMP",
    expiresAt: expect.any(Date),
  }));
});

test("writeFailure persists the public error envelope", async () => {
  await writeFailure("request-1", "user-1", "falhou", "internal");
  expect(set).toHaveBeenCalledWith(expect.objectContaining({
    error: "falhou",
    code: "internal",
    requesterUid: "user-1",
  }));
});


test("oversized responses fail before any Firestore write", async () => {
  expect(() => writeSuccess("huge", "user-1", { data: "x".repeat(710000) })).toThrow("Resultado muito grande");
  expect(set).not.toHaveBeenCalled();
});
