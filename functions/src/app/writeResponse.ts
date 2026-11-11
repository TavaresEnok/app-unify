import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { AppError } from "./errors";
import type { ErrorCode } from "../contracts";

const RESPONSE_TTL_DAYS = 7;

function expirationDate(): Timestamp {
  const expires = new Date();
  expires.setUTCDate(expires.getUTCDate() + RESPONSE_TTL_DAYS);
  return Timestamp.fromDate(expires);
}

// Envelope construction only. All response persistence goes through the lease
// transaction; no unfenced write API is exposed.
export function successResponse(requesterUid: string, result: unknown) {
  if (Buffer.byteLength(JSON.stringify(result ?? null), "utf8") > 700_000) {
    throw new AppError("invalid-argument", "Resultado muito grande. Use paginação ou exportação.");
  }
  return { result: result ?? null, requesterUid, completedAt: FieldValue.serverTimestamp(), expiresAt: expirationDate() };
}

export function failureResponse(requesterUid: string, error: string, code: ErrorCode, uncertain = false) {
  return { error, code, requesterUid, completedAt: FieldValue.serverTimestamp(),
    ...(uncertain ? { reconciliationRequired: true } : { expiresAt: expirationDate() }) };
}
