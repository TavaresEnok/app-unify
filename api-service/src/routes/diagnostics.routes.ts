import { spawn } from "node:child_process";
import { Router } from "express";
import { verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { sgpLimiter, tracerouteLimiter } from "../middlewares/rateLimits";
import { proxyToSgp } from "../services/proxySgpClient";
import { isValidTracerouteTarget, normalizeMaxHops, parseTracerouteOutput } from "../validators/traceroute";

export const diagnosticsRouter = Router();
diagnosticsRouter.use(verifyToken);

diagnosticsRouter.post("/onu-signal", sgpLimiter, asyncRoute(async (req, res) => {
  const cpfCnpj = typeof req.body?.cpfCnpj === "string" ? req.body.cpfCnpj.trim() : "";
  if (!cpfCnpj) throw new ApiError(400, "CPF/CNPJ é obrigatório.", "invalid-argument");
  const result = await proxyToSgp("/diagnostic/onu-signal", req.body, req.headers.authorization);
  res.status(result.status).json(result.data);
}));

diagnosticsRouter.post("/traceroute", tracerouteLimiter, asyncRoute(async (req, res) => {
  const target = typeof req.body?.target === "string" ? req.body.target.trim() : "8.8.8.8";
  const maxHops = normalizeMaxHops(req.body?.maxHops);
  if (!isValidTracerouteTarget(target)) throw new ApiError(400, "Destino de traceroute inválido ou não permitido.", "invalid-argument");
  const stdout = await new Promise<string>((resolve, reject) => {
    const chunks: Buffer[] = [];
    const process = spawn("traceroute", ["-n", "-m", String(maxHops), "-w", "2", target], { stdio: ["ignore", "pipe", "ignore"] });
    const timeout = setTimeout(() => { process.kill("SIGKILL"); reject(new ApiError(504, "Traceroute excedeu o tempo limite.", "timeout")); }, 30_000);
    process.stdout.on("data", (chunk: Buffer) => chunks.push(chunk));
    process.on("error", (error) => { clearTimeout(timeout); reject(error); });
    process.on("close", () => { clearTimeout(timeout); resolve(Buffer.concat(chunks).toString("utf8")); });
  });
  res.json({ data: { target, hops: parseTracerouteOutput(stdout), raw: stdout } });
}));
