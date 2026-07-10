import { FieldValue } from "firebase-admin/firestore";
import type { RequestHandler } from "../app/request";
import { AppError } from "../app/errors";
import { auth, db } from "../app/firebase";
import { requireSuperAdmin } from "../app/permissions";

function validatePassword(password: string): void {
  if (password.length < 12 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) ||
    !/[0-9]/.test(password) || !/[^A-Za-z0-9]/.test(password)) {
    throw new AppError("invalid-argument", "A senha não atende à política de segurança.");
  }
}

export const listAdminUsers: RequestHandler<"LIST_ADMIN_USERS"> = async ({ requesterUid }) => {
  await requireSuperAdmin(requesterUid);
  const result = await auth.listUsers(1000);
  return result.users
    .filter((user) => user.customClaims?.superAdmin || user.customClaims?.providerId)
    .map((user) => ({
      uid: user.uid,
      email: user.email,
      superAdmin: user.customClaims?.superAdmin === true,
      providerId: typeof user.customClaims?.providerId === "string" ? user.customClaims.providerId : undefined,
    }));
};

export const createAdminUser: RequestHandler<"CREATE_ADMIN_USER"> = async ({ requestId, requesterUid, payload }) => {
  await requireSuperAdmin(requesterUid);
  const email = payload.email.trim().toLowerCase();
  if (!email.includes("@")) throw new AppError("invalid-argument", "Email inválido.");
  validatePassword(payload.password);
  if (payload.role === "providerAdmin" && !payload.providerId) {
    throw new AppError("invalid-argument", "O provedor é obrigatório para este perfil.");
  }

  try {
    const existing = await auth.getUserByEmail(email);
    const metadata = await db.collection("users").doc(existing.uid).get();
    if (metadata.data()?.createdByRequestId === requestId) {
      return { success: true, message: "Utilizador criado com sucesso.", uid: existing.uid };
    }
    throw new AppError("conflict", "Já existe um utilizador com este email.");
  } catch (error) {
    if (error instanceof AppError) throw error;
    const code = (error as { code?: string }).code;
    if (code !== "auth/user-not-found") throw error;
  }

  const user = await auth.createUser({ email, password: payload.password, emailVerified: false });
  try {
    const claims = payload.role === "superAdmin"
      ? { superAdmin: true, role: "superAdmin" }
      : { providerId: payload.providerId, role: "providerAdmin" };
    await auth.setCustomUserClaims(user.uid, claims);
    await db.collection("users").doc(user.uid).set({
      email,
      ...claims,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: requesterUid,
      createdByRequestId: requestId,
    });
  } catch (error) {
    await auth.deleteUser(user.uid).catch(() => undefined);
    throw error;
  }
  return { success: true, message: "Utilizador criado com sucesso.", uid: user.uid };
};

export const deleteAdminUser: RequestHandler<"DELETE_ADMIN_USER"> = async ({ requesterUid, payload }) => {
  await requireSuperAdmin(requesterUid);
  if (requesterUid === payload.uid) throw new AppError("invalid-argument", "Você não pode apagar sua própria conta.");
  await Promise.all([
    auth.deleteUser(payload.uid).catch((error: { code?: string }) => {
      if (error.code !== "auth/user-not-found") throw error;
    }),
    db.collection("users").doc(payload.uid).delete(),
  ]);
  return { success: true, message: "Utilizador apagado." };
};

export const setSuperAdminByEmail: RequestHandler<"SET_SUPER_ADMIN_BY_EMAIL"> = async ({ requesterUid, payload }) => {
  await requireSuperAdmin(requesterUid);
  let target;
  try {
    target = await auth.getUserByEmail(payload.email.trim().toLowerCase());
  } catch {
    throw new AppError("not-found", "Utilizador não encontrado.");
  }
  await auth.setCustomUserClaims(target.uid, {
    ...(target.customClaims || {}),
    superAdmin: true,
    role: "superAdmin",
  });
  await db.collection("users").doc(target.uid).set({
    email: target.email,
    superAdmin: true,
    role: "superAdmin",
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return { success: true, message: "Permissão de Super Admin concedida.", uid: target.uid };
};
