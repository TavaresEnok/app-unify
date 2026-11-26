import { Router } from "express";
import { verifyToken } from "../middlewares/auth";
import { asyncRoute } from "../middlewares/errorHandler";
import { sgpLimiter, tenantLimiter, subscriberLoginLimiter, subscriberLoginIpLimiter } from "../middlewares/rateLimits";
import { ApiError } from "../middlewares/errorHandler";
import { proxyBoletoPdf, proxyToSgp } from "../services/proxySgpClient";
import { assertCpfInTenant } from "../services/tenantScope";

export const proxyRouter = Router();

// Login histórico do assinante: CPF/CNPJ + provedor, sem senha. O proxy-sgp
// valida o contrato e emite a sessão; este endpoint público limita tentativas.
proxyRouter.post("/check-cpf", subscriberLoginIpLimiter, subscriberLoginLimiter, asyncRoute(async (req, res) => {
  const providerId = typeof req.body?.providerId === "string" ? req.body.providerId.trim() : "";
  const cpf = typeof req.body?.cpf === "string" ? req.body.cpf.replace(/\D/g, "") : "";
  if (!providerId) throw new ApiError(401, "CPF/CNPJ e provedor são obrigatórios. Atualize o aplicativo.", "unauthenticated");
  if (!/^[a-z0-9_-]{1,64}$/i.test(providerId) || !/^\d{11}(\d{3})?$/.test(cpf)) {
    throw new ApiError(401, "Credenciais inválidas.", "unauthenticated");
  }
  const result = await proxyToSgp("/check-cpf", { ...req.body, providerId, cpf }, undefined, req.ip);
  res.status(result.status).json(result.data);
}));

// Rotas que operam sobre um CPF: além do token, o CPF alvo precisa pertencer ao
// tenant do chamador (M1) — impede um admin do provedor A ler/alterar dados
// (inclusive Wi-Fi) de assinantes do provedor B.
for (const path of [
  "/get-invoices",
  "/get-consumption-data",
  "/unlock-trust",
  "/cpe/wifi/update",
  "/cpe/wifi/list",
] as const) {
  proxyRouter.post(path, verifyToken, sgpLimiter, tenantLimiter, asyncRoute(async (req, res) => {
    await assertCpfInTenant(req);
    const result = await proxyToSgp(path, req.body, req.headers.authorization, req.ip);
    res.status(result.status).json(result.data);
  }));
}

// Boleto em PDF de uma fatura em aberto (o app abre/compartilha o arquivo).
// O assinante só pede o próprio boleto; o proxy confere no ERP que a fatura é
// do CPF da sessão, limita a cota e guarda o PDF por alguns minutos.
proxyRouter.get("/subscriber/invoices/:id/boleto", verifyToken, sgpLimiter, tenantLimiter, asyncRoute(async (req, res) => {
  const faturaId = String(req.params.id || "").trim();
  if (!/^\d{1,12}$/.test(faturaId)) throw new ApiError(400, "Fatura inválida.", "invalid-argument");
  const contrato = typeof req.query.contratoId === "string" ? req.query.contratoId.trim() : "";
  if (contrato && !/^\d{1,12}$/.test(contrato)) throw new ApiError(400, "Contrato inválido.", "invalid-argument");
  const user = req.user;
  const cpfCnpj = user?.role === "subscriber" && typeof user.cpfCnpj === "string"
    ? user.cpfCnpj
    : typeof req.query.cpfCnpj === "string" ? req.query.cpfCnpj.replace(/\D/g, "") : "";
  const providerId = user?.superAdmin === true && typeof req.query.providerId === "string"
    ? req.query.providerId
    : user?.providerId;
  const body: Record<string, unknown> = { cpfCnpj, ...(providerId ? { providerId } : {}), faturaId, ...(contrato ? { contratoId: contrato } : {}) };
  req.body = body;
  await assertCpfInTenant(req);
  const pdf = await proxyBoletoPdf(body, req.headers.authorization, req.ip);
  res.set({
    "Content-Type": "application/pdf",
    "Content-Length": String(pdf.length),
    "Content-Disposition": `inline; filename="boleto-${faturaId}.pdf"`,
    "Cache-Control": "private, no-store",
    "X-Content-Type-Options": "nosniff",
  });
  res.status(200).end(pdf);
}));
