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

export interface OutageCluster {
  scope: "olt" | "bairro";
  areaName: string;
  cidade: string;
  distinctSubscribers: number;
  criticalCount: number;
  degradedCount: number;
  totalDiagnostics: number;
  lastSeenAt: string;
}

/**
 * Detecta automaticamente surtos regionais (possíveis quedas de fibra/OLT)
 * agrupando diagnósticos críticos/degradados recentes por OLT e por Bairro.
 */
export async function detectOutageClusters(
  db: SqlQueryable,
  providerId: string,
  options: { windowMinutes?: number; minSubscribers?: number } = {},
): Promise<OutageCluster[]> {
  await ensureNotificationSchema(db);
  const windowMinutes = Math.min(240, Math.max(5, Math.trunc(Number(options.windowMinutes) || 45)));
  const minSubscribers = Math.min(50, Math.max(2, Math.trunc(Number(options.minSubscribers) || 3)));

  const res = await db.query<{
    scope: "olt" | "bairro";
    area_name: string;
    cidade: string;
    distinct_subscribers: string;
    critical_count: string;
    degraded_count: string;
    total_diagnostics: string;
    last_seen_at: Date;
  }>(
    `WITH recent AS (
       SELECT cpfcnpj, verdict, olt_name, bairro, cidade, created_at
         FROM diagnostic_results
        WHERE provider_id = $1
          AND verdict IN ('critical', 'degraded')
          AND created_at >= NOW() - ($2::int * INTERVAL '1 minute')
     ),
     by_olt AS (
       SELECT 'olt'::text AS scope,
              olt_name AS area_name,
              COALESCE(MAX(NULLIF(cidade, '')), '') AS cidade,
              COUNT(DISTINCT cpfcnpj)::text AS distinct_subscribers,
              COUNT(*) FILTER (WHERE verdict = 'critical')::text AS critical_count,
              COUNT(*) FILTER (WHERE verdict = 'degraded')::text AS degraded_count,
              COUNT(*)::text AS total_diagnostics,
              MAX(created_at) AS last_seen_at
         FROM recent
        WHERE olt_name <> ''
        GROUP BY olt_name
       HAVING COUNT(DISTINCT cpfcnpj) >= $3
     ),
     by_bairro AS (
       SELECT 'bairro'::text AS scope,
              bairro AS area_name,
              COALESCE(MAX(NULLIF(cidade, '')), '') AS cidade,
              COUNT(DISTINCT cpfcnpj)::text AS distinct_subscribers,
              COUNT(*) FILTER (WHERE verdict = 'critical')::text AS critical_count,
              COUNT(*) FILTER (WHERE verdict = 'degraded')::text AS degraded_count,
              COUNT(*)::text AS total_diagnostics,
              MAX(created_at) AS last_seen_at
         FROM recent
        WHERE bairro <> ''
        GROUP BY bairro
       HAVING COUNT(DISTINCT cpfcnpj) >= $3
     )
     SELECT * FROM by_olt
     UNION ALL
     SELECT * FROM by_bairro
     ORDER BY critical_count::int DESC, distinct_subscribers::int DESC, last_seen_at DESC
     LIMIT 12`,
    [providerId, windowMinutes, minSubscribers],
  );

  return res.rows.map((r) => ({
    scope: r.scope === "olt" ? "olt" : "bairro",
    areaName: r.area_name,
    cidade: r.cidade || "",
    distinctSubscribers: Number(r.distinct_subscribers || 0),
    criticalCount: Number(r.critical_count || 0),
    degradedCount: Number(r.degraded_count || 0),
    totalDiagnostics: Number(r.total_diagnostics || 0),
    lastSeenAt: r.last_seen_at ? new Date(r.last_seen_at).toISOString() : new Date().toISOString(),
  }));
}

