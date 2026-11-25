import { ensureCoreSchema, getPgPool } from "./postgres";

const SENSITIVE_KEYS = new Set(["password", "senha", "token", "apitoken", "authorization", "secret", "privatekey", "credential", "integrations", "secrets", "sgpbaseurl", "systemurl", "appname", "secretref", "secretversion"]);

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
    const pool = getPgPool();
    if (!pool) return;
    await ensureCoreSchema(pool);
    const payload = /PROVIDER/.test(entry.type)
      ? { configurationChanged: true }
      : redact(entry.payload ?? {});
    await pool.query(
      `INSERT INTO audit_logs (type, requester_uid, provider_id, correlation_id, payload, source, outcome, created_at)
       VALUES ($1, $2, $3, $4, $5::jsonb, 'api-service', 'success', NOW())`,
      [
        entry.type,
        entry.requesterUid,
        entry.providerId || null,
        entry.correlationId || null,
        JSON.stringify(payload ?? {}),
      ],
    );
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
