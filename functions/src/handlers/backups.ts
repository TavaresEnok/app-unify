import { FieldValue } from "firebase-admin/firestore";
import type { RequestHandler } from "../app/request";
import { requirePayloadFields } from "../app/request";
import { AppError } from "../app/errors";
import { db } from "../app/firebase";
import { sanitizePersonalization, restoredPersonalization } from "../app/providerConfig";
import { requireProviderAccess } from "../app/permissions";

function requireBackupId(value: unknown): asserts value is string {
  if (typeof value !== "string" || !value.trim() || value.includes("/") || value === "." || value === "..") {
    throw new AppError("invalid-argument", "ID de backup inválido.");
  }
}

export const backupProviderConfig: RequestHandler<"BACKUP_PROVIDER_CONFIG"> = async ({ requestId, requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  requirePayloadFields(payload, ["providerId", "name"]);
  if (payload.name !== undefined && typeof payload.name !== "string") {
    throw new AppError("invalid-argument", "Nome de backup inválido.");
  }
  const providerRef = db.collection("provedores").doc(payload.providerId);
  const provider = await providerRef.get();
  if (!provider.exists) throw new AppError("not-found", "Provedor não encontrado.");
  const backupRef = providerRef.collection("backups").doc(requestId);
  await backupRef.set({
    name: payload.name?.trim() || `Backup ${new Date().toISOString()}`,
    schemaVersion: 1,
    providerData: sanitizePersonalization(provider.data()),
    createdBy: requesterUid,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { success: true, message: "Backup criado.", backupId: backupRef.id };
};

export const listProviderBackups: RequestHandler<"LIST_PROVIDER_BACKUPS"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  requirePayloadFields(payload, ["providerId"]);
  const snapshot = await db.collection("provedores").doc(payload.providerId)
    .collection("backups").orderBy("createdAt", "desc").get();
  return snapshot.docs.map((backup) => {
    const data = backup.data();
    return {
      id: backup.id,
      name: typeof data.name === "string" ? data.name : "",
      createdAt: typeof data.createdAt?.toDate === "function" ? data.createdAt.toDate().toISOString()
        : typeof data.createdAt === "string" ? data.createdAt : null,
      createdBy: typeof data.createdBy === "string" ? data.createdBy : "",
    };
  });
};

export const restoreProviderConfig: RequestHandler<"RESTORE_PROVIDER_CONFIG"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  requirePayloadFields(payload, ["providerId", "backupId"]);
  requireBackupId(payload.backupId);
  const providerRef = db.collection("provedores").doc(payload.providerId);
  const backup = await providerRef.collection("backups").doc(payload.backupId).get();
  if (!backup.exists) throw new AppError("not-found", "Backup não encontrado.");
  const data = backup.data() || {};
  if (!data.providerData || typeof data.providerData !== "object" || Array.isArray(data.providerData)
      || (data.schemaVersion !== undefined && data.schemaVersion !== 1)) {
    throw new AppError("invalid-argument", "Backup inválido.");
  }
  // Transaction preserves concurrent integration/native/admin changes.
  await db.runTransaction(async transaction => {
    const current = await transaction.get(providerRef);
    if (!current.exists) throw new AppError("not-found", "Provedor não encontrado.");
    transaction.set(providerRef, {
      ...restoredPersonalization(current.data() || {}, data.providerData),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  return { success: true, message: "Backup restaurado." };
};

export const deleteProviderBackup: RequestHandler<"DELETE_PROVIDER_BACKUP"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  requirePayloadFields(payload, ["providerId", "backupId"]);
  requireBackupId(payload.backupId);
  await db.collection("provedores").doc(payload.providerId).collection("backups").doc(payload.backupId).delete();
  return { success: true, message: "Backup apagado." };
};
