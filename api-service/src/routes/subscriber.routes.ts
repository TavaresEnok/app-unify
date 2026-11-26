import { randomUUID } from "node:crypto";
import { Router, type Request } from "express";
import { invoiceAmount } from "../services/invoice-amount";
import { verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { sgpLimiter, subscriberReplyLimiter, subscriberTicketLimiter, tenantLimiter } from "../middlewares/rateLimits";
import {
  createSgpSession,
  externalErrorMessage,
  listContracts,
  pickContracts,
  resolveSgpCredentials,
  type SgpContract,
} from "../services/sgpClient";
import { mapWithConcurrency } from "../services/boundedWork";
import { ensureCoreSchema, getPgPool, requirePgPool } from "../services/postgres";
import { getProviderRow } from "../services/providersStore";
import {
  listSubscriberNotifications,
  registerSubscriberDevice,
  unregisterSubscriberDevice,
} from "../services/notificationCampaigns";
import { providerOfCpf } from "../services/tenantScope";

interface CachedIncident {
  id: string;
  title: string;
  message: string;
  severity: string;
  area: string;
  estimatedResolution: string;
  createdAt: string | null;
}

const INCIDENT_CACHE_TTL_MS = 30_000;
const incidentCache = new Map<string, { expiresAt: number; items: CachedIncident[] }>();

export function clearIncidentCacheForTests(): void {
  incidentCache.clear();
}

export function invalidateSubscriberIncidentCache(providerId: string): void {
  incidentCache.delete(providerId);
}

async function getActiveProviderIncidents(providerId: string): Promise<CachedIncident[]> {
  const now = Date.now();
  const cached = incidentCache.get(providerId);
  if (cached && cached.expiresAt > now) {
    return cached.items;
  }
  const pool = getPgPool();
  if (!pool) return [];
  await ensureCoreSchema(pool);

  const res = await pool.query<{
    id: string;
    title: string;
    message: string;
    severity: string;
    area: string | null;
    estimated_resolution: string | null;
    created_at: Date;
  }>(
    `SELECT id, title, message, severity, area, estimated_resolution, created_at
       FROM incidents
      WHERE provider_id = $1 AND active = TRUE
      ORDER BY created_at DESC
      LIMIT 10`,
    [providerId],
  );

  const items: CachedIncident[] = res.rows.map((d) => ({
    id: d.id,
    title: String(d.title || "Aviso de rede"),
    message: String(d.message || ""),
    severity: String(d.severity || "warning"),
    area: String(d.area || ""),
    estimatedResolution: String(d.estimated_resolution || ""),
    createdAt: d.created_at instanceof Date ? d.created_at.toISOString() : null,
  }));

  incidentCache.set(providerId, { expiresAt: now + INCIDENT_CACHE_TTL_MS, items });
  return items;
}

function incidentMatchesSubscriber(area: string, tokens: string[]): boolean {
  const normalized = area.trim().toLowerCase();
  if (!normalized || normalized === "todos" || normalized === "geral" || normalized === "toda a rede") {
    return true;
  }
  return tokens.some((tok) => tok && (normalized.includes(tok) || tok.includes(normalized)));
}

export const subscriberRouter = Router();

interface SubscriberContext {
  cpfCnpj: string;
  providerId?: string;
}

async function subscriberContext(req: Request): Promise<SubscriberContext> {
  const cpfCnpj = typeof req.body?.cpfCnpj === "string" ? req.body.cpfCnpj.trim() : "";
  if (!cpfCnpj) throw new ApiError(400, "CPF/CNPJ é obrigatório.", "invalid-argument");
  const digits = cpfCnpj.replace(/\D/g, "");
  if (!/^\d{11}(\d{3})?$/.test(digits)) throw new ApiError(400, "CPF/CNPJ inválido.", "invalid-argument");
  const user = req.user;
  if (user?.superAdmin !== true && req.body?.providerId && req.body.providerId !== user?.providerId) {
    throw new ApiError(403, "Provedor inválido.", "permission-denied");
  }

  if (user?.superAdmin === true) {
    const fromBody = typeof req.body?.providerId === "string" && req.body.providerId ? req.body.providerId : undefined;
    return { cpfCnpj, providerId: fromBody };
  }
  if (user?.role === "subscriber" && user.cpfCnpj === digits) {
    const claim = typeof user.providerId === "string" && user.providerId ? user.providerId : undefined;
    return { cpfCnpj, providerId: claim };
  }
  if (user?.role === "providerAdmin" && typeof user.providerId === "string") {
    const owner = await providerOfCpf(digits, user.providerId);
    if (!owner || owner !== user.providerId) {
      throw new ApiError(403, "Este cliente não pertence ao seu provedor.", "permission-denied");
    }
    return { cpfCnpj, providerId: owner };
  }
  throw new ApiError(403, "Você só pode acessar os seus próprios dados.", "permission-denied");
}

async function sgpForRequest(req: Request) {
  if (["url", "token", "app", "sgpBaseUrl", "sgpParams", "apiToken", "appName"].some((key) => Object.prototype.hasOwnProperty.call(req.body || {}, key))) {
    throw new ApiError(400, "Configuração SGP não permitida no pedido.", "invalid-argument");
  }
  const context = await subscriberContext(req);
  const credentials = await resolveSgpCredentials(context.providerId);
  return { ...context, credentials, session: createSgpSession(credentials.providerId, credentials.baseUrl, credentials) };
}

function upstreamError(req: Request, message: string, error: unknown): ApiError {
  console.warn(JSON.stringify({
    severity: "WARNING",
    message,
    correlationId: req.correlationId,
    error: externalErrorMessage(error, "SGP indisponível"),
  }));
  return new ApiError(502, message, "upstream-error");
}

function money(value: unknown): string {
  return `R$ ${Number(value || 0).toFixed(2).replace(".", ",")}`;
}

function openValue(item: SgpContract): number {
  return Number(item.contrato.contratoValorAberto || 0);
}

function contractSummary(item: SgpContract) {
  return {
    contratoId: item.contratoId,
    plano: item.contrato.servico_plano || item.contrato.plano || "Plano não informado",
    status: item.contrato.contratoStatusDisplay || item.contrato.contratoStatus || null,
    valorAberto: money(openValue(item)),
    vencimento: item.contrato.cobVencimento || null,
  };
}

subscriberRouter.post("/getClientData", verifyToken, sgpLimiter, tenantLimiter, asyncRoute(async (req, res) => {
  const { cpfCnpj, credentials, session } = await sgpForRequest(req);
  try {
    const contracts = await listContracts(session, credentials, cpfCnpj);
    const [selected] = pickContracts(contracts, req.body?.contratoId);
    const { contrato, contratoId, senhaCentral } = selected;
    let connectionStatus = "Offline";
    if (senhaCentral) {
      try {
        const form = new URLSearchParams({
          cpfcnpj: cpfCnpj.replace(/\D/g, ""),
          senha: senhaCentral,
          contrato: contratoId,
        });
        const response = await session.post(`${credentials.baseUrl}/api/central/verificaacesso/`, form);
        const data = response.data;
        const statusText = String(data?.status ?? "").trim().toLowerCase();
        const msgText = String(data?.msg ?? "").toLowerCase();
        if (
          data?.status === 1 || data?.status === "1" ||
          msgText.includes("online") ||
          data?.online === true || data?.online === 1 || data?.online === "1" ||
          ["online", "ativo"].includes(statusText) ||
          data?.disponivel === true || data?.disponivel === 1 ||
          data?.ativo === true || data?.ativo === 1 ||
          data?.acesso === true || data?.acesso === 1 || data?.acesso === "liberado"
        ) {
          connectionStatus = "Online";
        }
      } catch (error) {
        console.warn(JSON.stringify({ severity: "WARNING", message: "Falha ao consultar status do contrato", correlationId: req.correlationId, error: externalErrorMessage(error, "SGP indisponível") }));
      }
    }
    res.json({ data: {
      cpfCnpj: contrato.cpfCnpj || cpfCnpj,
      userName: contrato.razaoSocial || contrato.nome || null,
      userPlan: contrato.servico_plano || contrato.plano || null,
      userStatus: connectionStatus,
      contractStatus: contrato.contratoStatusDisplay || contrato.contratoStatus || contrato.status || null,
      email: contrato.email || contrato.emailContato || null,
      billValue: contrato.contratoValorAberto == null ? null : money(contrato.contratoValorAberto),
      billDueDate: contrato.cobVencimento == null ? null : String(contrato.cobVencimento),
      contratoId,
      totalAberto: money(contracts.reduce((sum, item) => sum + openValue(item), 0)),
      contratos: contracts.map(contractSummary),
    } });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw upstreamError(req, "Erro ao buscar dados do cliente.", error);
  }
}));

subscriberRouter.post("/getConsumptionData", verifyToken, sgpLimiter, tenantLimiter, asyncRoute(async (req, res) => {
  const { cpfCnpj, credentials, session } = await sgpForRequest(req);
  try {
    const contracts = pickContracts(await listContracts(session, credentials, cpfCnpj), req.body?.contratoId)
      .filter((item) => item.senhaCentral);
    if (!contracts.length) throw new ApiError(503, "Credencial do contrato indisponível para consulta de consumo.", "service-unavailable");
    const now = new Date();
    const usage = await mapWithConcurrency(contracts, 2, async (item) => {
      const form = new URLSearchParams({
        cpfcnpj: cpfCnpj,
        senha: item.senhaCentral,
        contrato: item.contratoId,
        mes: String(now.getMonth() + 1),
        ano: String(now.getFullYear()),
      });
      const response = await session.post(`${credentials.baseUrl}/api/central/extratouso/`, form);
      const quota = String(response.data?.plano || "").match(/(\d+(?:[.,]\d+)?)\s*GB\b/i);
      const total = response.data?.total;
      const totalBytes = total == null || total === "" ? null : Number(total);
      return {
        contratoId: item.contratoId,
        totalGb: quota ? Number(quota[1].replace(",", ".")) : null,
        usedGb: totalBytes != null && Number.isFinite(totalBytes) ? totalBytes / (1024 ** 3) : null,
      };
    });
    res.json({ data: {
      totalGb: usage.every((item) => item.totalGb != null)
        ? usage.reduce((sum, item) => sum + (item.totalGb ?? 0), 0) : null,
      usedGb: usage.every((item) => item.usedGb != null)
        ? usage.reduce((sum, item) => sum + (item.usedGb ?? 0), 0) : null,
      averageSpeed: null,
      period: `${String(now.getMonth() + 1).padStart(2, "0")}/${now.getFullYear()}`,
      contratos: usage,
    } });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw upstreamError(req, "Erro ao buscar consumo.", error);
  }
}));

subscriberRouter.post("/getInvoices", verifyToken, sgpLimiter, tenantLimiter, asyncRoute(async (req, res) => {
  const { cpfCnpj, credentials, session } = await sgpForRequest(req);
  const payload: Record<string, string> = { token: credentials.token, app: credentials.app, cpfcnpj: cpfCnpj };
  try {
    if (req.body?.contratoId) {
      const [selected] = pickContracts(await listContracts(session, credentials, cpfCnpj), req.body.contratoId);
      payload.contrato = selected.contratoId;
    }
    const [open, paid] = await Promise.all([
      session.post(`${credentials.baseUrl}/api/ura/titulos/`, { ...payload, status: "abertos" }),
      session.post(`${credentials.baseUrl}/api/ura/titulos/`, { ...payload, status: "pagos" }),
    ]);
    const format = (invoice: any, pago: boolean) => ({
      pago,
      vencimento: invoice.dataVencimento,
      valor: invoiceAmount(invoice.valor)?.toFixed(2).replace(".", ",") ?? null,
      dataPagamento: pago ? invoice.dataPagamento : undefined,
      linha_digitavel: invoice.linhaDigitavel,
      linha_digitavel_pix: invoice.codigoPix,
      link: invoice.link,
      id: invoice.id,
      numero_documento: invoice.numeroDocumento,
      contratoId: invoice.contrato ?? invoice.contratoId ?? null,
    });
    const invoicesFor = (data: { titulos?: unknown }, pago: boolean) => {
      if (!Array.isArray(data?.titulos)) {
        throw new ApiError(502, "O provedor não retornou a lista de faturas.", "upstream-error");
      }
      // Título sem contrato (null, '' ou '0' — avulso/renegociação) nunca é descartado.
      const contractOf = (item: any) => {
        const value = item.contratoId ?? item.contrato;
        return value == null || ["", "0"].includes(String(value).trim()) ? null : String(value);
      };
      return data.titulos.filter((item) => !payload.contrato ||
        contractOf(item) === null ||
        contractOf(item) === payload.contrato)
        .map((item) => format(item, pago));
    };
    const opens = invoicesFor(open.data, false);
    const paids = invoicesFor(paid.data, true);
    res.json({ data: [...opens, ...paids] });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw upstreamError(req, "Erro ao buscar faturas.", error);
  }
}));

subscriberRouter.post("/makePaymentPromise", verifyToken, sgpLimiter, tenantLimiter, asyncRoute(async (req, res) => {
  const { cpfCnpj, credentials, session } = await sgpForRequest(req);
  try {
    const contracts = await listContracts(session, credentials, cpfCnpj);
    let targets = pickContracts(contracts, req.body?.contratoId);
    if (!req.body?.contratoId) {
      const withDebt = targets.filter((item) => openValue(item) > 0);
      if (withDebt.length) targets = withDebt;
    }
    const resultados: Array<{ contratoId: string; success: boolean; message: string }> = [];
    for (const item of targets) {
      const response = await session.post(`${credentials.baseUrl}/api/ura/liberacaopromessa/`, {
        token: credentials.token, app: credentials.app, contrato: item.contratoId,
      });
      const success = [true, 1, "1", "true"].includes(response.data?.status);
      resultados.push({
        contratoId: item.contratoId,
        success,
        message: response.data?.msg || (success ? "Promessa de pagamento realizada com sucesso!" : "Não foi possível realizar a promessa."),
      });
    }
    if (!resultados.some((item) => item.success)) throw new ApiError(409, resultados[0].message, "upstream-rejected");
    res.json({ success: true, message: resultados.find((item) => item.success)!.message, resultados });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw upstreamError(req, "Erro ao realizar promessa.", error);
  }
}));

subscriberRouter.post("/subscriber/device-token", verifyToken, asyncRoute(async (req, res) => {
  if (req.user?.role !== "subscriber" || !req.user.providerId || !req.user.cpfCnpj) {
    throw new ApiError(403, "Apenas assinantes podem registrar dispositivo.", "permission-denied");
  }
  const fcmToken = typeof req.body?.fcmToken === "string" ? req.body.fcmToken.trim() : "";
  if (!fcmToken || fcmToken.length > 512) {
    throw new ApiError(400, "Token FCM inválido.", "invalid-argument");
  }
  const pool = getPgPool();
  if (!pool) {
    res.status(200).json({ success: false, stored: false });
    return;
  }
  await registerSubscriberDevice(pool, {
    providerId: req.user.providerId,
    cpfCnpj: req.user.cpfCnpj,
    authUid: req.user.uid,
    fcmToken,
    contratoId: req.body?.contratoId != null ? String(req.body.contratoId) : "",
    plano: typeof req.body?.plano === "string" ? req.body.plano : "",
    contractStatus: typeof req.body?.contractStatus === "string" ? req.body.contractStatus : "",
    connectionStatus: typeof req.body?.connectionStatus === "string" ? req.body.connectionStatus : "",
  });
  res.status(200).json({ success: true, stored: true });
}));

subscriberRouter.delete("/subscriber/device-token", verifyToken, asyncRoute(async (req, res) => {
  if (req.user?.role !== "subscriber" || !req.user.providerId || !req.user.cpfCnpj) {
    throw new ApiError(403, "Apenas assinantes podem remover dispositivo.", "permission-denied");
  }
  const pool = getPgPool();
  if (pool) {
    const fcmToken = typeof req.body?.fcmToken === "string" ? req.body.fcmToken.trim() : undefined;
    await unregisterSubscriberDevice(pool, req.user.providerId, req.user.cpfCnpj, fcmToken);
  }
  res.status(200).json({ success: true });
}));

// Sair da conta: remove o token de notificação do aparelho e invalida as
// sessões do assinante (token_version + 1). Chamado de novo, só repete.
subscriberRouter.post("/subscriber/logout", verifyToken, asyncRoute(async (req, res) => {
  if (req.user?.role !== "subscriber" || !req.user.providerId || !req.user.cpfCnpj) {
    throw new ApiError(403, "Apenas assinantes podem sair por esta rota.", "permission-denied");
  }
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const fcmToken = typeof req.body?.fcmToken === "string" && req.body.fcmToken.trim() ? req.body.fcmToken.trim().slice(0, 512) : undefined;
  if (fcmToken) await unregisterSubscriberDevice(pool, req.user.providerId, req.user.cpfCnpj, fcmToken);
  await pool.query(
    `UPDATE subscribers SET token_version = token_version + 1, updated_at = NOW()
      WHERE provider_id = $1 AND cpfcnpj = $2`,
    [req.user.providerId, req.user.cpfCnpj],
  );
  res.json({ success: true });
}));

subscriberRouter.get("/subscriber/notifications", verifyToken, asyncRoute(async (req, res) => {
  if (req.user?.role !== "subscriber" || !req.user.providerId || !req.user.cpfCnpj) {
    throw new ApiError(403, "Apenas assinantes podem consultar notificações.", "permission-denied");
  }
  const pool = getPgPool();
  if (!pool) {
    res.json({ data: [] });
    return;
  }
  const limit = Number(req.query.limit || 30);
  const data = await listSubscriberNotifications(pool, req.user.providerId, req.user.cpfCnpj, limit);
  res.json({ data });
}));

subscriberRouter.get("/subscriber/incidents", verifyToken, asyncRoute(async (req, res) => {
  const user = req.user;
  const providerId = user?.role === "subscriber"
    ? user.providerId
    : user?.superAdmin && typeof req.query.providerId === "string"
      ? req.query.providerId.trim()
      : user?.providerId;

  if (!providerId) {
    throw new ApiError(403, "Provedor não identificado.", "permission-denied");
  }

  const active = await getActiveProviderIncidents(providerId);
  if (!active.length) {
    res.json({ data: [] });
    return;
  }

  let areaTokens: string[] = [];
  const pool = getPgPool();
  if (pool && user?.role === "subscriber" && user.cpfCnpj) {
    const segRes = await pool.query<{ olt_name: string; bairro: string; cidade: string }>(
      `SELECT olt_name, bairro, cidade
         FROM subscriber_segments
        WHERE provider_id = $1 AND cpfcnpj = $2
        LIMIT 5`,
      [providerId, user.cpfCnpj],
    ).catch(() => ({ rows: [] }));
    areaTokens = segRes.rows
      .flatMap((r) => [r.olt_name, r.bairro, r.cidade])
      .map((v) => String(v || "").trim().toLowerCase())
      .filter((v) => v.length >= 2);
  }

  const enriched = active
    .map((inc) => ({
      ...inc,
      matchesArea: incidentMatchesSubscriber(inc.area, areaTokens),
    }))
    .sort((a, b) => Number(b.matchesArea) - Number(a.matchesArea));

  res.json({ data: enriched });
}));

subscriberRouter.get("/subscriber/tickets", verifyToken, asyncRoute(async (req, res) => {
  if (req.user?.role !== "subscriber" || !req.user.providerId) {
    throw new ApiError(403, "Apenas assinantes podem consultar seus chamados.", "permission-denied");
  }
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const rows = await pool.query<{
    id: string;
    subject: string;
    status: string;
    last_message: string;
    created_at: Date;
    updated_at: Date;
  }>(
    `SELECT id, subject, status, last_message, created_at, updated_at
       FROM tickets
      WHERE provider_id = $1 AND created_by_uid = $2
      ORDER BY updated_at DESC
      LIMIT 50`,
    [req.user.providerId, req.user.uid],
  );
  res.json({
    data: rows.rows.map((r) => ({
      id: r.id,
      subject: r.subject,
      status: r.status,
      lastMessage: r.last_message,
      createdAt: r.created_at instanceof Date ? r.created_at.toISOString() : String(r.created_at),
      updatedAt: r.updated_at instanceof Date ? r.updated_at.toISOString() : String(r.updated_at),
    })),
  });
}));

subscriberRouter.post("/subscriber/tickets", verifyToken, subscriberTicketLimiter, asyncRoute(async (req, res) => {
  if (req.user?.role !== "subscriber" || !req.user.providerId || !req.user.cpfCnpj) {
    throw new ApiError(403, "Apenas assinantes podem abrir chamados.", "permission-denied");
  }
  const subject = typeof req.body?.subject === "string" ? req.body.subject.trim() : "";
  const message = typeof req.body?.message === "string" ? req.body.message.trim() : "";
  if (!subject || !message) {
    throw new ApiError(400, "Assunto e mensagem são obrigatórios.", "invalid-argument");
  }
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const provider = await getProviderRow(pool, req.user.providerId);
  const providerName = provider?.name || req.user.providerId;
  const userEmail = typeof req.body?.userEmail === "string" && req.body.userEmail.trim()
    ? req.body.userEmail.trim().slice(0, 180)
    : req.user.email || "";

  const ticketId = randomUUID().replace(/-/g, "").slice(0, 20);
  const msgId = randomUUID().replace(/-/g, "").slice(0, 20);

  await pool.query(
    `INSERT INTO tickets (id, provider_id, provider_name, subject, status, created_by_uid, created_by_email, cpfcnpj, last_message, created_at, updated_at)
     VALUES ($1, $2, $3, $4, 'Aberto', $5, $6, $7, $8, NOW(), NOW())`,
    [ticketId, req.user.providerId, providerName, subject.slice(0, 200), req.user.uid, userEmail, req.user.cpfCnpj, message.slice(0, 2000)],
  );
  await pool.query(
    `INSERT INTO ticket_messages (id, ticket_id, sender_uid, sender_email, sender_role, message, read, created_at)
     VALUES ($1, $2, $3, $4, 'subscriber', $5, FALSE, NOW())`,
    [msgId, ticketId, req.user.uid, userEmail, message.slice(0, 4000)],
  );
  res.status(201).json({ success: true, ticketId });
}));

subscriberRouter.get("/subscriber/tickets/:id/messages", verifyToken, asyncRoute(async (req, res) => {
  if (req.user?.role !== "subscriber" || !req.user.providerId) {
    throw new ApiError(403, "Acesso negado.", "permission-denied");
  }
  const ticketId = String(req.params.id || "").trim();
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const owner = await pool.query<{ provider_id: string; created_by_uid: string }>(
    `SELECT provider_id, created_by_uid FROM tickets WHERE id = $1 LIMIT 1`,
    [ticketId],
  );
  const ticket = owner.rows[0];
  if (!ticket) throw new ApiError(404, "Ticket não encontrado.", "not-found");
  if (ticket.provider_id !== req.user.providerId || ticket.created_by_uid !== req.user.uid) {
    throw new ApiError(403, "Sem permissão para este chamado.", "permission-denied");
  }
  const messages = await pool.query<{
    id: string;
    sender_uid: string;
    sender_email: string;
    sender_role: string;
    message: string;
    attachment_id: string | null;
    created_at: Date;
  }>(
    `SELECT id, sender_uid, sender_email, sender_role, message, attachment_id, created_at
       FROM ticket_messages
      WHERE ticket_id = $1
      ORDER BY created_at ASC`,
    [ticketId],
  );
  res.json({
    data: messages.rows.map((m) => ({
      id: m.id,
      senderUid: m.sender_uid,
      senderEmail: m.sender_email,
      senderRole: m.sender_role,
      message: m.message,
      attachmentId: m.attachment_id,
      createdAt: m.created_at instanceof Date ? m.created_at.toISOString() : String(m.created_at),
    })),
  });
}));

subscriberRouter.post("/subscriber/tickets/:id/reply", verifyToken, subscriberReplyLimiter, asyncRoute(async (req, res) => {
  if (req.user?.role !== "subscriber" || !req.user.providerId) {
    throw new ApiError(403, "Acesso negado.", "permission-denied");
  }
  const ticketId = String(req.params.id || "").trim();
  const message = typeof req.body?.message === "string" ? req.body.message.trim() : "";
  if (!message) throw new ApiError(400, "Mensagem obrigatória.", "invalid-argument");
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const owner = await pool.query<{ provider_id: string; created_by_uid: string }>(
    `SELECT provider_id, created_by_uid FROM tickets WHERE id = $1 LIMIT 1`,
    [ticketId],
  );
  const ticket = owner.rows[0];
  if (!ticket) throw new ApiError(404, "Ticket não encontrado.", "not-found");
  if (ticket.provider_id !== req.user.providerId || ticket.created_by_uid !== req.user.uid) {
    throw new ApiError(403, "Sem permissão para este chamado.", "permission-denied");
  }
  const msgId = randomUUID().replace(/-/g, "").slice(0, 20);
  await pool.query(
    `INSERT INTO ticket_messages (id, ticket_id, sender_uid, sender_email, sender_role, message, read, created_at)
     VALUES ($1, $2, $3, $4, 'subscriber', $5, FALSE, NOW())`,
    [msgId, ticketId, req.user.uid, req.user.email || "", message.slice(0, 4000)],
  );
  await pool.query(`UPDATE tickets SET updated_at = NOW(), last_message = $2 WHERE id = $1`, [ticketId, message.slice(0, 2000)]);
  res.json({ success: true });
}));
