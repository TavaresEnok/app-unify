import type { RequestHandler } from "express";
import { firebaseAuth } from "../services/firebaseAdmin";
import { ApiError } from "./errorHandler";

function bearerToken(header: string | undefined): string {
  if (!header?.startsWith("Bearer ")) throw new ApiError(401, "Token não fornecido.", "unauthenticated");
  return header.slice(7).trim();
}

export const verifyToken: RequestHandler = async (req, _res, next) => {
  req.user = undefined;
  try {
    const identity = await firebaseAuth.verifyIdToken(bearerToken(req.headers.authorization), true);
    const current = await firebaseAuth.getUser(identity.uid);
    if (current.disabled) throw new ApiError(401, "Sessão inválida.", "unauthenticated");
    const claims = current.customClaims || {};
    if (claims.superAdmin === true && ["subscriber", "providerAdmin"].includes(claims.role)) throw new ApiError(403, "Papel inconsistente.", "permission-denied");
    if ((identity.role || "") !== (claims.role || "") || (identity.providerId || "") !== (claims.providerId || "") ||
        (identity.superAdmin === true) !== (claims.superAdmin === true)) throw new ApiError(403, "Acesso alterado. Autentique novamente.", "permission-denied");
    // Token proves identity only. Access always comes from the current Auth record.
    req.user = { uid: identity.uid, sub: identity.uid, aud: identity.aud, iss: identity.iss,
      iat: identity.iat, exp: identity.exp, auth_time: identity.auth_time, firebase: identity.firebase,
      role: claims.role, providerId: claims.providerId, cpfCnpj: claims.cpfCnpj, superAdmin: claims.superAdmin === true } as typeof identity;
    next();
  } catch (error) {
    const code = (error as { code?: string }).code;
    const denied = ["auth/id-token-revoked", "auth/id-token-expired", "auth/invalid-id-token", "auth/argument-error", "auth/user-disabled", "auth/user-not-found"].includes(code || "");
    next(error instanceof ApiError ? error : denied
      ? new ApiError(401, "Sessão inválida.", "unauthenticated")
      : new ApiError(503, "Autorização indisponível. Preserve os dados e tente mais tarde.", "authorization-unavailable"));
  }
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
