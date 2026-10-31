import type { UserRecord } from "firebase-admin/auth";
import { auth } from "./firebase";
import { AppError } from "./errors";

export async function requireRequester(requesterUid: string): Promise<UserRecord> {
  if (!requesterUid) throw new AppError("unauthenticated", "RequesterUID é obrigatório.");
  try {
    const user = await auth.getUser(requesterUid);
    if (user.disabled) throw new Error("disabled");
    return user;
  } catch {
    throw new AppError("unauthenticated", "Utilizador não encontrado.");
  }
}

export function isSuperAdmin(user: UserRecord): boolean {
  return user.customClaims?.superAdmin === true;
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
