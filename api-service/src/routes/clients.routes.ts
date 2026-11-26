import { Router, type Request } from "express";
import { canAccessProvider, verifyAdmin, verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { ensureNotificationSchema, getPgPool } from "../services/postgres";
import { proxyToSgp } from "../services/proxySgpClient";
import { recordAdminAudit } from "../services/auditService";

export const clientsRouter = Router();
clientsRouter.use(verifyToken, verifyAdmin);

function resolveProviderId(req: Request): string {
  const requested = typeof req.body?.providerId === "string"
    ? req.body.providerId.trim()
    : typeof req.query?.providerId === "string"
      ? req.query.providerId.trim()
      : "";
  const providerId = req.user?.superAdmin === true
    ? requested || String(req.user?.providerId || "").trim()
    : String(req.user?.providerId || "").trim();

  if (!providerId || !/^[a-zA-Z0-9_-]{1,80}$/.test(providerId)) {
    throw new ApiError(400, "Provedor obrigatório.", "invalid-argument");
  }
  if (requested && requested !== providerId && !canAccessProvider(req, requested)) {
    throw new ApiError(403, "Sem permissão para acessar este provedor.", "permission-denied");
  }
  if (!canAccessProvider(req, providerId)) {
    throw new ApiError(403, "Sem permissão para acessar este provedor.", "permission-denied");
  }
  return providerId;
}

export function formatSgpAddress(raw: unknown): string {
  if (!raw) return "";
  if (typeof raw === "string") return raw.trim();
  if (typeof raw !== "object") return "";
  const addr = raw as Record<string, unknown>;
  const parts: string[] = [];
  const street = [addr.logradouro, addr.numero].map((v) => String(v || "").trim()).filter(Boolean).join(", ");
  if (street) parts.push(street);
  if (addr.complemento && String(addr.complemento).trim()) parts.push(String(addr.complemento).trim());
  const area = [addr.bairro, addr.cidade, addr.uf].map((v) => String(v || "").trim()).filter(Boolean).join(" - ");
  if (area) parts.push(area);
  return parts.join(" · ");
}

export interface NormalizedClientRow {
  id: string;
  nome: string;
  cpfcnpj: string;
  status: string;
  plano: string;
  cidade: string;
  bairro: string;
  endereco: string;
  oltName: string;
  pon: string;
  cto: string;
  login: string;
  vencimento: string;
  contratoIds: string[];
  hasAppDevice?: boolean;
  contratos: unknown[];
}

export function normalizeSgpClientRow(row: {
  client_id: string;
  nome: string;
  cpfcnpj: string;
  contratos: unknown;
  has_app_device?: boolean;
}): NormalizedClientRow {
  const contratos = Array.isArray(row.contratos) ? row.contratos : [];
  const first = (contratos[0] || {}) as Record<string, any>;
  const servicos = Array.isArray(first.servicos) ? first.servicos : [];
  const srv = (servicos.find((s: any) => s?.onu && (s.onu.olt_nome || s.onu.olt_name)) ||
    servicos.find((s: any) => s?.onu) ||
    servicos[0] ||
    {}) as Record<string, any>;
  const onu = (srv.onu && typeof srv.onu === "object" ? srv.onu : {}) as Record<string, any>;

  const planoObj = srv.plano;
  const plano = (typeof planoObj === "object" && planoObj ? planoObj.descricao : planoObj) ||
    first.servico_plano ||
    first.plano ||
    "";
  const status = first.status || first.contratoStatusDisplay || first.contratoStatus || "Ativo";
  const addrObj = first.endereco || srv.endereco || null;
  const cidade = String((typeof addrObj === "object" && addrObj ? addrObj.cidade : "") || "").trim();
  const bairro = String((typeof addrObj === "object" && addrObj ? addrObj.bairro : "") || "").trim();
  const endereco = formatSgpAddress(addrObj);
  const oltName = String(onu.olt_nome || onu.olt_name || "").trim();
  const slot = onu.slot != null && String(onu.slot) !== "" ? String(onu.slot) : "";
  const ponNum = onu.pon != null && String(onu.pon) !== "" ? String(onu.pon) : "";
  const pon = slot && ponNum ? `Slot ${slot} / PON ${ponNum}` : "";
  const cto = String(onu.splitter?.nome || onu.cto || "").trim();
  const login = String(srv.login || first.contratoCentralLogin || first.login || "").trim();
  const vencimento = first.vencimento != null ? `Dia ${first.vencimento}` : "";
  const contratoIds = contratos
    .map((c: any) => (c?.id ?? c?.contratoId))
    .filter((id: unknown) => id != null && String(id).trim() !== "")
    .map((id: unknown) => String(id));

  return {
    id: String(row.client_id),
    nome: String(row.nome || "Cliente"),
    cpfcnpj: String(row.cpfcnpj || ""),
    status: String(status),
    plano: String(plano || ""),
    cidade,
    bairro,
    endereco,
    oltName,
    pon,
    cto,
    login,
    vencimento,
    contratoIds,
    ...(typeof row.has_app_device === "boolean" ? { hasAppDevice: row.has_app_device } : {}),
    contratos,
  };
}

clientsRouter.get("/", asyncRoute(async (req, res) => {
  const providerId = resolveProviderId(req);
  const pool = getPgPool();
  if (!pool) throw new ApiError(503, "Banco de clientes indisponível.", "service-unavailable");

  const tableCheck = await pool.query<{ ok: boolean; has_devices?: boolean }>(`
    SELECT
      to_regclass('public.sgp_clients') IS NOT NULL AS ok,
      to_regclass('public.subscriber_devices') IS NOT NULL AS has_devices
  `);
  if (!tableCheck.rows[0]?.ok) {
    return res.json({ data: { clientes: [], total: 0, page: 1, limit: 25, lastSyncedAt: null, appUsersCount: 0 } });
  }
  const hasDevices = Boolean(tableCheck.rows[0]?.has_devices);

  const limit = Math.min(100, Math.max(1, Math.trunc(Number(req.query.limit) || 25)));
  const page = Math.max(1, Math.trunc(Number(req.query.page) || 1));
  const offset = (page - 1) * limit;
  const search = typeof req.query.search === "string" ? req.query.search.trim().slice(0, 100) : "";
  const digits = search.replace(/\D/g, "");
  const appFilter = typeof req.query.appFilter === "string" ? req.query.appFilter.trim() : "all";

  const clauses = ["c.provider_id = $1"];
  const params: unknown[] = [providerId];
  if (search) {
    const escapedSearch = search.replace(/[\\%_]/g, (ch: string) => `\\${ch}`);
    params.push(`%${escapedSearch}%`);
    const pLike = `$${params.length}`;
    if (digits.length >= 3) {
      params.push(`%${digits}%`);
      const pDigits = `$${params.length}`;
      params.push(digits);
      const pExact = `$${params.length}`;
      clauses.push(`(c.nome ILIKE ${pLike} ESCAPE '\\' OR c.cpfcnpj LIKE ${pDigits} OR c.client_id = ${pExact} OR c.contratos::text ILIKE ${pLike} ESCAPE '\\')`);
    } else {
      clauses.push(`(c.nome ILIKE ${pLike} ESCAPE '\\' OR c.contratos::text ILIKE ${pLike} ESCAPE '\\')`);
    }
  }
  if (hasDevices && appFilter === "with_app") {
    clauses.push(`EXISTS (SELECT 1 FROM subscriber_devices d WHERE d.provider_id = c.provider_id AND d.cpfcnpj = c.cpfcnpj AND d.fcm_token <> '')`);
  } else if (hasDevices && appFilter === "without_app") {
    clauses.push(`NOT EXISTS (SELECT 1 FROM subscriber_devices d WHERE d.provider_id = c.provider_id AND d.cpfcnpj = c.cpfcnpj AND d.fcm_token <> '')`);
  }
  const whereSql = clauses.join(" AND ");

  const hasAppSelect = hasDevices
    ? `, EXISTS(SELECT 1 FROM subscriber_devices d WHERE d.provider_id = c.provider_id AND d.cpfcnpj = c.cpfcnpj AND d.fcm_token <> '') AS has_app_device`
    : "";

  const [rowsRes, countRes, lastRes, appUsersRes] = await Promise.all([
    pool.query(
      `SELECT c.client_id, c.nome, c.cpfcnpj, c.contratos${hasAppSelect}
         FROM sgp_clients c
        WHERE ${whereSql}
        ORDER BY c.nome ASC, c.client_id ASC
        LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
      [...params, limit, offset],
    ),
    pool.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM sgp_clients c WHERE ${whereSql}`, params),
    pool.query<{ last_synced: Date | null }>(
      `SELECT MAX(updated_at) AS last_synced FROM sgp_clients WHERE provider_id = $1`,
      [providerId],
    ).catch(() => ({ rows: [{ last_synced: null }] })),
    hasDevices
      ? pool.query<{ count: string }>(
        `SELECT COUNT(DISTINCT cpfcnpj)::text AS count FROM subscriber_devices WHERE provider_id = $1 AND fcm_token <> ''`,
        [providerId],
      ).catch(() => ({ rows: [{ count: "0" }] }))
      : Promise.resolve({ rows: [{ count: "0" }] }),
  ]);

  res.json({
    data: {
      clientes: rowsRes.rows.map(normalizeSgpClientRow),
      total: Number(countRes.rows[0]?.count || 0),
      page,
      limit,
      lastSyncedAt: lastRes.rows[0]?.last_synced ? new Date(lastRes.rows[0].last_synced).toISOString() : null,
      appUsersCount: Number(appUsersRes.rows[0]?.count || 0),
    },
  });
}));

clientsRouter.post("/sync", asyncRoute(async (req, res) => {
  const providerId = resolveProviderId(req);
  const result = await proxyToSgp("/sync-clients", { providerId }, req.headers.authorization);
  res.status(result.status).json(result.data);
}));

clientsRouter.get("/sync/:jobId", asyncRoute(async (req, res) => {
  const providerId = resolveProviderId(req);
  const jobId = String(req.params.jobId || "").trim();
  if (!jobId) throw new ApiError(400, "jobId obrigatório.", "invalid-argument");
  const result = await proxyToSgp("/sync-status", { providerId, jobId }, req.headers.authorization);
  res.status(result.status).json(result.data);
}));

// "Encerrar sessões do assinante": o app desse CPF precisa entrar de novo.
clientsRouter.post("/:identifier/revoke-sessions", asyncRoute(async (req, res) => {
  const providerId = resolveProviderId(req);
  const cpf = String(req.params.identifier || "").replace(/\D/g, "");
  if (!/^\d{11}(\d{3})?$/.test(cpf)) throw new ApiError(400, "CPF/CNPJ inválido.", "invalid-argument");
  const pool = getPgPool();
  if (!pool) throw new ApiError(503, "Banco indisponível. Tente novamente.", "unavailable");
  const updated = await pool.query(
    `UPDATE subscribers SET token_version = token_version + 1, updated_at = NOW() WHERE provider_id = $1 AND cpfcnpj = $2`,
    [providerId, cpf],
  );
  await recordAdminAudit({ type: "REVOKE_SUBSCRIBER_SESSIONS", requesterUid: req.user!.uid, providerId, correlationId: req.correlationId }).catch(() => undefined);
  res.json({ success: true, revoked: (updated.rowCount || 0) > 0 });
}));

clientsRouter.get("/:identifier", asyncRoute(async (req, res) => {
  const providerId = resolveProviderId(req);
  const pool = getPgPool();
  if (!pool) throw new ApiError(503, "Banco de clientes indisponível.", "service-unavailable");
  await ensureNotificationSchema(pool);

  const raw = String(req.params.identifier || "").trim();
  const digits = raw.replace(/\D/g, "");
  if (!raw) throw new ApiError(400, "Identificador do cliente obrigatório.", "invalid-argument");

  const result = await pool.query(
    `SELECT c.client_id, c.nome, c.cpfcnpj, c.contratos,
            EXISTS(
              SELECT 1 FROM subscriber_devices d
               WHERE d.provider_id = c.provider_id AND d.cpfcnpj = c.cpfcnpj AND d.fcm_token <> ''
            ) AS has_app_device
       FROM sgp_clients c
      WHERE c.provider_id = $1 AND (c.client_id = $2 OR c.cpfcnpj = $3)
      LIMIT 1`,
    [providerId, raw, digits || raw],
  );
  if (!result.rows.length) {
    throw new ApiError(404, "Cliente não encontrado no cache local.", "not-found");
  }
  res.json({ data: normalizeSgpClientRow(result.rows[0]) });
}));

clientsRouter.delete("/:identifier", asyncRoute(async (req, res) => {
  const providerId = resolveProviderId(req);
  const pool = getPgPool();
  if (!pool) throw new ApiError(503, "Banco de clientes indisponível.", "service-unavailable");
  await ensureNotificationSchema(pool);

  const raw = String(req.params.identifier || "").trim();
  const digits = raw.replace(/\D/g, "");
  if (!raw) throw new ApiError(400, "Identificador obrigatório.", "invalid-argument");

  const found = await pool.query<{ client_id: string; cpfcnpj: string }>(
    `SELECT client_id, cpfcnpj FROM sgp_clients WHERE provider_id = $1 AND (client_id = $2 OR cpfcnpj = $3) LIMIT 1`,
    [providerId, raw, digits || raw],
  );
  const cpf = found.rows[0]?.cpfcnpj || digits;
  const clientId = found.rows[0]?.client_id || raw;

  await Promise.all([
    pool.query(`DELETE FROM sgp_clients WHERE provider_id = $1 AND (client_id = $2 OR cpfcnpj = $3)`, [providerId, clientId, cpf || raw]),
    cpf ? pool.query(`DELETE FROM subscriber_segments WHERE provider_id = $1 AND cpfcnpj = $2`, [providerId, cpf]).catch(() => undefined) : Promise.resolve(),
    cpf ? pool.query(`DELETE FROM subscriber_devices WHERE provider_id = $1 AND cpfcnpj = $2`, [providerId, cpf]).catch(() => undefined) : Promise.resolve(),
  ]);

  res.json({ success: true, message: "Registro do cliente removido do cache local e push." });
}));

