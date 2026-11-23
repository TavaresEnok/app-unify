import { Router, type Request } from "express";
import { canAccessProvider, verifyAdmin, verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { firestore, messaging } from "../services/firebaseAdmin";
import { getPgPool } from "../services/postgres";
import {
  importLegacyTokensFromFirestore,
  listCampaignHistory,
  listSegmentOptions,
  previewAudience,
  projectSegmentsFromSgpClients,
  sendCampaign,
  type SegmentFilters,
} from "../services/notificationCampaigns";

export const notificationsRouter = Router();
notificationsRouter.use(verifyToken, verifyAdmin);

function requireDatabase() {
  const pool = getPgPool();
  if (!pool) {
    throw new ApiError(503, "Banco de dados de segmentação indisponível.", "service-unavailable");
  }
  return pool;
}

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

function parseQueryList(value: unknown): string[] | undefined {
  if (typeof value === "string" && value.trim()) {
    return value.split(",").map((s) => s.trim()).filter(Boolean);
  }
  if (Array.isArray(value)) {
    return value.flatMap((v) => (typeof v === "string" ? v.split(",") : [])).map((s) => s.trim()).filter(Boolean);
  }
  return undefined;
}

notificationsRouter.get("/segments", asyncRoute(async (req, res) => {
  const providerId = resolveProviderId(req);
  const pool = requireDatabase();
  const contextFilters: SegmentFilters = {
    oltNames: parseQueryList(req.query.olt),
    ponKeys: parseQueryList(req.query.pon),
    cidades: parseQueryList(req.query.cidade),
    bairros: parseQueryList(req.query.bairro),
  };
  const data = await listSegmentOptions(pool, providerId, contextFilters);
  res.json({ data });
}));

notificationsRouter.post("/preview", asyncRoute(async (req, res) => {
  const providerId = resolveProviderId(req);
  const pool = requireDatabase();
  const data = await previewAudience(pool, providerId, req.body?.filters);
  res.json({ data });
}));

notificationsRouter.post("/send", asyncRoute(async (req, res) => {
  const providerId = resolveProviderId(req);
  const pool = requireDatabase();
  const title = typeof req.body?.title === "string" ? req.body.title.trim() : "";
  const body = typeof req.body?.body === "string" ? req.body.body.trim() : "";
  if (!title || !body) {
    throw new ApiError(400, "Título e mensagem são obrigatórios.", "invalid-argument");
  }

  const campaign = await sendCampaign(pool, messaging, {
    providerId,
    title,
    body,
    category: typeof req.body?.category === "string" ? req.body.category : "info",
    route: typeof req.body?.route === "string" ? req.body.route : "",
    filters: req.body?.filters,
    sentBy: req.user?.uid || "admin",
  });

  const message = campaign.deliveryMode === "topic"
    ? "Notificação enviada para todos os assinantes do aplicativo."
    : campaign.targetedDevices === 0
      ? `Campanha registrada (${campaign.matchedSubscribers} assinante(s) no segmento, nenhum aparelho com push ativo no momento — visível no aplicativo ao abrir).`
      : `Notificação enviada: ${campaign.successCount} entrega(s) aceita(s), ${campaign.failureCount} falha(s) (${campaign.matchedSubscribers} assinante(s) no segmento).`;

  res.status(201).json({ success: true, message, data: campaign });
}));

notificationsRouter.get("/history", asyncRoute(async (req, res) => {
  const providerId = resolveProviderId(req);
  const pool = requireDatabase();
  const limit = Number(req.query.limit || 25);
  const data = await listCampaignHistory(pool, providerId, limit);
  res.json({ data });
}));

notificationsRouter.post("/sync-segments", asyncRoute(async (req, res) => {
  const providerId = resolveProviderId(req);
  const pool = requireDatabase();
  const projected = await projectSegmentsFromSgpClients(pool, providerId);
  let importedTokens = 0;
  if (req.body?.importLegacyTokens === true) {
    importedTokens = await importLegacyTokensFromFirestore(pool, firestore, providerId);
  }
  const options = await listSegmentOptions(pool, providerId);
  res.json({
    success: true,
    message: importedTokens > 0
      ? `Segmentos atualizados (${projected} registro(s)) e ${importedTokens} token(s) importado(s).`
      : `Segmentos atualizados (${projected} registro(s) indexados a partir do cache SGP).`,
    data: { projected, importedTokens, totals: options.totals },
  });
}));

