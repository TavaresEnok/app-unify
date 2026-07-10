import { Router } from "express";
import { verifyToken } from "../middlewares/auth";
import { asyncRoute } from "../middlewares/errorHandler";
import { sgpLimiter } from "../middlewares/rateLimits";
import { proxyToSgp } from "../services/proxySgpClient";

export const proxyRouter = Router();

proxyRouter.post("/check-cpf", sgpLimiter, asyncRoute(async (req, res) => {
  const result = await proxyToSgp("/check-cpf", req.body);
  res.status(result.status).json(result.data);
}));

for (const path of ["/get-invoices", "/get-consumption-data", "/unlock-trust", "/cpe/wifi/update"] as const) {
  proxyRouter.post(path, sgpLimiter, verifyToken, asyncRoute(async (req, res) => {
    const result = await proxyToSgp(path, req.body, req.headers.authorization);
    res.status(result.status).json(result.data);
  }));
}

proxyRouter.post("/cpe/wifi/list", sgpLimiter, verifyToken, asyncRoute(async (req, res) => {
  const result = await proxyToSgp("/cpe/wifi/list", req.body, req.headers.authorization);
  res.status(result.status).json(result.data);
}));
