import { firestore, serverTimestamp } from "./firebaseAdmin";

const SENSITIVE_KEYS = new Set(["password", "senha", "token", "apitoken", "authorization", "secret", "privatekey", "credential"]);

function isSensitiveKey(key: string): boolean {
  const normalized = key.toLowerCase().replace(/[^a-z0-9]/g, "");
  return SENSITIVE_KEYS.has(normalized) || normalized.endsWith("token") || normalized.endsWith("secret");
}

function redact(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(redact);
  if (!value || typeof value !== "object") return value;
  return Object.fromEntries(Object.entries(value as Record<string, unknown>).map(([key, next]) => [
    key,
    isSensitiveKey(key) ? "[REDACTED]" : redact(next),
  ]));
}

export async function recordAdminAudit(entry: {
  type: string;
  requesterUid: string;
  providerId?: string;
  correlationId?: string;
  payload?: unknown;
}): Promise<void> {
  try {
    await firestore.collection("audit_logs").add({
      ...entry,
      payload: redact(entry.payload),
      source: "api-service",
      outcome: "success",
      createdAt: serverTimestamp(),
    });
  } catch (error) {
    console.error(JSON.stringify({
      severity: "ERROR",
      message: "Audit write failed",
      correlationId: entry.correlationId,
      type: entry.type,
      error: error instanceof Error ? error.message : String(error),
    }));
  }
}
