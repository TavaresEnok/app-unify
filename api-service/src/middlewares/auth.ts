import type { RequestHandler } from "express";
import { requirePgPool } from "../services/postgres";
import { verifyLiveSession } from "../services/self-auth";
import { verifySessionWithLegacy } from "../services/legacy-firebase-auth";
import { ApiError } from "./errorHandler";

// Reuse only within this HTTP request. Never trust a pre-populated req.user or
// cache authorization across requests: revocations and role changes stay live.
const verifiedRequests = new WeakMap<Express.Request, { token: string; user: NonNullable<Express.Request["user"]> }>();

const UNAUTHENTICATED_CODES = new Set([
  "auth/id-token-revoked",
  "auth/id-token-expired",
  "auth/invalid-id-token",
  "auth/argument-error",
  "auth/user-disabled",
  "auth/user-not-found",
]);

function bearerToken(header: string | undefined): string {
  if (!header?.startsWith("Bearer ")) throw new ApiError(401, "Token não fornecido.", "unauthenticated");
  return header.slice(7).trim();
}

export const verifyToken: RequestHandler = async (req, _res, next) => {
  req.user = undefined;
  try {
    const token = bearerToken(req.headers.authorization);
    const verified = verifiedRequests.get(req);
    if (verified?.token === token) {
      req.user = verified.user;
      next();
      return;
    }
    verifiedRequests.delete(req);
    const identity = await verifySessionWithLegacy(requirePgPool(), token, verifyLiveSession);
    if (identity.superAdmin === true && ["subscriber", "providerAdmin"].includes(identity.role)) {
      throw new ApiError(403, "Papel inconsistente.", "permission-denied");
    }
    req.user = { ...identity } as unknown as NonNullable<Express.Request["user"]>;
    verifiedRequests.set(req, { token, user: Object.freeze(req.user) });
    next();
  } catch (error) {
    if (error instanceof ApiError) {
      next(error);
      return;
    }
    const code = (error as { code?: string })?.code || "";
    if (code === "access/scope-changed" || code === "access/identity-conflict") {
      next(new ApiError(403, "Acesso alterado. Autentique novamente.", "permission-denied"));
      return;
    }
    if (UNAUTHENTICATED_CODES.has(code)) {
      next(new ApiError(401, "Sessão inválida.", "unauthenticated"));
      return;
    }
    next(new ApiError(503, "Autorização indisponível. Preserve os dados e tente mais tarde.", "authorization-unavailable"));
  }
};

// Long-running/private operations must recheck authority immediately before
// committing or releasing bytes, even though ingress already verified the token.
export const verifyFreshToken: RequestHandler = (req, res, next) => {
  verifiedRequests.delete(req);
  return verifyToken(req, res, next);
};

export const authenticateIfPresent: RequestHandler = (req, res, next) => {
  if (req.headers.authorization) return verifyToken(req, res, next);
  next();
};

export const verifyAdmin: RequestHandler = (req, _res, next) => {
  if (req.user?.superAdmin !== true && req.user?.role !== "providerAdmin") {
    return next(new ApiError(403, "Acesso administrativo obrigatório.", "permission-denied"));
  }
  next();
};

export const verifySuperAdmin: RequestHandler[] = [
  verifyToken,
  (req, _res, next) => {
    if (req.user?.superAdmin !== true) return next(new ApiError(403, "Apenas Super Admin pode executar esta operação.", "permission-denied"));
    next();
  },
];

export function canAccessProvider(req: Express.Request, providerId: string): boolean {
  return req.user?.superAdmin === true || (req.user?.role === "providerAdmin" && req.user?.providerId === providerId);
}

// Ações sensíveis exigem login recente (últimos 5 min). O painel reconhece o
// código "reauth-required", pede a senha (POST /admin/auth/reauthenticate) e
// repete a ação; não é sessão expirada e não deve deslogar.
export const REAUTH_WINDOW_SECONDS = 300;
export function requireRecentLogin(req: Express.Request): void {
  const authTime = Number(req.user?.auth_time || 0);
  if (!Number.isFinite(authTime) || Date.now() / 1000 - authTime > REAUTH_WINDOW_SECONDS) {
    throw new ApiError(401, "Confirme sua senha para continuar.", "reauth-required");
  }
}
