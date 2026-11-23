import { randomUUID } from "node:crypto";
import type { messaging as FirebaseMessagingNs, firestore as FirestoreNs } from "firebase-admin";
import { ensureNotificationSchema, type SqlQueryable } from "./postgres";

export interface SegmentFilters {
  oltNames?: string[];
  ponKeys?: string[]; // formato "Slot X / PON Y" ou "X/Y"
  ctos?: string[];
  cidades?: string[];
  bairros?: string[];
  popIds?: string[];
  statuses?: string[];
  planos?: string[];
  targetCpf?: string;
  search?: string;
}

export interface NormalizedSegmentFilters {
  oltNames: string[];
  ponKeys: string[];
  ctos: string[];
  cidades: string[];
  bairros: string[];
  popIds: string[];
  statuses: string[];
  planos: string[];
  targetCpf: string;
  search: string;
}

export interface SegmentOption {
  value: string;
  count: number;
  meta?: string;
}

export interface SegmentOptionsResult {
  olts: SegmentOption[];
  pons: SegmentOption[];
  ctos: SegmentOption[];
  cidades: SegmentOption[];
  bairros: SegmentOption[];
  pops: SegmentOption[];
  planos: SegmentOption[];
  statuses: SegmentOption[];
  totals: {
    totalSubscribers: number;
    subscribersWithDevice: number;
    totalDevices: number;
  };
}

export interface AudiencePreview {
  matchedSubscribers: number;
  reachableDevices: number;
  hasFilters: boolean;
  filters: NormalizedSegmentFilters;
}

export interface SendCampaignInput {
  providerId: string;
  title: string;
  body: string;
  category?: string;
  route?: string;
  filters?: SegmentFilters;
  sentBy: string;
}

export interface CampaignRecord {
  id: string;
  providerId: string;
  title: string;
  body: string;
  category: string;
  route: string;
  filters: NormalizedSegmentFilters;
  matchedSubscribers: number;
  targetedDevices: number;
  successCount: number;
  failureCount: number;
  deliveryMode: "topic" | "multicast";
  sentBy: string;
  createdAt: string;
}

export interface MessagingLike {
  send(message: FirebaseMessagingNs.Message): Promise<string>;
  sendEachForMulticast(message: FirebaseMessagingNs.MulticastMessage): Promise<{
    successCount: number;
    failureCount: number;
    responses: Array<{ success: boolean; error?: { code?: string } }>;
  }>;
}

const INVALID_TOKEN_CODES = new Set([
  "messaging/invalid-registration-token",
  "messaging/registration-token-not-registered",
]);

function cleanList(values: unknown, maxItems = 50): string[] {
  if (!Array.isArray(values)) {
    if (typeof values === "string" && values.trim() && values.trim() !== "all") {
      return [values.trim().slice(0, 120)];
    }
    return [];
  }
  const seen = new Set<string>();
  const out: string[] = [];
  for (const item of values) {
    if (typeof item !== "string") continue;
    const trimmed = item.trim();
    if (!trimmed || trimmed === "all" || seen.has(trimmed)) continue;
    seen.add(trimmed);
    out.push(trimmed.slice(0, 120));
    if (out.length >= maxItems) break;
  }
  return out;
}

export function normalizeFilters(raw?: SegmentFilters | Record<string, unknown>): NormalizedSegmentFilters {
  const src = (raw || {}) as Record<string, unknown>;
  const targetCpf = typeof src.targetCpf === "string" ? src.targetCpf.replace(/\D/g, "").slice(0, 14) : "";
  const search = typeof src.search === "string" ? src.search.trim().slice(0, 100) : "";
  return {
    oltNames: cleanList(src.oltNames ?? src.oltName),
    ponKeys: cleanList(src.ponKeys ?? src.ponKey),
    ctos: cleanList(src.ctos ?? src.cto),
    cidades: cleanList(src.cidades ?? src.cidade),
    bairros: cleanList(src.bairros ?? src.bairro),
    popIds: cleanList(src.popIds ?? src.popId),
    statuses: cleanList(src.statuses ?? src.statusFilter),
    planos: cleanList(src.planos ?? src.planFilter),
    targetCpf,
    search,
  };
}

export function hasActiveFilters(filters: NormalizedSegmentFilters): boolean {
  return (
    filters.oltNames.length > 0 ||
    filters.ponKeys.length > 0 ||
    filters.ctos.length > 0 ||
    filters.cidades.length > 0 ||
    filters.bairros.length > 0 ||
    filters.popIds.length > 0 ||
    filters.statuses.length > 0 ||
    filters.planos.length > 0 ||
    filters.targetCpf.length > 0 ||
    filters.search.length > 0
  );
}

/**
 * Normaliza uma chave PON no formato canônico "slot/pon" (ex.: "1/11"),
 * aceitando "Slot 1 / PON 11" ou "1/11".
 */
export function parsePonKey(value: string): string | null {
  const match = value.match(/(\d+)\D+(\d+)/);
  return match ? `${match[1]}/${match[2]}` : null;
}

/**
 * Monta cláusula WHERE 100% parametrizada sobre `subscriber_segments` (alias `s`).
 */
export function buildSegmentWhere(providerId: string, filters: NormalizedSegmentFilters): { whereSql: string; params: unknown[] } {
  const clauses: string[] = ["s.provider_id = $1"];
  const params: unknown[] = [providerId];

  const push = (val: unknown) => {
    params.push(val);
    return `$${params.length}`;
  };

  if (filters.oltNames.length > 0) {
    clauses.push(`s.olt_name = ANY(${push(filters.oltNames)}::text[])`);
  }
  if (filters.ponKeys.length > 0) {
    const normalizedPons = filters.ponKeys.map(parsePonKey).filter((v): v is string => Boolean(v));
    if (normalizedPons.length > 0) {
      clauses.push(`(s.slot || '/' || s.pon) = ANY(${push(normalizedPons)}::text[])`);
    }
  }
  if (filters.ctos.length > 0) {
    clauses.push(`s.cto = ANY(${push(filters.ctos)}::text[])`);
  }
  if (filters.cidades.length > 0) {
    clauses.push(`s.cidade = ANY(${push(filters.cidades)}::text[])`);
  }
  if (filters.bairros.length > 0) {
    clauses.push(`s.bairro = ANY(${push(filters.bairros)}::text[])`);
  }
  if (filters.popIds.length > 0) {
    clauses.push(`s.pop_id = ANY(${push(filters.popIds)}::text[])`);
  }
  if (filters.statuses.length > 0) {
    clauses.push(`LOWER(s.contract_status) = ANY(${push(filters.statuses.map((v) => v.toLowerCase()))}::text[])`);
  }
  if (filters.planos.length > 0) {
    clauses.push(`s.plano = ANY(${push(filters.planos)}::text[])`);
  }
  if (filters.targetCpf) {
    clauses.push(`s.cpfcnpj = ${push(filters.targetCpf)}`);
  }
  if (filters.search) {
    const pattern = `%${filters.search}%`;
    const p = push(pattern);
    clauses.push(`(s.olt_name ILIKE ${p} OR s.cto ILIKE ${p} OR s.bairro ILIKE ${p} OR s.cidade ILIKE ${p} OR s.plano ILIKE ${p} OR s.client_name ILIKE ${p})`);
  }

  return { whereSql: clauses.join(" AND "), params };
}

/**
 * Projeta os contratos já sincronizados em `sgp_clients` para a tabela indexada
 * `subscriber_segments` com uma única query SQL (0 chamadas ao SGP, 0 leituras no Firestore).
 */
export async function projectSegmentsFromSgpClients(db: SqlQueryable, providerId: string): Promise<number> {
  await ensureNotificationSchema(db);
  // Verifica se `sgp_clients` existe antes de projetar (ambientes novos podem não ter sincronizado ainda).
  const tableCheck = await db.query<{ exists: boolean }>(
    `SELECT to_regclass('public.sgp_clients') IS NOT NULL AS exists`,
  );
  if (!tableCheck.rows[0]?.exists) return 0;

  const result = await db.query(
    `
    WITH extracted AS (
      SELECT DISTINCT ON (sc.provider_id, sc.cpfcnpj, COALESCE(c->>'id', ''))
        sc.provider_id,
        regexp_replace(sc.cpfcnpj, '[^0-9]', '', 'g') AS cpfcnpj,
        COALESCE(c->>'id', '') AS contrato_id,
        COALESCE(sc.nome, '') AS client_name,
        COALESCE(c->>'status', c->>'contratoStatusDisplay', c->>'contratoStatus', '') AS contract_status,
        COALESCE(
          srv->'plano'->>'descricao',
          CASE WHEN jsonb_typeof(srv->'plano') = 'string' THEN srv->>'plano' ELSE NULL END,
          c->>'servico_plano',
          c->>'plano',
          ''
        ) AS plano,
        UPPER(TRIM(COALESCE(c->'endereco'->>'cidade', srv->'endereco'->>'cidade', ''))) AS cidade,
        UPPER(TRIM(COALESCE(c->'endereco'->>'bairro', srv->'endereco'->>'bairro', ''))) AS bairro,
        COALESCE(c->>'pop_id', '') AS pop_id,
        COALESCE(srv->'onu'->>'olt_id', '') AS olt_id,
        TRIM(COALESCE(srv->'onu'->>'olt_nome', srv->'onu'->>'olt_name', '')) AS olt_name,
        COALESCE(srv->'onu'->>'slot', '') AS slot,
        COALESCE(srv->'onu'->>'pon', '') AS pon,
        TRIM(COALESCE(srv->'onu'->'splitter'->>'nome', srv->'onu'->>'cto', '')) AS cto
      FROM sgp_clients sc
      CROSS JOIN LATERAL jsonb_array_elements(
        CASE WHEN jsonb_typeof(sc.contratos) = 'array' THEN sc.contratos ELSE '[]'::jsonb END
      ) AS c
      LEFT JOIN LATERAL jsonb_array_elements(
        CASE WHEN jsonb_typeof(c->'servicos') = 'array' THEN c->'servicos' ELSE '[]'::jsonb END
      ) AS srv ON TRUE
      WHERE sc.provider_id = $1
        AND regexp_replace(sc.cpfcnpj, '[^0-9]', '', 'g') <> ''
      ORDER BY
        sc.provider_id,
        sc.cpfcnpj,
        COALESCE(c->>'id', ''),
        (srv->'onu' IS NOT NULL AND srv->'onu'::text <> 'null') DESC,
        (COALESCE(srv->'onu'->>'olt_nome', '') <> '') DESC
    )
    INSERT INTO subscriber_segments (
      provider_id, cpfcnpj, contrato_id, client_name, contract_status,
      plano, cidade, bairro, pop_id, olt_id, olt_name, slot, pon, cto, updated_at
    )
    SELECT
      provider_id, cpfcnpj, contrato_id, client_name, contract_status,
      plano, cidade, bairro, pop_id, olt_id, olt_name, slot, pon, cto, NOW()
    FROM extracted
    ON CONFLICT (provider_id, cpfcnpj, contrato_id) DO UPDATE SET
      client_name = CASE WHEN EXCLUDED.client_name <> '' THEN EXCLUDED.client_name ELSE subscriber_segments.client_name END,
      contract_status = CASE WHEN EXCLUDED.contract_status <> '' THEN EXCLUDED.contract_status ELSE subscriber_segments.contract_status END,
      plano = CASE WHEN EXCLUDED.plano <> '' THEN EXCLUDED.plano ELSE subscriber_segments.plano END,
      cidade = CASE WHEN EXCLUDED.cidade <> '' THEN EXCLUDED.cidade ELSE subscriber_segments.cidade END,
      bairro = CASE WHEN EXCLUDED.bairro <> '' THEN EXCLUDED.bairro ELSE subscriber_segments.bairro END,
      pop_id = CASE WHEN EXCLUDED.pop_id <> '' THEN EXCLUDED.pop_id ELSE subscriber_segments.pop_id END,
      olt_id = CASE WHEN EXCLUDED.olt_id <> '' THEN EXCLUDED.olt_id ELSE subscriber_segments.olt_id END,
      olt_name = CASE WHEN EXCLUDED.olt_name <> '' THEN EXCLUDED.olt_name ELSE subscriber_segments.olt_name END,
      slot = CASE WHEN EXCLUDED.slot <> '' THEN EXCLUDED.slot ELSE subscriber_segments.slot END,
      pon = CASE WHEN EXCLUDED.pon <> '' THEN EXCLUDED.pon ELSE subscriber_segments.pon END,
      cto = CASE WHEN EXCLUDED.cto <> '' THEN EXCLUDED.cto ELSE subscriber_segments.cto END,
      updated_at = NOW()
    `,
    [providerId],
  );
  return result.rowCount ?? 0;
}

/** Garante projeção inicial automática se `subscriber_segments` estiver vazia para o provedor. */
export async function ensureProviderSegments(db: SqlQueryable, providerId: string): Promise<void> {
  await ensureNotificationSchema(db);
  const check = await db.query<{ count: string }>(
    `SELECT COUNT(*)::text AS count FROM subscriber_segments WHERE provider_id = $1`,
    [providerId],
  );
  if (Number(check.rows[0]?.count || 0) === 0) {
    await projectSegmentsFromSgpClients(db, providerId);
  }
}

export async function listSegmentOptions(
  db: SqlQueryable,
  providerId: string,
  contextFilters?: SegmentFilters,
): Promise<SegmentOptionsResult> {
  await ensureProviderSegments(db, providerId);
  const ctx = normalizeFilters(contextFilters);

  const ponWhere = ctx.oltNames.length > 0
    ? `provider_id = $1 AND slot <> '' AND pon <> '' AND olt_name = ANY($2::text[])`
    : `provider_id = $1 AND slot <> '' AND pon <> ''`;
  const ponParams = ctx.oltNames.length > 0 ? [providerId, ctx.oltNames] : [providerId];

  const ctoClauses = ["provider_id = $1", "cto <> ''"];
  const ctoParams: unknown[] = [providerId];
  if (ctx.oltNames.length > 0) {
    ctoParams.push(ctx.oltNames);
    ctoClauses.push(`olt_name = ANY($${ctoParams.length}::text[])`);
  }
  if (ctx.ponKeys.length > 0) {
    const normalizedPons = ctx.ponKeys.map(parsePonKey).filter((v): v is string => Boolean(v));
    if (normalizedPons.length > 0) {
      ctoParams.push(normalizedPons);
      ctoClauses.push(`(slot || '/' || pon) = ANY($${ctoParams.length}::text[])`);
    }
  }
  if (ctx.cidades.length > 0) {
    ctoParams.push(ctx.cidades);
    ctoClauses.push(`cidade = ANY($${ctoParams.length}::text[])`);
  }
  if (ctx.bairros.length > 0) {
    ctoParams.push(ctx.bairros);
    ctoClauses.push(`bairro = ANY($${ctoParams.length}::text[])`);
  }

  const bairroWhere = ctx.cidades.length > 0
    ? `provider_id = $1 AND bairro <> '' AND cidade = ANY($2::text[])`
    : `provider_id = $1 AND bairro <> ''`;
  const bairroParams = ctx.cidades.length > 0 ? [providerId, ctx.cidades] : [providerId];

  const [olts, pons, ctos, cidades, bairros, pops, planos, statuses, totals] = await Promise.all([
    db.query<{ value: string; count: string }>(
      `SELECT olt_name AS value, COUNT(DISTINCT cpfcnpj)::text AS count
         FROM subscriber_segments
        WHERE provider_id = $1 AND olt_name <> ''
        GROUP BY olt_name ORDER BY COUNT(DISTINCT cpfcnpj) DESC, olt_name ASC LIMIT 200`,
      [providerId],
    ),
    db.query<{ value: string; meta: string; count: string }>(
      `SELECT (slot || '/' || pon) AS value,
              ('Slot ' || slot || ' / PON ' || pon) AS meta,
              COUNT(DISTINCT cpfcnpj)::text AS count
         FROM subscriber_segments
        WHERE ${ponWhere}
        GROUP BY slot, pon ORDER BY slot::int NULLS LAST, pon::int NULLS LAST LIMIT 200`,
      ponParams,
    ).catch(() =>
      db.query<{ value: string; meta: string; count: string }>(
        `SELECT (slot || '/' || pon) AS value,
                ('Slot ' || slot || ' / PON ' || pon) AS meta,
                COUNT(DISTINCT cpfcnpj)::text AS count
           FROM subscriber_segments
          WHERE ${ponWhere}
          GROUP BY slot, pon ORDER BY slot ASC, pon ASC LIMIT 200`,
        ponParams,
      ),
    ),
    db.query<{ value: string; count: string }>(
      `SELECT cto AS value, COUNT(DISTINCT cpfcnpj)::text AS count
         FROM subscriber_segments
        WHERE ${ctoClauses.join(" AND ")}
        GROUP BY cto ORDER BY COUNT(DISTINCT cpfcnpj) DESC, cto ASC LIMIT 300`,
      ctoParams,
    ),
    db.query<{ value: string; count: string }>(
      `SELECT cidade AS value, COUNT(DISTINCT cpfcnpj)::text AS count
         FROM subscriber_segments
        WHERE provider_id = $1 AND cidade <> ''
        GROUP BY cidade ORDER BY COUNT(DISTINCT cpfcnpj) DESC, cidade ASC LIMIT 200`,
      [providerId],
    ),
    db.query<{ value: string; meta: string; count: string }>(
      `SELECT bairro AS value, MIN(cidade) AS meta, COUNT(DISTINCT cpfcnpj)::text AS count
         FROM subscriber_segments
        WHERE ${bairroWhere}
        GROUP BY bairro ORDER BY COUNT(DISTINCT cpfcnpj) DESC, bairro ASC LIMIT 300`,
      bairroParams,
    ),
    db.query<{ value: string; count: string }>(
      `SELECT pop_id AS value, COUNT(DISTINCT cpfcnpj)::text AS count
         FROM subscriber_segments
        WHERE provider_id = $1 AND pop_id <> ''
        GROUP BY pop_id ORDER BY COUNT(DISTINCT cpfcnpj) DESC, pop_id ASC LIMIT 200`,
      [providerId],
    ),
    db.query<{ value: string; count: string }>(
      `SELECT plano AS value, COUNT(DISTINCT cpfcnpj)::text AS count
         FROM subscriber_segments
        WHERE provider_id = $1 AND plano <> ''
        GROUP BY plano ORDER BY COUNT(DISTINCT cpfcnpj) DESC, plano ASC LIMIT 200`,
      [providerId],
    ),
    db.query<{ value: string; count: string }>(
      `SELECT contract_status AS value, COUNT(DISTINCT cpfcnpj)::text AS count
         FROM subscriber_segments
        WHERE provider_id = $1 AND contract_status <> ''
        GROUP BY contract_status ORDER BY COUNT(DISTINCT cpfcnpj) DESC, contract_status ASC LIMIT 50`,
      [providerId],
    ),
    db.query<{ total_subscribers: string; subscribers_with_device: string; total_devices: string }>(
      `SELECT
         (SELECT COUNT(DISTINCT cpfcnpj) FROM subscriber_segments WHERE provider_id = $1)::text AS total_subscribers,
         (SELECT COUNT(DISTINCT cpfcnpj) FROM subscriber_devices WHERE provider_id = $1)::text AS subscribers_with_device,
         (SELECT COUNT(*) FROM subscriber_devices WHERE provider_id = $1)::text AS total_devices`,
      [providerId],
    ),
  ]);

  const mapRows = (rows: Array<{ value: string; count: string; meta?: string }>): SegmentOption[] =>
    rows.map((r) => ({ value: r.value, count: Number(r.count || 0), ...(r.meta ? { meta: r.meta } : {}) }));

  const t = totals.rows[0];
  return {
    olts: mapRows(olts.rows),
    pons: mapRows(pons.rows),
    ctos: mapRows(ctos.rows),
    cidades: mapRows(cidades.rows),
    bairros: mapRows(bairros.rows),
    pops: mapRows(pops.rows),
    planos: mapRows(planos.rows),
    statuses: mapRows(statuses.rows),
    totals: {
      totalSubscribers: Number(t?.total_subscribers || 0),
      subscribersWithDevice: Number(t?.subscribers_with_device || 0),
      totalDevices: Number(t?.total_devices || 0),
    },
  };
}

export async function previewAudience(
  db: SqlQueryable,
  providerId: string,
  rawFilters?: SegmentFilters,
): Promise<AudiencePreview> {
  await ensureProviderSegments(db, providerId);
  const filters = normalizeFilters(rawFilters);
  const active = hasActiveFilters(filters);

  if (!active) {
    const res = await db.query<{ matched_subscribers: string; reachable_devices: string }>(
      `SELECT
         GREATEST(
           (SELECT COUNT(DISTINCT cpfcnpj) FROM subscriber_segments WHERE provider_id = $1),
           (SELECT COUNT(DISTINCT cpfcnpj) FROM subscriber_devices WHERE provider_id = $1)
         )::text AS matched_subscribers,
         (SELECT COUNT(DISTINCT fcm_token) FROM subscriber_devices WHERE provider_id = $1)::text AS reachable_devices`,
      [providerId],
    );
    return {
      matchedSubscribers: Number(res.rows[0]?.matched_subscribers || 0),
      reachableDevices: Number(res.rows[0]?.reachable_devices || 0),
      hasFilters: false,
      filters,
    };
  }

  const { whereSql, params } = buildSegmentWhere(providerId, filters);
  const res = await db.query<{ matched_subscribers: string; reachable_devices: string }>(
    `SELECT
       COUNT(DISTINCT s.cpfcnpj)::text AS matched_subscribers,
       COUNT(DISTINCT d.fcm_token)::text AS reachable_devices
     FROM subscriber_segments s
     LEFT JOIN subscriber_devices d
       ON d.provider_id = s.provider_id AND d.cpfcnpj = s.cpfcnpj
     WHERE ${whereSql}`,
    params,
  );

  let matchedSubscribers = Number(res.rows[0]?.matched_subscribers || 0);
  let reachableDevices = Number(res.rows[0]?.reachable_devices || 0);

  // Se o filtro for apenas por targetCpf e o cliente ainda não estiver em subscriber_segments,
  // confere diretamente em subscriber_devices.
  if (filters.targetCpf && reachableDevices === 0) {
    const direct = await db.query<{ devices: string }>(
      `SELECT COUNT(DISTINCT fcm_token)::text AS devices
         FROM subscriber_devices
        WHERE provider_id = $1 AND cpfcnpj = $2`,
      [providerId, filters.targetCpf],
    );
    reachableDevices = Number(direct.rows[0]?.devices || 0);
    if (reachableDevices > 0 && matchedSubscribers === 0) matchedSubscribers = 1;
  }

  return { matchedSubscribers, reachableDevices, hasFilters: true, filters };
}

async function resolveTargetTokens(
  db: SqlQueryable,
  providerId: string,
  filters: NormalizedSegmentFilters,
): Promise<{ matchedSubscribers: number; tokens: string[] }> {
  const { whereSql, params } = buildSegmentWhere(providerId, filters);
  const [countRes, tokenRes] = await Promise.all([
    db.query<{ matched_subscribers: string }>(
      `SELECT COUNT(DISTINCT s.cpfcnpj)::text AS matched_subscribers
         FROM subscriber_segments s
        WHERE ${whereSql}`,
      params,
    ),
    db.query<{ fcm_token: string }>(
      `SELECT DISTINCT d.fcm_token
         FROM subscriber_segments s
         INNER JOIN subscriber_devices d
           ON d.provider_id = s.provider_id AND d.cpfcnpj = s.cpfcnpj
        WHERE ${whereSql} AND d.fcm_token <> ''`,
      params,
    ),
  ]);

  let matchedSubscribers = Number(countRes.rows[0]?.matched_subscribers || 0);
  let tokens = tokenRes.rows.map((r) => r.fcm_token);

  if (filters.targetCpf && tokens.length === 0) {
    const direct = await db.query<{ fcm_token: string }>(
      `SELECT DISTINCT fcm_token FROM subscriber_devices WHERE provider_id = $1 AND cpfcnpj = $2 AND fcm_token <> ''`,
      [providerId, filters.targetCpf],
    );
    tokens = direct.rows.map((r) => r.fcm_token);
    if (tokens.length > 0 && matchedSubscribers === 0) matchedSubscribers = 1;
  }

  return { matchedSubscribers, tokens };
}

export async function sendCampaign(
  db: SqlQueryable,
  messagingClient: MessagingLike,
  input: SendCampaignInput,
): Promise<CampaignRecord> {
  await ensureProviderSegments(db, input.providerId);

  const title = input.title.trim().slice(0, 120);
  const body = input.body.trim().slice(0, 1000);
  const category = (input.category || "info").trim().slice(0, 32) || "info";
  const route = (input.route || "").trim().slice(0, 120);
  const filters = normalizeFilters(input.filters);
  const active = hasActiveFilters(filters);
  const id = randomUUID();

  const dataPayload: Record<string, string> = {
    campaignId: id,
    category,
    route,
  };

  let matchedSubscribers = 0;
  let targetedDevices = 0;
  let successCount = 0;
  let failureCount = 0;
  let deliveryMode: "topic" | "multicast" = active ? "multicast" : "topic";

  if (!active) {
    const preview = await previewAudience(db, input.providerId, filters);
    matchedSubscribers = preview.matchedSubscribers;
    targetedDevices = preview.reachableDevices;

    await messagingClient.send({
      topic: `provider_${input.providerId}`,
      notification: { title, body },
      data: dataPayload,
      android: {
        priority: "high",
        notification: { channelId: "high_importance_channel", priority: "high" },
      },
    });
    successCount = Math.max(1, targetedDevices);
  } else {
    const resolved = await resolveTargetTokens(db, input.providerId, filters);
    matchedSubscribers = resolved.matchedSubscribers;
    targetedDevices = resolved.tokens.length;

    const invalidTokens: string[] = [];
    for (let i = 0; i < resolved.tokens.length; i += 500) {
      const chunk = resolved.tokens.slice(i, i + 500);
      const response = await messagingClient.sendEachForMulticast({
        tokens: chunk,
        notification: { title, body },
        data: dataPayload,
        android: {
          priority: "high",
          notification: { channelId: "high_importance_channel", priority: "high" },
        },
      });
      successCount += response.successCount;
      failureCount += response.failureCount;
      response.responses.forEach((item, idx) => {
        if (!item.success && item.error?.code && INVALID_TOKEN_CODES.has(item.error.code)) {
          invalidTokens.push(chunk[idx]);
        }
      });
    }

    if (invalidTokens.length > 0) {
      await db.query(
        `DELETE FROM subscriber_devices WHERE provider_id = $1 AND fcm_token = ANY($2::text[])`,
        [input.providerId, invalidTokens],
      ).catch(() => undefined);
    }
  }

  const inserted = await db.query<{ created_at: Date }>(
    `INSERT INTO notification_campaigns (
       id, provider_id, title, body, category, route, filters,
       matched_subscribers, targeted_devices, success_count, failure_count,
       delivery_mode, sent_by
     ) VALUES ($1,$2,$3,$4,$5,$6,$7::jsonb,$8,$9,$10,$11,$12,$13)
     RETURNING created_at`,
    [
      id,
      input.providerId,
      title,
      body,
      category,
      route,
      JSON.stringify(filters),
      matchedSubscribers,
      targetedDevices,
      successCount,
      failureCount,
      deliveryMode,
      input.sentBy,
    ],
  );

  return {
    id,
    providerId: input.providerId,
    title,
    body,
    category,
    route,
    filters,
    matchedSubscribers,
    targetedDevices,
    successCount,
    failureCount,
    deliveryMode,
    sentBy: input.sentBy,
    createdAt: (inserted.rows[0]?.created_at ?? new Date()).toISOString(),
  };
}

export async function listCampaignHistory(
  db: SqlQueryable,
  providerId: string,
  limit = 25,
): Promise<CampaignRecord[]> {
  await ensureNotificationSchema(db);
  const safeLimit = Math.min(100, Math.max(1, Number(limit) || 25));
  const res = await db.query<{
    id: string;
    provider_id: string;
    title: string;
    body: string;
    category: string;
    route: string;
    filters: SegmentFilters;
    matched_subscribers: number;
    targeted_devices: number;
    success_count: number;
    failure_count: number;
    delivery_mode: "topic" | "multicast";
    sent_by: string;
    created_at: Date;
  }>(
    `SELECT id, provider_id, title, body, category, route, filters,
            matched_subscribers, targeted_devices, success_count, failure_count,
            delivery_mode, sent_by, created_at
       FROM notification_campaigns
      WHERE provider_id = $1
      ORDER BY created_at DESC
      LIMIT $2`,
    [providerId, safeLimit],
  );

  return res.rows.map((r) => ({
    id: r.id,
    providerId: r.provider_id,
    title: r.title,
    body: r.body,
    category: r.category,
    route: r.route,
    filters: normalizeFilters(r.filters),
    matchedSubscribers: Number(r.matched_subscribers || 0),
    targetedDevices: Number(r.targeted_devices || 0),
    successCount: Number(r.success_count || 0),
    failureCount: Number(r.failure_count || 0),
    deliveryMode: r.delivery_mode === "topic" ? "topic" : "multicast",
    sentBy: r.sent_by,
    createdAt: new Date(r.created_at).toISOString(),
  }));
}

export async function registerSubscriberDevice(
  db: SqlQueryable,
  input: {
    providerId: string;
    cpfCnpj: string;
    authUid: string;
    fcmToken: string;
    contratoId?: string;
    plano?: string;
    contractStatus?: string;
    connectionStatus?: string;
  },
): Promise<void> {
  await ensureNotificationSchema(db);
  const digits = input.cpfCnpj.replace(/\D/g, "");
  const token = input.fcmToken.trim();
  if (!digits || !token) return;

  await db.query(
    `INSERT INTO subscriber_devices (
       provider_id, cpfcnpj, auth_uid, fcm_token, contrato_id, plano, contract_status, connection_status, updated_at
     ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NOW())
     ON CONFLICT (provider_id, cpfcnpj, fcm_token) DO UPDATE SET
       auth_uid = EXCLUDED.auth_uid,
       contrato_id = CASE WHEN EXCLUDED.contrato_id <> '' THEN EXCLUDED.contrato_id ELSE subscriber_devices.contrato_id END,
       plano = CASE WHEN EXCLUDED.plano <> '' THEN EXCLUDED.plano ELSE subscriber_devices.plano END,
       contract_status = CASE WHEN EXCLUDED.contract_status <> '' THEN EXCLUDED.contract_status ELSE subscriber_devices.contract_status END,
       connection_status = CASE WHEN EXCLUDED.connection_status <> '' THEN EXCLUDED.connection_status ELSE subscriber_devices.connection_status END,
       updated_at = NOW()`,
    [
      input.providerId,
      digits,
      input.authUid || "",
      token,
      input.contratoId || "",
      input.plano || "",
      input.contractStatus || "",
      input.connectionStatus || "",
    ],
  );
}

export async function unregisterSubscriberDevice(
  db: SqlQueryable,
  providerId: string,
  cpfCnpj: string,
  fcmToken?: string,
): Promise<void> {
  await ensureNotificationSchema(db);
  const digits = cpfCnpj.replace(/\D/g, "");
  if (!digits) return;
  if (fcmToken?.trim()) {
    await db.query(
      `DELETE FROM subscriber_devices WHERE provider_id = $1 AND cpfcnpj = $2 AND fcm_token = $3`,
      [providerId, digits, fcmToken.trim()],
    );
  } else {
    await db.query(
      `DELETE FROM subscriber_devices WHERE provider_id = $1 AND cpfcnpj = $2`,
      [providerId, digits],
    );
  }
}

export interface SubscriberSegmentSnapshot {
  contract_status: string;
  plano: string;
  cidade: string;
  bairro: string;
  pop_id: string;
  olt_name: string;
  slot: string;
  pon: string;
  cto: string;
  client_name: string;
}

export function campaignMatchesSubscriber(
  filters: NormalizedSegmentFilters,
  cpfDigits: string,
  segments: SubscriberSegmentSnapshot[],
): boolean {
  if (!hasActiveFilters(filters)) return true;
  if (filters.targetCpf && filters.targetCpf !== cpfDigits) return false;
  if (filters.targetCpf && !segments.length) {
    // Se só filtrou por CPF específico, já casou
    const onlyCpf =
      !filters.oltNames.length && !filters.ponKeys.length && !filters.ctos.length &&
      !filters.cidades.length && !filters.bairros.length && !filters.popIds.length &&
      !filters.statuses.length && !filters.planos.length && !filters.search;
    return onlyCpf;
  }
  const normalizedPons = filters.ponKeys.map(parsePonKey).filter((v): v is string => Boolean(v));
  const loweredStatuses = filters.statuses.map((s) => s.toLowerCase());
  const searchLower = filters.search.toLowerCase();

  return segments.some((seg) => {
    if (filters.oltNames.length && !filters.oltNames.includes(seg.olt_name)) return false;
    if (normalizedPons.length && !normalizedPons.includes(`${seg.slot}/${seg.pon}`)) return false;
    if (filters.ctos.length && !filters.ctos.includes(seg.cto)) return false;
    if (filters.cidades.length && !filters.cidades.includes(seg.cidade)) return false;
    if (filters.bairros.length && !filters.bairros.includes(seg.bairro)) return false;
    if (filters.popIds.length && !filters.popIds.includes(seg.pop_id)) return false;
    if (loweredStatuses.length && !loweredStatuses.includes(seg.contract_status.toLowerCase())) return false;
    if (filters.planos.length && !filters.planos.includes(seg.plano)) return false;
    if (searchLower) {
      const hay = `${seg.olt_name} ${seg.cto} ${seg.bairro} ${seg.cidade} ${seg.plano} ${seg.client_name}`.toLowerCase();
      if (!hay.includes(searchLower)) return false;
    }
    return true;
  });
}

export async function listSubscriberNotifications(
  db: SqlQueryable,
  providerId: string,
  cpfCnpj: string,
  limit = 30,
): Promise<Array<{ id: string; title: string; body: string; category: string; route: string; createdAt: string }>> {
  await ensureNotificationSchema(db);
  const digits = cpfCnpj.replace(/\D/g, "");
  const [segRes, campRes] = await Promise.all([
    db.query<SubscriberSegmentSnapshot>(
      `SELECT contract_status, plano, cidade, bairro, pop_id, olt_name, slot, pon, cto, client_name
         FROM subscriber_segments
        WHERE provider_id = $1 AND cpfcnpj = $2`,
      [providerId, digits],
    ),
    db.query<{
      id: string;
      title: string;
      body: string;
      category: string;
      route: string;
      filters: SegmentFilters;
      created_at: Date;
    }>(
      `SELECT id, title, body, category, route, filters, created_at
         FROM notification_campaigns
        WHERE provider_id = $1
          AND created_at >= NOW() - INTERVAL '14 days'
        ORDER BY created_at DESC
        LIMIT 80`,
      [providerId],
    ),
  ]);

  const segments = segRes.rows;
  const matched: Array<{ id: string; title: string; body: string; category: string; route: string; createdAt: string }> = [];
  for (const row of campRes.rows) {
    const filters = normalizeFilters(row.filters);
    if (campaignMatchesSubscriber(filters, digits, segments)) {
      matched.push({
        id: row.id,
        title: row.title,
        body: row.body,
        category: row.category,
        route: row.route,
        createdAt: new Date(row.created_at).toISOString(),
      });
      if (matched.length >= limit) break;
    }
  }
  return matched;
}

/**
 * Importa sob demanda (1x quando solicitado pelo admin) tokens FCM legados que
 * ainda estejam só no Firestore `clientes` para `subscriber_devices` no Postgres.
 */
export async function importLegacyTokensFromFirestore(
  db: SqlQueryable,
  fsDb: FirestoreNs.Firestore,
  providerId: string,
): Promise<number> {
  await ensureNotificationSchema(db);
  let imported = 0;
  let query: FirebaseFirestore.Query = fsDb
    .collection("clientes")
    .where("providerId", "==", providerId)
    .orderBy("__name__");

  while (true) {
    const page = await query.limit(500).get();
    for (const doc of page.docs) {
      const data = doc.data();
      const token = typeof data.fcmToken === "string" ? data.fcmToken.trim() : "";
      const cpf = String(data.cpfCnpj || doc.id || "").replace(/\D/g, "");
      if (!token || !cpf) continue;
      await registerSubscriberDevice(db, {
        providerId,
        cpfCnpj: cpf,
        authUid: typeof data.authUid === "string" ? data.authUid : doc.id,
        fcmToken: token,
        plano: typeof data.plano === "string" ? data.plano : "",
        contractStatus: typeof data.contractStatus === "string" ? data.contractStatus : "",
        connectionStatus: typeof data.status === "string" ? data.status : "",
      });
      imported++;
    }
    if (page.size < 500) break;
    query = query.startAfter(page.docs[page.docs.length - 1]);
  }
  return imported;
}

