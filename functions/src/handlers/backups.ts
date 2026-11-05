import { FieldValue } from "firebase-admin/firestore";
import type { RequestHandler } from "../app/request";
import { AppError } from "../app/errors";
import { db } from "../app/firebase";
import { requireProviderAccess } from "../app/permissions";
import { publicProviderData } from "../app/publicProviderData";

export const backupProviderConfig: RequestHandler<"BACKUP_PROVIDER_CONFIG"> = async ({ requestId, requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  const providerRef = db.collection("provedores").doc(payload.providerId);
  const provider = await providerRef.get();
  if (!provider.exists) throw new AppError("not-found", "Provedor não encontrado.");
  const backupRef = providerRef.collection("backups").doc(requestId);
  await backupRef.set({
    name: payload.name?.trim() || `Backup ${new Date().toISOString()}`,
    providerData: publicProviderData(provider.data() || {}),
    createdBy: requesterUid,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { success: true, message: "Backup criado.", backupId: backupRef.id };
};

export const listProviderBackups: RequestHandler<"LIST_PROVIDER_BACKUPS"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  const snapshot = await db.collection("provedores").doc(payload.providerId)
    .collection("backups").orderBy("createdAt", "desc").get();
  return snapshot.docs.map((backup) => {
    const data = backup.data();
    return { id: backup.id, name: data.name, createdAt: data.createdAt, createdBy: data.createdBy };
  });
};

export const restoreProviderConfig: RequestHandler<"RESTORE_PROVIDER_CONFIG"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  const providerRef = db.collection("provedores").doc(payload.providerId);
  const backup = await providerRef.collection("backups").doc(payload.backupId).get();
  if (!backup.exists) throw new AppError("not-found", "Backup não encontrado.");
  const data = backup.data() || {};
  if (!data.providerData || typeof data.providerData !== "object") {
    throw new AppError("invalid-argument", "Backup inválido.");
  }
  const restored = publicProviderData(data.providerData as Record<string, unknown>);
  // Destinos legados ainda são usados pelo SGP; a personalização não pode
  // redirecionar chamadas autenticadas usando um backup antigo ou adulterado.
  delete restored.sgpBaseUrl;
  delete restored.appName;
  if (restored.details && typeof restored.details === "object" && !Array.isArray(restored.details)) {
    const details = { ...restored.details as Record<string, unknown> };
    delete details.systemUrl;
    delete details.appName;
    if (Object.keys(details).length) restored.details = details;
    else delete restored.details;
  } else delete restored.details;
  const batch = db.batch();
  batch.set(providerRef, {
    ...restored,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  await batch.commit();
  return { success: true, message: "Backup restaurado." };
};

export const deleteProviderBackup: RequestHandler<"DELETE_PROVIDER_BACKUP"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  await db.collection("provedores").doc(payload.providerId).collection("backups").doc(payload.backupId).delete();
  return { success: true, message: "Backup apagado." };
};
