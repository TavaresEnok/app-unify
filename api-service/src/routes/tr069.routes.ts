import { Router, type Request } from "express";
import { canAccessProvider, verifyAdmin, verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { tenantLimiter } from "../middlewares/rateLimits";
import { recordAdminAudit } from "../services/auditService";
import { getPgPool } from "../services/postgres";
import {
  getAcsPrivateConfig,
  getTr069Driver,
  resolveCpeIdentityFromPg,
  saveAcsPrivateConfig,
  toPublicAcsSummary,
} from "../services/tr069";
import { isValidTracerouteTarget } from "../validators/traceroute";

const REBOOT_COOLDOWN_MS = 60_000;
const recentReboots = new Map<string, number>();

export function clearRebootCooldownForTests(): void {
  recentReboots.clear();
}

function assertSubscriber(req: Request): { providerId: string; cpfCnpj: string } {
  if (req.user?.role !== "subscriber" || !req.user.providerId || !req.user.cpfCnpj) {
    throw new ApiError(403, "Apenas assinantes podem acessar o roteador por esta rota.", "permission-denied");
  }
  return { providerId: req.user.providerId, cpfCnpj: req.user.cpfCnpj };
}

function resolveAdminProviderId(req: Request): string {
  const requested = typeof req.query?.providerId === "string"
    ? req.query.providerId.trim()
    : typeof req.body?.providerId === "string"
      ? req.body.providerId.trim()
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

function assertFeatureEnabled(enabled: boolean, label: string): void {
  if (!enabled) {
    throw new ApiError(403, `Recurso "${label}" desativado pelo provedor.`, "permission-denied");
  }
}

export const tr069SubscriberRouter = Router();
tr069SubscriberRouter.use(verifyToken, tenantLimiter);

tr069SubscriberRouter.get("/capabilities", asyncRoute(async (req, res) => {
  const { providerId } = assertSubscriber(req);
  const config = await getAcsPrivateConfig(providerId);
  res.json({
    data: {
      enabled: config.enabled && config.driver !== "none",
      driver: config.enabled ? config.driver : "none",
      features: config.enabled ? config.features : {
        wifi: false,
        reboot: false,
        hosts: false,
        guestWifi: false,
        channelOptimize: false,
        speedDiagnostic: false,
      },
    },
  });
}));

tr069SubscriberRouter.get("/status", asyncRoute(async (req, res) => {
  const { providerId, cpfCnpj } = assertSubscriber(req);
  const config = await getAcsPrivateConfig(providerId);
  const driver = getTr069Driver(config);
  const contratoId = typeof req.query.contratoId === "string" ? req.query.contratoId.trim() : undefined;
  const identity = await resolveCpeIdentityFromPg(getPgPool(), providerId, cpfCnpj, {
    contratoId,
    authHeader: req.headers.authorization,
  });
  const overview = await driver.getOverview(config, identity);
  res.json({ data: overview, features: config.features });
}));

tr069SubscriberRouter.get("/hosts", asyncRoute(async (req, res) => {
  const { providerId, cpfCnpj } = assertSubscriber(req);
  const config = await getAcsPrivateConfig(providerId);
  const driver = getTr069Driver(config);
  assertFeatureEnabled(config.features.hosts, "Dispositivos conectados");
  const contratoId = typeof req.query.contratoId === "string" ? req.query.contratoId.trim() : undefined;
  const identity = await resolveCpeIdentityFromPg(getPgPool(), providerId, cpfCnpj, {
    contratoId,
    authHeader: req.headers.authorization,
  });
  const hosts = await driver.listHosts(config, identity);
  res.json({ data: hosts });
}));

tr069SubscriberRouter.post("/wifi", asyncRoute(async (req, res) => {
  const { providerId, cpfCnpj } = assertSubscriber(req);
  const config = await getAcsPrivateConfig(providerId);
  const driver = getTr069Driver(config);
  assertFeatureEnabled(config.features.wifi, "Gerenciamento Wi-Fi");

  const wifiId = typeof req.body?.wifiId === "string" ? req.body.wifiId.trim() : "";
  const ssid = typeof req.body?.ssid === "string" ? req.body.ssid.trim().slice(0, 32) : undefined;
  const password = typeof req.body?.password === "string" ? req.body.password : undefined;
  const enabled = typeof req.body?.enabled === "boolean" ? req.body.enabled : undefined;
  const channel = typeof req.body?.channel === "string" ? req.body.channel.trim().slice(0, 10) : undefined;

  if (!wifiId) throw new ApiError(400, "Identificador da rede Wi-Fi é obrigatório.", "invalid-argument");
  if (password !== undefined && password.length > 0 && (password.length < 8 || password.length > 63)) {
    throw new ApiError(400, "A senha do Wi-Fi deve ter entre 8 e 63 caracteres.", "invalid-argument");
  }
  if (req.body?.isGuest === true) {
    assertFeatureEnabled(config.features.guestWifi, "Rede de visitantes");
  }

  const contratoId = typeof req.body?.contratoId === "string" ? req.body.contratoId.trim() : undefined;
  const identity = await resolveCpeIdentityFromPg(getPgPool(), providerId, cpfCnpj, {
    contratoId,
    authHeader: req.headers.authorization,
  });
  const result = await driver.updateWifi(config, identity, { wifiId, ssid, password, enabled, channel });
  res.json(result);
}));

tr069SubscriberRouter.post("/reboot", asyncRoute(async (req, res) => {
  const { providerId, cpfCnpj } = assertSubscriber(req);
  const config = await getAcsPrivateConfig(providerId);
  const driver = getTr069Driver(config);
  assertFeatureEnabled(config.features.reboot, "Reiniciar roteador");

  const key = `${providerId}:${cpfCnpj}`;
  const last = recentReboots.get(key) || 0;
  if (Date.now() - last < REBOOT_COOLDOWN_MS) {
    throw new ApiError(429, "Aguarde 1 minuto antes de enviar outro comando de reinicialização.", "resource-exhausted");
  }

  const contratoId = typeof req.body?.contratoId === "string" ? req.body.contratoId.trim() : undefined;
  const identity = await resolveCpeIdentityFromPg(getPgPool(), providerId, cpfCnpj, {
    contratoId,
    authHeader: req.headers.authorization,
  });
  const result = await driver.reboot(config, identity);
  recentReboots.set(key, Date.now());
  res.json(result);
}));

tr069SubscriberRouter.post("/optimize-wifi", asyncRoute(async (req, res) => {
  const { providerId, cpfCnpj } = assertSubscriber(req);
  const config = await getAcsPrivateConfig(providerId);
  const driver = getTr069Driver(config);
  assertFeatureEnabled(config.features.channelOptimize, "Otimizar canal Wi-Fi");

  const contratoId = typeof req.body?.contratoId === "string" ? req.body.contratoId.trim() : undefined;
  const identity = await resolveCpeIdentityFromPg(getPgPool(), providerId, cpfCnpj, {
    contratoId,
    authHeader: req.headers.authorization,
  });
  const result = await driver.optimizeWifi(config, identity);
  res.json(result);
}));

tr069SubscriberRouter.post("/diagnostic", asyncRoute(async (req, res) => {
  const { providerId, cpfCnpj } = assertSubscriber(req);
  const config = await getAcsPrivateConfig(providerId);
  const driver = getTr069Driver(config);
  assertFeatureEnabled(config.features.speedDiagnostic, "Diagnóstico no roteador");

  const target = typeof req.body?.target === "string" && req.body.target.trim() ? req.body.target.trim() : "8.8.8.8";
  if (!isValidTracerouteTarget(target)) {
    throw new ApiError(400, "Destino de diagnóstico inválido.", "invalid-argument");
  }
  const contratoId = typeof req.body?.contratoId === "string" ? req.body.contratoId.trim() : undefined;
  const identity = await resolveCpeIdentityFromPg(getPgPool(), providerId, cpfCnpj, {
    contratoId,
    authHeader: req.headers.authorization,
  });
  const result = await driver.runDiagnostic(config, identity, target);
  res.json({ data: result });
}));

// =========================================================================
// ROTAS ADMINISTRATIVAS (Configuração ACS + Atendimento NOC na Ficha do Cliente)
// =========================================================================
export const tr069AdminRouter = Router();
tr069AdminRouter.use(verifyToken, verifyAdmin);
tr069AdminRouter.use((_req, res, next) => {
  res.setHeader("Cache-Control", "private, no-store");
  next();
});

tr069AdminRouter.get("/config", asyncRoute(async (req, res) => {
  const providerId = resolveAdminProviderId(req);
  const config = await getAcsPrivateConfig(providerId);
  res.json({ data: toPublicAcsSummary(config) });
}));

tr069AdminRouter.put("/config", asyncRoute(async (req, res) => {
  if (req.user?.superAdmin !== true) {
    throw new ApiError(403, "Apenas Super Admin pode alterar a integração TR-069/ACS.", "permission-denied");
  }
  const providerId = resolveAdminProviderId(req);
  const saved = await saveAcsPrivateConfig(providerId, req.body || {});
  await recordAdminAudit({
    type: "UPDATE_ACS_INTEGRATION",
    requesterUid: req.user.uid,
    providerId,
    correlationId: req.correlationId,
    payload: { driver: saved.driver, enabled: saved.enabled, url: saved.url, features: saved.features },
  });
  res.json({ success: true, message: "Configuração TR-069/ACS salva com sucesso.", data: toPublicAcsSummary(saved) });
}));

tr069AdminRouter.post("/test", asyncRoute(async (req, res) => {
  if (req.user?.superAdmin !== true) {
    throw new ApiError(403, "Apenas Super Admin pode testar a conexão ACS.", "permission-denied");
  }
  const providerId = resolveAdminProviderId(req);
  const config = await getAcsPrivateConfig(providerId);
  const driver = getTr069Driver(config);
  const result = await driver.testConnection(config);
  res.json({ success: result.ok, data: result });
}));

tr069AdminRouter.get("/clients/:identifier/overview", asyncRoute(async (req, res) => {
  const providerId = resolveAdminProviderId(req);
  const config = await getAcsPrivateConfig(providerId);
  if (!config.enabled || config.driver === "none") {
    res.json({ data: { enabled: false, driver: "none", overview: null, hosts: [] } });
    return;
  }
  const driver = getTr069Driver(config);
  const identifier = String(req.params.identifier || "").trim();
  const identity = await resolveCpeIdentityFromPg(getPgPool(), providerId, identifier, {
    authHeader: req.headers.authorization,
  });
  const [overview, hosts] = await Promise.all([
    driver.getOverview(config, identity),
    config.features.hosts ? driver.listHosts(config, identity).catch(() => []) : Promise.resolve([]),
  ]);
  res.json({ data: { enabled: true, driver: config.driver, features: config.features, overview, hosts } });
}));

tr069AdminRouter.post("/clients/:identifier/reboot", asyncRoute(async (req, res) => {
  const providerId = resolveAdminProviderId(req);
  const config = await getAcsPrivateConfig(providerId);
  const driver = getTr069Driver(config);
  const identifier = String(req.params.identifier || "").trim();
  const identity = await resolveCpeIdentityFromPg(getPgPool(), providerId, identifier, {
    authHeader: req.headers.authorization,
  });
  const result = await driver.reboot(config, identity);
  await recordAdminAudit({
    type: "TR069_ADMIN_REBOOT",
    requesterUid: req.user!.uid,
    providerId,
    correlationId: req.correlationId,
    payload: { identifier, driver: config.driver },
  });
  res.json(result);
}));

tr069AdminRouter.post("/clients/:identifier/optimize-wifi", asyncRoute(async (req, res) => {
  const providerId = resolveAdminProviderId(req);
  const config = await getAcsPrivateConfig(providerId);
  const driver = getTr069Driver(config);
  const identifier = String(req.params.identifier || "").trim();
  const identity = await resolveCpeIdentityFromPg(getPgPool(), providerId, identifier, {
    authHeader: req.headers.authorization,
  });
  const result = await driver.optimizeWifi(config, identity);
  await recordAdminAudit({
    type: "TR069_ADMIN_OPTIMIZE_WIFI",
    requesterUid: req.user!.uid,
    providerId,
    correlationId: req.correlationId,
    payload: { identifier, driver: config.driver },
  });
  res.json(result);
}));

tr069AdminRouter.post("/clients/:identifier/diagnostic", asyncRoute(async (req, res) => {
  const providerId = resolveAdminProviderId(req);
  const config = await getAcsPrivateConfig(providerId);
  const driver = getTr069Driver(config);
  const target = typeof req.body?.target === "string" && req.body.target.trim() ? req.body.target.trim() : "8.8.8.8";
  if (!isValidTracerouteTarget(target)) {
    throw new ApiError(400, "Destino de diagnóstico inválido.", "invalid-argument");
  }
  const identifier = String(req.params.identifier || "").trim();
  const identity = await resolveCpeIdentityFromPg(getPgPool(), providerId, identifier, {
    authHeader: req.headers.authorization,
  });
  const result = await driver.runDiagnostic(config, identity, target);
  await recordAdminAudit({
    type: "TR069_ADMIN_DIAGNOSTIC",
    requesterUid: req.user!.uid,
    providerId,
    correlationId: req.correlationId,
    payload: { identifier, target, driver: config.driver },
  });
  res.json({ data: result });
}));
