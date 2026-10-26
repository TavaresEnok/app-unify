import { FieldValue, Timestamp } from "firebase-admin/firestore";
import type { ErrorCode } from "../contracts";
import { db } from "./firebase";

const RESPONSE_TTL_DAYS = 7;

function expirationDate(): Timestamp {
  const expires = new Date();
  expires.setUTCDate(expires.getUTCDate() + RESPONSE_TTL_DAYS);
  return Timestamp.fromDate(expires);
}

export function writeSuccess(requestId: string, requesterUid: string, result: unknown): Promise<FirebaseFirestore.WriteResult> {
  return db.collection("function_responses").doc(requestId).set({
    result,
    requesterUid,
    completedAt: FieldValue.serverTimestamp(),
    expiresAt: expirationDate(),
  });
}

export function writeFailure(
  requestId: string,
  requesterUid: string,
  error: string,
  code: ErrorCode,
): Promise<FirebaseFirestore.WriteResult> {
  return db.collection("function_responses").doc(requestId).set({
    error,
    code,
    requesterUid,
    completedAt: FieldValue.serverTimestamp(),
    expiresAt: expirationDate(),
  });
}
