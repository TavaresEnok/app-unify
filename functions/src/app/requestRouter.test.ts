import { test, expect, beforeEach, vi, type Mock } from "vitest";
const { responseGet, writeFailure, writeSuccess, recordAudit, info, warn, error } = vi.hoisted(() => {
const responseGet = vi.fn();
const writeFailure = vi.fn();
const writeSuccess = vi.fn();
const recordAudit = vi.fn();
const info = vi.fn();
const warn = vi.fn();
const error = vi.fn();
return { responseGet, writeFailure, writeSuccess, recordAudit, info, warn, error };
});


vi.mock("./firebase", () => ({
  db: { collection: () => ({ doc: () => ({ get: responseGet, create: () => Promise.resolve() }) }) },
}));
vi.mock("./writeResponse", () => ({ writeFailure, writeSuccess }));
vi.mock("./audit", () => ({ recordAudit }));
vi.mock("firebase-functions/logger", () => ({ info, warn, error }));

import { AppError } from "./errors";
import { createRequestRouter, type HandlerRegistry } from "./requestRouter";

function registry(handler: Mock): HandlerRegistry {
  return new Proxy({}, { get: () => handler }) as HandlerRegistry;
}

const validRequest = {
  type: "GET_DASHBOARD_DATA" as const,
  requesterUid: "user-1",
  payload: {},
};

beforeEach(() => {
  vi.clearAllMocks();
  responseGet.mockResolvedValue({ exists: false });
  writeFailure.mockResolvedValue(undefined);
  writeSuccess.mockResolvedValue(undefined);
  recordAudit.mockResolvedValue(undefined);
});

test("ignores an idempotently completed request", async () => {
  responseGet.mockResolvedValueOnce({ exists: true });
  const handler = vi.fn();
  await createRequestRouter(registry(handler))("request-1", validRequest);
  expect(handler).not.toHaveBeenCalled();
  expect(info).toHaveBeenCalledWith("Function request already completed", { requestId: "request-1" });
});

test("ignores invalid anonymous requests and records attributable failures", async () => {
  const route = createRequestRouter(registry(vi.fn()));
  await route("request-1", { type: "UNKNOWN", payload: {} });
  expect(writeFailure).not.toHaveBeenCalled();

  await route("request-2", { type: "UNKNOWN", requesterUid: "user-1", payload: {} });
  expect(writeFailure).toHaveBeenCalledWith("request-2", "user-1", "Requisição inválida.", "invalid-argument");
  expect(warn).toHaveBeenCalledTimes(2);
});

test("supports the legacy requester uid inside payload", async () => {
  const handler = vi.fn().mockResolvedValue({ total: 1 });
  await createRequestRouter(registry(handler))("request-1", {
    type: "GET_DASHBOARD_DATA",
    payload: { requesterUid: "legacy-user" },
  });
  expect(handler).toHaveBeenCalledWith(expect.objectContaining({ requesterUid: "legacy-user" }));
  expect(writeSuccess).toHaveBeenCalledWith("request-1", "legacy-user", { total: 1 });
});

test("rejects requests whose top-level and payload requesterUid diverge", async () => {
  const handler = vi.fn();
  await createRequestRouter(registry(handler))("request-forged", {
    type: "SET_SUPER_ADMIN_BY_EMAIL",
    requesterUid: "victim-super-admin",
    payload: { requesterUid: "attacker", email: "attacker@example.com" },
  });
  expect(handler).not.toHaveBeenCalled();
  expect(writeFailure).toHaveBeenCalledWith(
    "request-forged",
    "victim-super-admin",
    "Requisição inválida.",
    "invalid-argument",
  );
});

test("writes success and a redacted audit envelope", async () => {
  const handler = vi.fn().mockResolvedValue({ ok: true });
  const request = {
    type: "GET_PROVIDER_DASHBOARD_DATA" as const,
    requesterUid: "user-1",
    payload: { providerId: "provider-1" },
  };
  await createRequestRouter(registry(handler))("request-1", request);
  expect(writeSuccess).toHaveBeenCalledWith("request-1", "user-1", { ok: true });
  expect(recordAudit).toHaveBeenCalledWith(expect.objectContaining({
    requestId: "request-1",
    providerId: "provider-1",
    outcome: "success",
  }));
});

test("normalizes handler failures and continues when audit fails", async () => {
  const handler = vi.fn().mockRejectedValue(new AppError("permission-denied", "negado"));
  recordAudit.mockRejectedValueOnce(new Error("audit unavailable"));
  await createRequestRouter(registry(handler))("request-1", validRequest);
  expect(writeFailure).toHaveBeenCalledWith("request-1", "user-1", "negado", "permission-denied");
  expect(error).toHaveBeenCalledWith("Audit write failed", expect.objectContaining({ requestId: "request-1" }));
  expect(error).toHaveBeenCalledWith("Function request failed", expect.objectContaining({ code: "permission-denied" }));
});
