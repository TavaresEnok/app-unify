import type { UserRecord } from "firebase-admin/auth";
import { auth } from "./firebase";
import { AppError } from "./errors";
import type { FunctionRequest } from "../contracts";
import { initialRequesterLookup } from "./authorizationPrelude";

export async function requireRequester(requesterUid: string): Promise<UserRecord> {
  const markBeforeEffect = initialRequesterLookup();
  if (!requesterUid) throw new AppError("unauthenticated", "RequesterUID é obrigatório.");
  try {
    const user = await auth.getUser(requesterUid);
    if (user.disabled) throw new AppError("unauthenticated", "Sessão inválida.");
    return user;
  } catch (error) {
    if (error instanceof AppError) throw error;
    if ((error as { code?: string }).code === "auth/user-not-found") throw new AppError("unauthenticated", "Sessão inválida.");
    const unavailable = new AppError("authorization-unavailable", "Autorização indisponível. Preserve os dados e tente mais tarde.");
    markBeforeEffect(unavailable);
    throw unavailable;
  }
}

export async function requireSession(uid: string, session: FunctionRequest["session"]): Promise<UserRecord> {
  if (!session || !Number.isInteger(session.authTime) || !Number.isInteger(session.issuedAt) ||
      session.authTime <= 0 || session.issuedAt < session.authTime || session.issuedAt > Date.now() / 1000 + 60 ||
      typeof session.role !== "string" || typeof session.providerId !== "string" || typeof session.superAdmin !== "boolean") {
    throw new AppError("unauthenticated", "Atualize o cliente e autentique novamente.");
  }
  const user = await requireRequester(uid);
  const validAfter = user.tokensValidAfterTime ? Date.parse(user.tokensValidAfterTime) / 1000 : 0;
  if (!Number.isFinite(validAfter) || session.authTime < validAfter || session.issuedAt < validAfter) {
    throw new AppError("unauthenticated", "Sessão revogada. Autentique novamente.");
  }
  const claims = user.customClaims || {};
  if (claims.superAdmin === true && ["subscriber", "providerAdmin"].includes(claims.role)) throw new AppError("permission-denied", "Papel inconsistente.");
  if (session.role !== (claims.role || "") || session.providerId !== (claims.providerId || "") ||
      session.superAdmin !== (claims.superAdmin === true)) {
    throw new AppError("permission-denied", "Acesso alterado. Autentique novamente.");
  }
  return user;
}

export function isSuperAdmin(user: UserRecord): boolean {
  return user.customClaims?.superAdmin === true && !["subscriber", "providerAdmin"].includes(user.customClaims?.role);
}

export function requesterProviderId(user: UserRecord): string | undefined {
  const value = user.customClaims?.providerId;
  return typeof value === "string" ? value : undefined;
}

export async function requireSuperAdmin(requesterUid: string): Promise<UserRecord> {
  const user = await requireRequester(requesterUid);
  if (!isSuperAdmin(user)) {
    throw new AppError("permission-denied", "Permissão negada. Apenas Super Admin.");
  }
  return user;
}

export async function requireProviderAccess(
  requesterUid: string,
  providerId: string,
): Promise<UserRecord> {
  const user = await requireRequester(requesterUid);
  if (!isSuperAdmin(user) && (user.customClaims?.role !== "providerAdmin" || requesterProviderId(user) !== providerId)) {
    throw new AppError("permission-denied", "Permissão negada para este provedor.");
  }
  return user;
}
