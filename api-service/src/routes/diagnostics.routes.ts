import { redis } from "../services/redis";
import { createUpstream } from "../services/upstream-runtime";
import { executeTraceroute } from "../services/traceroute";
import { Router, type Request } from "express";
import { canAccessProvider, verifyAdmin, verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { sgpLimiter, tenantLimiter, tracerouteLimiter } from "../middlewares/rateLimits";
import { proxyToSgp } from "../services/proxySgpClient";
import { assertCpfInTenant } from "../services/tenantScope";
import { getPgPool } from "../services/postgres";
import {
  deleteDiagnosticResult,
  detectOutageClusters,
  listDiagnosticResults,
  saveDiagnosticResult,
} from "../services/diagnosticResults";
import { isValidTracerouteTarget, normalizeMaxHops, parseTracerouteOutput, resolveSafeTracerouteTarget } from "../validators/traceroute";

const diagnosticSlots = createUpstream({ getRedis: () => redis, maxPerProvider: 2, maxPerHost: 4 });
export const diagnosticsRouter = Router();
diagnosticsRouter.use(verifyToken);

diagnosticsRouter.post("/onu-signal", sgpLimiter, tenantLimiter, asyncRoute(async (req, res) => {
  const cpfCnpj = typeof req.body?.cpfCnpj === "string" ? req.body.cpfCnpj.trim() : "";
  if (!cpfCnpj) throw new ApiError(400, "CPF/CNPJ é obrigatório.", "invalid-argument");
  await assertCpfInTenant(req);
  const result = await proxyToSgp("/diagnostic/onu-signal", req.body, req.headers.authorization);
  res.status(result.status).json(result.data);
}));

diagnosticsRouter.post("/traceroute", tracerouteLimiter, asyncRoute(async (req, res) => {
  const target = typeof req.body?.target === "string" ? req.body.target.trim() : "8.8.8.8";
  const maxHops = normalizeMaxHops(req.body?.maxHops);
  if (!isValidTracerouteTarget(target)) throw new ApiError(400, "Destino de traceroute inválido ou não permitido.", "invalid-argument");
  // Revalida pós-DNS e fixa o IP público resolvido, impedindo SSRF/DNS-rebinding
  // para faixas internas via hostname.
  let safeTarget: string;
  try {
    safeTarget = await resolveSafeTracerouteTarget(target);
  } catch {
    throw new ApiError(400, "Destino de traceroute inválido ou não permitido.", "invalid-argument");
  }
  const result = await diagnosticSlots.execute({ providerId: String(req.user?.providerId || req.user?.uid), url: "https://diagnostics.local/traceroute", body: { target: safeTarget } }, () => executeTraceroute(safeTarget, maxHops)).catch((error) => {
    if (error.status === 503) throw new ApiError(503, "Diagnóstico ocupado. Tente novamente em instantes.", "unavailable");
    throw error;
  });
  const hops = parseTracerouteOutput(result.raw);
  res.json({ data: { target, resolvedTarget: safeTarget, origin: "server", hops,
    reached: hops.some((hop) => hop.ip === safeTarget), timedOut: result.timedOut, raw: result.raw } });
}));

diagnosticsRouter.post("/results", tenantLimiter, asyncRoute(async (req, res) => {
  const user = req.user;
  if (user?.role !== "subscriber" || !user.providerId || !user.cpfCnpj) {
    throw new ApiError(403, "Apenas assinantes podem registrar diagnóstico.", "permission-denied");
  }
  const verdict = typeof req.body?.verdict === "string" ? req.body.verdict.trim() : "";
  if (!verdict) {
    throw new ApiError(400, "Veredito do diagnóstico é obrigatório.", "invalid-argument");
  }
  const pool = getPgPool();
  if (!pool) {
    res.status(200).json({ success: false, stored: false });
    return;
  }
  const saved = await saveDiagnosticResult(pool, {
    providerId: user.providerId,
    cpfCnpj: user.cpfCnpj,
    createdByUid: user.uid,
    contratoId: typeof req.body?.contratoId === "string" ? req.body.contratoId : "",
    clientName: typeof req.body?.clientName === "string" ? req.body.clientName : "",
    planName: typeof req.body?.planName === "string" ? req.body.planName : "",
    mode: typeof req.body?.mode === "string" ? req.body.mode : "quick",
    verdict,
    verdictHeadline: typeof req.body?.verdictHeadline === "string" ? req.body.verdictHeadline : "",
    cause: typeof req.body?.cause === "string" ? req.body.cause : "",
    summary: req.body?.summary && typeof req.body.summary === "object" ? req.body.summary : {},
  });
  res.status(201).json({ success: true, stored: true, data: saved });
}));

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

export const adminDiagnosticsRouter = Router();
adminDiagnosticsRouter.use(verifyToken, verifyAdmin);

adminDiagnosticsRouter.get("/", asyncRoute(async (req, res) => {
  const providerId = resolveAdminProviderId(req);
  const pool = getPgPool();
  if (!pool) {
    res.json({ data: [] });
    return;
  }
  const limit = Number(req.query.limit || 100);
  const data = await listDiagnosticResults(pool, providerId, limit);
  res.json({ data });
}));

adminDiagnosticsRouter.get("/outage-radar", asyncRoute(async (req, res) => {
  const providerId = resolveAdminProviderId(req);
  const pool = getPgPool();
  if (!pool) {
    res.json({ data: [] });
    return;
  }
  const windowMinutes = req.query.windowMinutes ? Number(req.query.windowMinutes) : 45;
  const minSubscribers = req.query.minSubscribers ? Number(req.query.minSubscribers) : 3;
  const data = await detectOutageClusters(pool, providerId, { windowMinutes, minSubscribers });
  res.json({ data, windowMinutes, minSubscribers });
}));

adminDiagnosticsRouter.delete("/:id", asyncRoute(async (req, res) => {
  const providerId = resolveAdminProviderId(req);
  const id = String(req.params.id || "").trim();
  if (!id || id.length > 80) {
    throw new ApiError(400, "Identificador do diagnóstico inválido.", "invalid-argument");
  }
  const pool = getPgPool();
  if (!pool) {
    throw new ApiError(503, "Banco de diagnósticos indisponível.", "service-unavailable");
  }
  const deleted = await deleteDiagnosticResult(pool, providerId, id);
  if (!deleted) {
    throw new ApiError(404, "Diagnóstico não encontrado.", "not-found");
  }
  res.json({ success: true });
}));
