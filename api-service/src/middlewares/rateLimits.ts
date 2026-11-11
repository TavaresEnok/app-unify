import { createHash } from "node:crypto";
import rateLimit, { ipKeyGenerator } from "express-rate-limit";
import { RedisStore, type RedisReply } from "rate-limit-redis";
import type { Request } from "express";
import { redis } from "../services/redis";

export function requestIdentity(req: Request): string {
  return req.user?.uid ? `user:${req.user.providerId || "global"}:${req.user.uid}` : `ip:${ipKeyGenerator(req.ip || "unknown")}`;
}

function limiter(name: string, windowMs: number, max: number, keyGenerator = requestIdentity) {
  return rateLimit({
    windowMs, max, keyGenerator,
    standardHeaders: true, legacyHeaders: false,
    ...(redis ? { store: new RedisStore({
      prefix: `api:rl:${name}:`,
      sendCommand: (command: string, ...args: string[]) => redis!.call(command, ...args) as Promise<RedisReply>,
    }) } : {}),
    message: { error: { message: "Limite de requisições atingido. Aguarde e tente novamente.", code: "resource-exhausted" } },
  });
}

// Proteção ampla de entrada; cotas de operações autenticadas são por usuário.
export const globalLimiter = limiter("ingress", 60_000, 3000);
export const loginLimiter = limiter("admin-login", 60_000, 20);
export const subscriberLoginLimiter = limiter("subscriber-login", 60_000, 10, (req) => {
  const identity = `${req.body?.providerId || ""}:${String(req.body?.cpf || "").replace(/\D/g, "")}`;
  return createHash("sha256").update(identity).digest("hex");
});
export const sgpLimiter = limiter("sgp-user", 60_000, 120);
export const tenantLimiter = limiter("sgp-tenant", 60_000, 3000,
  (req) => req.user?.providerId ? `tenant:${req.user.providerId}` : requestIdentity(req));
export const tracerouteLimiter = limiter("traceroute", 3_600_000, 40);
// Config pública do app (sem login). Assinantes de ISP costumam compartilhar
// IP via CGNAT, então a cota por IP é larga; o cache em memória poupa o Firestore.
export const publicConfigLimiter = limiter("public-config", 60_000, 600);
