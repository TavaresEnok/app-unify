import { randomUUID } from "node:crypto";
import { ensureNotificationSchema, type SqlQueryable } from "./postgres";

export interface DiagnosticResultInput {
  providerId: string;
  cpfCnpj: string;
  contratoId?: string;
  clientName?: string;
  planName?: string;
  mode?: string;
  verdict: string;
  verdictHeadline?: string;
  cause?: string;
  summary?: Record<string, unknown>;
}

export interface DiagnosticResultRow {
  id: string;
  providerId: string;
  cpfCnpj: string;
  contratoId: string;
  clientName: string;
  planName: string;
  mode: string;
  verdict: string;
  verdictHeadline: string;
  cause: string;
  summary: Record<string, unknown>;
  oltName: string;
  bairro: string;
  cidade: string;
  createdAt: string;
}

const ALLOWED_MODES = new Set(["quick", "complete", "ping", "tracert", "lan", "speed"]);
const ALLOWED_VERDICTS = new Set(["healthy", "degraded", "critical", "unknown"]);

function cleanText(value: unknown, maxLen: number): string {
  return typeof value === "string" ? value.trim().slice(0, maxLen) : "";
}

function sanitizeSummary(raw: unknown): Record<string, unknown> {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return {};
  const src = raw as Record<string, unknown>;
  const out: Record<string, unknown> = {};
  const keys = Object.keys(src).slice(0, 32);
  for (const key of keys) {
    const val = src[key];
    if (
      val === null ||
      typeof val === "boolean" ||
      typeof val === "number" ||
      typeof val === "string"
    ) {
      out[key.slice(0, 48)] = typeof val === "string" ? val.slice(0, 240) : val;
    }
  }
  return out;
}

export async function saveDiagnosticResult(
  db: SqlQueryable,
  input: DiagnosticResultInput,
): Promise<DiagnosticResultRow> {
  await ensureNotificationSchema(db);

  const id = randomUUID();
  const providerId = cleanText(input.providerId, 80);
  const cpfDigits = cleanText(input.cpfCnpj, 32).replace(/\D/g, "");
  let contratoId = cleanText(input.contratoId, 64);
  let clientName = cleanText(input.clientName, 160);
  let planName = cleanText(input.planName, 120);
  const modeRaw = cleanText(input.mode, 32).toLowerCase();
  const mode = ALLOWED_MODES.has(modeRaw) ? modeRaw : "quick";
  const verdictRaw = cleanText(input.verdict, 32).toLowerCase();
  const verdict = ALLOWED_VERDICTS.has(verdictRaw) ? verdictRaw : "unknown";
  const verdictHeadline = cleanText(input.verdictHeadline, 200);
  const cause = cleanText(input.cause, 120);
  const summary = sanitizeSummary(input.summary);

  let oltName = "";
  let bairro = "";
  let cidade = "";

  if (cpfDigits) {
    const segRes = await db.query<{
      contrato_id: string;
      client_name: string;
      plano: string;
      olt_name: string;
      bairro: string;
      cidade: string;
    }>(
      `SELECT contrato_id, client_name, plano, olt_name, bairro, cidade
         FROM subscriber_segments
        WHERE provider_id = $1 AND cpfcnpj = $2
        ORDER BY (CASE WHEN $3 <> '' AND contrato_id = $3 THEN 0 ELSE 1 END), updated_at DESC
        LIMIT 1`,
      [providerId, cpfDigits, contratoId],
    ).catch(() => ({ rows: [] }));

    const seg = segRes.rows[0];
    if (seg) {
      if (!contratoId && seg.contrato_id) contratoId = seg.contrato_id;
      if (!clientName && seg.client_name) clientName = seg.client_name;
      if (!planName && seg.plano) planName = seg.plano;
      oltName = seg.olt_name || "";
      bairro = seg.bairro || "";
      cidade = seg.cidade || "";
    }
  }

  const inserted = await db.query<{ created_at: Date }>(
    `INSERT INTO diagnostic_results (
       id, provider_id, cpfcnpj, contrato_id, client_name, plan_name,
       mode, verdict, verdict_headline, cause, summary, olt_name, bairro, cidade
     ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11::jsonb,$12,$13,$14)
     RETURNING created_at`,
    [
      id,
      providerId,
      cpfDigits,
      contratoId,
      clientName,
      planName,
      mode,
      verdict,
      verdictHeadline,
      cause,
      JSON.stringify(summary),
      oltName,
      bairro,
      cidade,
    ],
  );

  const createdAt = inserted.rows[0]?.created_at
    ? new Date(inserted.rows[0].created_at).toISOString()
    : new Date().toISOString();

  return {
    id,
    providerId,
    cpfCnpj: cpfDigits,
    contratoId,
    clientName,
    planName,
    mode,
    verdict,
    verdictHeadline,
    cause,
    summary,
    oltName,
    bairro,
    cidade,
    createdAt,
  };
}

export async function listDiagnosticResults(
  db: SqlQueryable,
  providerId: string,
  limit = 100,
): Promise<DiagnosticResultRow[]> {
  await ensureNotificationSchema(db);
  const safeLimit = Math.min(200, Math.max(1, Math.trunc(Number(limit) || 100)));
  const res = await db.query<{
    id: string;
    provider_id: string;
    cpfcnpj: string;
    contrato_id: string;
    client_name: string;
    plan_name: string;
    mode: string;
    verdict: string;
    verdict_headline: string;
    cause: string;
    summary: Record<string, unknown>;
    olt_name: string;
    bairro: string;
    cidade: string;
    created_at: Date;
  }>(
    `SELECT id, provider_id, cpfcnpj, contrato_id, client_name, plan_name,
            mode, verdict, verdict_headline, cause, summary,
            olt_name, bairro, cidade, created_at
       FROM diagnostic_results
      WHERE provider_id = $1
      ORDER BY created_at DESC
      LIMIT $2`,
    [providerId, safeLimit],
  );

  return res.rows.map((r) => ({
    id: r.id,
    providerId: r.provider_id,
    cpfCnpj: r.cpfcnpj,
    contratoId: r.contrato_id || "",
    clientName: r.client_name || "",
    planName: r.plan_name || "",
    mode: r.mode || "quick",
    verdict: r.verdict || "unknown",
    verdictHeadline: r.verdict_headline || "",
    cause: r.cause || "",
    summary: (r.summary && typeof r.summary === "object" ? r.summary : {}) as Record<string, unknown>,
    oltName: r.olt_name || "",
    bairro: r.bairro || "",
    cidade: r.cidade || "",
    createdAt: r.created_at ? new Date(r.created_at).toISOString() : new Date().toISOString(),
  }));
}

export async function deleteDiagnosticResult(
  db: SqlQueryable,
  providerId: string,
  id: string,
): Promise<boolean> {
  await ensureNotificationSchema(db);
  const res = await db.query(
    `DELETE FROM diagnostic_results WHERE provider_id = $1 AND id = $2`,
    [providerId, id],
  );
  return (res.rowCount || 0) > 0;
}

