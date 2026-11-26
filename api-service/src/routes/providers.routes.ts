import express, { Router } from "express";
import { randomUUID } from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import { canAccessProvider, requireRecentLogin, verifyFreshToken, verifyToken, verifyAdmin } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { recordAdminAudit } from "../services/auditService";
import { requirePgPool } from "../services/postgres";
import {
  createProviderBackup,
  deleteProviderBackup,
  deleteProviderRow,
  getProviderBackup,
  getProviderRow,
  getProviderSecret,
  getProviderSecretMeta,
  listProviderBackups,
  listProviderRows,
  saveProviderSecret,
  serializeProviderRow,
  upsertProvider,
} from "../services/providersStore";
import sgpOutbound from "../services/sgp-outbound";
import { ixcHeaders, ixcUrl } from "../services/ixc-gateway";
import { publicConfigCache } from "../services/publicConfigCache";
import { proxyToSgp } from "../services/proxySgpClient";
import {
  parseDetails,
  parsePersonalization,
  parsePrivateIntegration,
  parseProviderInput,
  restoredPersonalization,
  sanitizePersonalization,
} from "../services/providerConfig";
import { getPgPool } from "../services/postgres";

export const providersRouter = Router();
providersRouter.use(verifyToken, verifyAdmin);
providersRouter.use((_req, res, next) => { res.setHeader("Cache-Control", "private, no-store"); next(); });

const MAX_ASSET_BYTES = 2 * 1024 * 1024;
const rawAssetBody = express.raw({ type: () => true, limit: MAX_ASSET_BYTES, inflate: false });

function detectAssetExtension(bytes: Buffer, mime: string): string | null {
  if (!Buffer.isBuffer(bytes) || !bytes.length || bytes.length > MAX_ASSET_BYTES) return null;
  if (mime === "image/png" && bytes.length >= 24 && bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) {
    return "png";
  }
  if (mime === "image/jpeg" && bytes.length >= 4 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return "jpg";
  }
  if (mime === "image/webp" && bytes.length >= 12 && bytes.subarray(0, 4).toString("ascii") === "RIFF" && bytes.subarray(8, 12).toString("ascii") === "WEBP") {
    return "webp";
  }
  return null;
}

providersRouter.get("/", asyncRoute(async (req, res) => {
  const pool = requirePgPool();
  if (req.user?.superAdmin === true) {
    const rows = await listProviderRows(pool);
    return res.json({ data: rows.map(serializeProviderRow) });
  }
  const providerId = typeof req.user?.providerId === "string" ? req.user.providerId : "";
  if (!providerId) throw new ApiError(403, "Sem permissão para listar provedores.", "permission-denied");
  const row = await getProviderRow(pool, providerId);
  return res.json({ data: row ? [serializeProviderRow(row)] : [] });
}));

providersRouter.get("/summaries", asyncRoute(async (req, res) => {
  if (req.user?.superAdmin !== true) throw new ApiError(403, "Acesso SaaS obrigatório.", "permission-denied");
  const rows = await listProviderRows(requirePgPool());
  res.json({
    data: rows.map((row) => {
      const d = row.data || {};
      const details = (d.details && typeof d.details === "object" ? d.details : {}) as Record<string, unknown>;
      return {
        id: row.id,
        name: row.name,
        active: row.active,
        plan: d.plan ?? d.plano,
        appStatus: d.appStatus ?? d.statusApp,
        details: { cnpj: details.cnpj ?? d.cnpj ?? "" },
      };
    }),
  });
}));

providersRouter.get("/:providerId", asyncRoute(async (req, res) => {
  const id = req.params.providerId;
  if (!/^[a-z0-9_-]{1,64}$/i.test(id)) throw new ApiError(400, "ID de provedor inválido.", "invalid-argument");
  if (!canAccessProvider(req, id)) throw new ApiError(403, "Sem permissão para este provedor.", "permission-denied");
  const row = await getProviderRow(requirePgPool(), id);
  if (!row) throw new ApiError(404, "Provedor não encontrado.", "not-found");
  res.json({ data: serializeProviderRow(row) });
}));

providersRouter.patch("/:providerId/config", asyncRoute(async (req, res) => {
  const id = req.params.providerId;
  if (!/^[a-z0-9_-]{1,64}$/i.test(id)) throw new ApiError(400, "ID de provedor inválido.", "invalid-argument");
  if (!canAccessProvider(req, id)) throw new ApiError(403, "Sem permissão para este provedor.", "permission-denied");
  let config: Record<string, unknown>;
  try { config = parsePersonalization(req.body); }
  catch { throw new ApiError(400, "Configuração inválida ou campo não permitido.", "invalid-argument"); }
  const pool = requirePgPool();
  if (!(await getProviderRow(pool, id))) throw new ApiError(404, "Provedor não encontrado.", "not-found");
  await upsertProvider(pool, id, config);
  publicConfigCache.delete(id);
  await recordAdminAudit({ type: "UPDATE_PROVIDER_CONFIG", requesterUid: req.user!.uid, providerId: id, correlationId: req.correlationId, payload: config });
  res.json({ success: true, providerId: id });
}));

providersRouter.patch("/:providerId/details", asyncRoute(async (req, res) => {
  const id = req.params.providerId;
  if (!/^[a-z0-9_-]{1,64}$/i.test(id)) throw new ApiError(400, "ID de provedor inválido.", "invalid-argument");
  if (!canAccessProvider(req, id)) throw new ApiError(403, "Sem permissão para este provedor.", "permission-denied");
  const rawDetails = req.body?.details && typeof req.body.details === "object" ? req.body.details : req.body;
  let details: Record<string, unknown>;
  try { details = parseDetails(rawDetails); }
  catch { throw new ApiError(400, "Detalhes inválidos ou campo não permitido.", "invalid-argument"); }
  const pool = requirePgPool();
  if (!(await getProviderRow(pool, id))) throw new ApiError(404, "Provedor não encontrado.", "not-found");
  const patch: Record<string, unknown> = { details };
  if (typeof details.name === "string" && details.name.trim()) patch.name = details.name.trim();
  await upsertProvider(pool, id, patch);
  publicConfigCache.delete(id);
  await recordAdminAudit({ type: "UPDATE_PROVIDER_DETAILS", requesterUid: req.user!.uid, providerId: id, correlationId: req.correlationId, payload: details });
  res.json({ success: true, id });
}));

providersRouter.post("/", asyncRoute(async (req, res) => {
  if (!req.body || typeof req.body !== "object" || Array.isArray(req.body) ||
      (req.body.id !== undefined && typeof req.body.id !== "string") ||
      (req.body.providerId !== undefined && typeof req.body.providerId !== "string")) {
    throw new ApiError(400, "Configuração inválida.", "invalid-argument");
  }
  const rawId = typeof req.body?.id === "string" ? req.body.id : typeof req.body?.providerId === "string" ? req.body.providerId : "";
  const id = rawId.trim();
  if (!id && req.user?.superAdmin !== true) throw new ApiError(403, "Apenas Super Admin pode criar provedores.", "permission-denied");
  if (id && !canAccessProvider(req, id)) throw new ApiError(403, "Sem permissão para alterar este provedor.", "permission-denied");
  if (id && !/^[a-z0-9_-]+$/i.test(id)) throw new ApiError(400, "ID de provedor inválido.", "invalid-argument");

  const { id: _id, providerId: _providerId, ...input } = req.body;
  let data: Record<string, unknown>;
  try { data = parseProviderInput(input, req.user?.superAdmin === true); }
  catch { throw new ApiError(400, "Configuração inválida ou campo não permitido.", "invalid-argument"); }

  const pool = requirePgPool();
  const existing = id ? await getProviderRow(pool, id, { includeDeleted: true }) : null;
  const existed = Boolean(existing) && !(existing?.data && typeof existing.data === "object" && "deletedAt" in existing.data);
  if (!existed && req.user?.superAdmin !== true) {
    throw new ApiError(403, "Apenas Super Admin pode criar provedores.", "permission-denied");
  }
  // Criar com um ID já usado (inclusive de provedor excluído) nunca
  // sobrescreve o provedor existente nem reaproveita os dados dele.
  if (existing && req.user?.superAdmin === true) {
    throw new ApiError(409, "Já existe um provedor com este ID.", "already-exists");
  }
  const saved = await upsertProvider(pool, id || null, data);
  publicConfigCache.delete(saved.id);
  await recordAdminAudit({
    type: existed ? "UPDATE_PROVIDER" : "CREATE_PROVIDER",
    requesterUid: req.user!.uid,
    providerId: saved.id,
    correlationId: req.correlationId,
    payload: data,
  });
  return res.status(existed ? 200 : 201).json({ success: true, id: saved.id });
}));

providersRouter.delete("/:providerId", asyncRoute(async (req, res) => {
  if (req.user?.superAdmin !== true) throw new ApiError(403, "Apenas Super Admin pode excluir provedores.", "permission-denied");
  const id = req.params.providerId;
  if (!/^[a-z0-9_-]{1,64}$/i.test(id)) throw new ApiError(400, "ID de provedor inválido.", "invalid-argument");
  const removed = await deleteProviderRow(requirePgPool(), id);
  if (!removed) throw new ApiError(404, "Provedor não encontrado.", "not-found");
  publicConfigCache.delete(id);
  await recordAdminAudit({ type: "DELETE_PROVIDER", requesterUid: req.user!.uid, providerId: id, correlationId: req.correlationId });
  res.json({ success: true });
}));

/**
 * Uma leitura mínima no IXC (cliente, 1 registro) antes de gravar: token ou
 * URL errados viram 400 claro, em vez de um sync que falha em silêncio.
 * Passa pelo mesmo cliente de saída (SSRF guard/IP fixado) das consultas.
 */
async function probeIxcIntegration(integration: Record<string, string>): Promise<void> {
  const invalid = (status: number | string) => new ApiError(400, `Token ou URL do IXC inválidos (HTTP ${status}).`, "invalid-argument");
  let response: { status: number; data: unknown };
  try {
    response = (await sgpOutbound.request(ixcUrl(integration.sgpBaseUrl, "cliente"), {
      qtype: "cliente.id", query: "0", oper: ">", page: "1", rp: "1", sortname: "cliente.id", sortorder: "desc",
    }, { encoding: "json", timeout: 15000, headers: ixcHeaders(integration.apiToken, "listar") })) as { status: number; data: unknown };
  } catch (error) {
    const status = Number((error as { response?: { status?: number } })?.response?.status);
    if (status >= 300 && status < 500) throw invalid(status);
    throw new ApiError(502, "Não foi possível testar a conexão com o IXC agora. Tente novamente.", "upstream-error");
  }
  const data = response.data as { type?: unknown } | string | null;
  // URL errada costuma responder 200 com página HTML; token sem acesso, type:"error".
  if (!data || typeof data !== "object" || String(data.type || "").toLowerCase() === "error") throw invalid(response.status);
}

providersRouter.post("/:providerId/integration", verifyFreshToken, asyncRoute(async (req, res) => {
  if (req.user?.superAdmin !== true) throw new ApiError(403, "Apenas SaaS pode substituir integração.", "permission-denied");
  // 401 com código "reauth-required": o painel pede a senha e repete a ação.
  requireRecentLogin(req);

  const id = req.params.providerId;
  if (!/^[a-z0-9_-]+$/i.test(id)) throw new ApiError(400, "ID inválido.", "invalid-argument");
  let integrations: Record<string, string>;
  try { integrations = parsePrivateIntegration(req.body); }
  catch { throw new ApiError(400, "Integração inválida.", "invalid-argument"); }
  try { await sgpOutbound.assertSafeSgpBaseUrl(integrations.sgpBaseUrl); }
  catch { throw new ApiError(400, "Destino SGP inválido ou interno.", "invalid-argument"); }

  const pool = requirePgPool();
  if (!(await getProviderRow(pool, id))) throw new ApiError(404, "Provedor não encontrado.", "not-found");
  if (integrations.erp === "ixc") await probeIxcIntegration(integrations);
  await saveProviderSecret(pool, id, "erp", integrations);
  await recordAdminAudit({ type: "REPLACE_PROVIDER_INTEGRATION", requesterUid: req.user!.uid, providerId: id, payload: { replaced: true } });

  let syncQueued = false;
  if (process.env.NODE_ENV !== "test") {
    try {
      await proxyToSgp("/sync-clients", { providerId: id }, req.headers.authorization);
      syncQueued = true;
    } catch {
      // A integração foi salva; o sync inicial pode ser acionado manualmente ou pelo cron.
    }
  }
  res.json(syncQueued ? { success: true, syncQueued: true } : { success: true });
}));

// Situação da integração com o ERP, sem segredos. O Super Admin vê também o
// host configurado; o admin do provedor vê só se está configurada.
providersRouter.get("/:providerId/integration/status", asyncRoute(async (req, res) => {
  const id = req.params.providerId;
  if (!/^[a-z0-9_-]{1,64}$/i.test(id)) throw new ApiError(400, "ID de provedor inválido.", "invalid-argument");
  if (!canAccessProvider(req, id)) throw new ApiError(403, "Sem permissão para este provedor.", "permission-denied");
  const pool = requirePgPool();
  const provider = await getProviderRow(pool, id);
  if (!provider) throw new ApiError(404, "Provedor não encontrado.", "not-found");
  const [secret, meta, acs] = await Promise.all([
    getProviderSecret<Record<string, unknown>>(pool, id, "erp").catch(() => null),
    getProviderSecretMeta(pool, id, "erp").catch(() => null),
    getProviderSecret<Record<string, unknown>>(pool, id, "acs").catch(() => null),
  ]);
  const erp = secret ? (String(secret.erp || "sgp").toLowerCase() === "ixc" ? "ixc" : "sgp") : null;
  let baseUrlHost: string | null = null;
  if (secret && typeof secret.sgpBaseUrl === "string") {
    try { baseUrlHost = new URL(secret.sgpBaseUrl).host; } catch { baseUrlHost = null; }
  }
  const data = (provider.data || {}) as Record<string, unknown>;
  const lastSync = data.lastClientSyncAt;
  const lastClientSyncAt = typeof lastSync === "string" ? lastSync
    : lastSync && typeof lastSync === "object" && Number.isFinite(Number((lastSync as Record<string, unknown>)._seconds))
      ? new Date(Number((lastSync as Record<string, unknown>)._seconds) * 1000).toISOString() : null;
  const countRes = await getPgPool()?.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM sgp_clients WHERE provider_id = $1`, [id])
    .catch(() => ({ rows: [] as { count: string }[] }));
  const clientCount = countRes?.rows?.[0] ? Number(countRes.rows[0].count) : null;
  res.json({
    data: {
      configured: Boolean(secret),
      erp,
      erpLabel: erp === "ixc" ? "IXC Provedor" : erp === "sgp" ? "SGP" : null,
      ...(req.user?.superAdmin === true ? { baseUrlHost } : {}),
      configuredAt: meta?.updatedAt || null,
      lastClientSyncAt,
      lastClientSyncPartial: data.lastClientSyncPartial === true,
      syncedClientCount: Number.isFinite(Number(data.syncedClientCount)) ? Number(data.syncedClientCount) : null,
      clientCount,
      tr069: acs ? { driver: String(acs.driver || "none"), enabled: Boolean(acs.enabled) && acs.driver !== "none" } : { driver: "none", enabled: false },
    },
  });
}));

providersRouter.get("/:providerId/backups", asyncRoute(async (req, res) => {
  const id = req.params.providerId;
  if (!/^[a-z0-9_-]{1,64}$/i.test(id)) throw new ApiError(400, "ID de provedor inválido.", "invalid-argument");
  if (!canAccessProvider(req, id)) throw new ApiError(403, "Sem permissão.", "permission-denied");
  const backups = await listProviderBackups(requirePgPool(), id);
  res.json({ data: backups });
}));

providersRouter.post("/:providerId/backups", asyncRoute(async (req, res) => {
  const id = req.params.providerId;
  if (!/^[a-z0-9_-]{1,64}$/i.test(id)) throw new ApiError(400, "ID de provedor inválido.", "invalid-argument");
  if (!canAccessProvider(req, id)) throw new ApiError(403, "Sem permissão.", "permission-denied");
  const label = typeof req.body?.label === "string" ? req.body.label.trim().slice(0, 120) : "";
  const created = await createProviderBackup(requirePgPool(), id, req.user!.uid, label);
  await recordAdminAudit({ type: "BACKUP_PROVIDER_CONFIG", requesterUid: req.user!.uid, providerId: id, correlationId: req.correlationId });
  res.status(201).json({ success: true, ...created });
}));

providersRouter.post("/:providerId/backups/:backupId/restore", asyncRoute(async (req, res) => {
  const id = req.params.providerId;
  const backupId = req.params.backupId;
  if (!/^[a-z0-9_-]{1,64}$/i.test(id) || !/^[a-z0-9_-]{1,64}$/i.test(backupId)) {
    throw new ApiError(400, "Identificador inválido.", "invalid-argument");
  }
  if (!canAccessProvider(req, id)) throw new ApiError(403, "Sem permissão.", "permission-denied");
  const pool = requirePgPool();
  const [provider, backup] = await Promise.all([
    getProviderRow(pool, id),
    getProviderBackup(pool, id, backupId),
  ]);
  if (!provider) throw new ApiError(404, "Provedor não encontrado.", "not-found");
  if (!backup) throw new ApiError(404, "Backup não encontrado.", "not-found");

  // Backup sem nenhuma personalização apagaria layout, cores e logo do app.
  if (!Object.keys(sanitizePersonalization(backup.snapshot || {})).length) {
    throw new ApiError(400, "Backup sem personalização. Escolha outro backup.", "failed-precondition");
  }
  const nextData = restoredPersonalization(provider.data || {}, backup.snapshot || {});
  await upsertProvider(pool, id, nextData, { replaceData: true });
  publicConfigCache.delete(id);
  await recordAdminAudit({ type: "RESTORE_PROVIDER_CONFIG", requesterUid: req.user!.uid, providerId: id, correlationId: req.correlationId });
  res.json({ success: true });
}));

providersRouter.delete("/:providerId/backups/:backupId", asyncRoute(async (req, res) => {
  const id = req.params.providerId;
  const backupId = req.params.backupId;
  if (!/^[a-z0-9_-]{1,64}$/i.test(id) || !/^[a-z0-9_-]{1,64}$/i.test(backupId)) {
    throw new ApiError(400, "Identificador inválido.", "invalid-argument");
  }
  if (!canAccessProvider(req, id)) throw new ApiError(403, "Sem permissão.", "permission-denied");
  const removed = await deleteProviderBackup(requirePgPool(), id, backupId);
  if (!removed) throw new ApiError(404, "Backup não encontrado.", "not-found");
  res.json({ success: true });
}));

providersRouter.post("/:providerId/assets", (req, res, next) => rawAssetBody(req, res, (err) =>
  next(err ? new ApiError((err as { status?: number }).status === 413 ? 413 : 400, "Imagem inválida ou maior que 2 MiB.") : undefined)),
asyncRoute(async (req, res) => {
  const id = req.params.providerId;
  if (!/^[a-z0-9_-]{1,64}$/i.test(id)) throw new ApiError(400, "ID de provedor inválido.", "invalid-argument");
  if (!canAccessProvider(req, id)) throw new ApiError(403, "Sem permissão para este provedor.", "permission-denied");
  if (!(await getProviderRow(requirePgPool(), id))) throw new ApiError(404, "Provedor não encontrado.", "not-found");

  const mime = String(req.headers["content-type"] || "").split(";")[0].trim().toLowerCase();
  const ext = detectAssetExtension(req.body, mime);
  if (!ext) throw new ApiError(415, "Formato de imagem não suportado (use PNG, JPG ou WebP até 2 MiB).");

  const filename = `${randomUUID().replace(/-/g, "")}.${ext}`;
  const dir = path.resolve(process.env.UPLOADS_DIR?.trim() || "/srv/uploads", "public", id);
  await fs.mkdir(dir, { recursive: true });
  await fs.writeFile(path.join(dir, filename), req.body, { flag: "wx" });
  res.status(201).json({ url: `/api/public/assets/${id}/${filename}` });
}));
