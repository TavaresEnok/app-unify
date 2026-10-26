import { FieldValue } from "firebase-admin/firestore";
import { db } from "./firebase";

const REDACTED_KEYS = new Set(["password", "senha", "token", "apitoken", "authorization", "secret", "privatekey", "credential"]);

function isSensitiveKey(key: string): boolean {
  const normalized = key.toLowerCase().replace(/[^a-z0-9]/g, "");
  return REDACTED_KEYS.has(normalized) || normalized.endsWith("token") || normalized.endsWith("secret");
}

function redact(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(redact);
  if (!value || typeof value !== "object") return value;
  return Object.fromEntries(Object.entries(value).map(([key, next]) => [
    key,
    isSensitiveKey(key) ? "[REDACTED]" : redact(next),
  ]));
}

export async function recordAudit(entry: {
  requestId: string;
  type: string;
  requesterUid: string;
  providerId?: string;
  payload?: unknown;
  outcome: "success" | "failure";
  errorCode?: string;
}): Promise<void> {
  await db.collection("audit_logs").add({
    ...entry,
    payload: redact(entry.payload),
    createdAt: FieldValue.serverTimestamp(),
  });
}
