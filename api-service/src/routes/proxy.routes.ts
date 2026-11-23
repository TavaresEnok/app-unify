import { Router } from "express";
import { verifyToken } from "../middlewares/auth";
import { asyncRoute } from "../middlewares/errorHandler";
import { sgpLimiter, tenantLimiter, subscriberLoginLimiter } from "../middlewares/rateLimits";
import { proxyToSgp } from "../services/proxySgpClient";
import { assertCpfInTenant } from "../services/tenantScope";

export const proxyRouter = Router();

// Login histórico do assinante: CPF/CNPJ + provedor, sem senha. O proxy-sgp
// valida o contrato e emite a sessão; este endpoint público limita tentativas.
proxyRouter.post("/check-cpf", subscriberLoginLimiter, asyncRoute(async (req, res) => {
  const result = await proxyToSgp("/check-cpf", req.body);
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
    const result = await proxyToSgp(path, req.body, req.headers.authorization);
    res.status(result.status).json(result.data);
  }));
}
