import rateLimit from "express-rate-limit";

function limiter(windowMs: number, max: number, message: string) {
  return rateLimit({
    windowMs,
    max,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: { message } },
  });
}

export const globalLimiter = limiter(60_000, 200, "Muitas requisições. Tente novamente em 1 minuto.");
export const loginLimiter = limiter(60_000, 10, "Muitas tentativas de login. Tente novamente em 1 minuto.");
export const sgpLimiter = limiter(60_000, 30, "Limite de consultas SGP atingido. Tente novamente em 1 minuto.");
export const apkLimiter = limiter(3_600_000, 5, "Limite de geração de aplicativo atingido. Tente novamente em 1 hora.");
export const tracerouteLimiter = limiter(3_600_000, 40, "Limite de diagnóstico de rota atingido. Tente novamente em 1 hora.");
