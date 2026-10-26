import type { RequestHandler } from "express";
import { firebaseAuth } from "../services/firebaseAdmin";
import { ApiError } from "./errorHandler";

function bearerToken(header: string | undefined): string {
  if (!header?.startsWith("Bearer ")) throw new ApiError(401, "Token não fornecido.", "unauthenticated");
  return header.slice(7).trim();
}

export const verifyToken: RequestHandler = async (req, _res, next) => {
  try {
    req.user = await firebaseAuth.verifyIdToken(bearerToken(req.headers.authorization));
    next();
  } catch (error) {
    next(error instanceof ApiError ? error : new ApiError(403, "Token inválido.", "permission-denied"));
  }
};

export const verifySuperAdmin: RequestHandler[] = [
  verifyToken,
  (req, _res, next) => {
    if (req.user?.superAdmin !== true) return next(new ApiError(403, "Apenas Super Admin pode executar esta operação.", "permission-denied"));
    next();
  },
];

export function canAccessProvider(req: Express.Request, providerId: string): boolean {
  return req.user?.superAdmin === true || req.user?.providerId === providerId;
}
