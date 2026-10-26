import { FieldValue } from "firebase-admin/firestore";
import type { RequestHandler } from "../app/request";
import { AppError } from "../app/errors";
import { db } from "../app/firebase";
import { requireProviderAccess } from "../app/permissions";

// Remove qualquer campo sensível que possa existir na raiz de um backup antigo,
// impedindo que um restore re-materialize segredos no documento público do
// provedor (que tem leitura pública). Segredos são restaurados apenas na
// subcoleção privada `secrets/sgp` (ver restoreProviderConfig).
function sanitizePublicProviderData(providerData: Record<string, unknown>): Record<string, unknown> {
  const clone: Record<string, unknown> = { ...providerData };
  for (const key of ["integrations", "apiToken", "token", "password", "secret", "secrets"]) {
    delete clone[key];
  }
  if (clone.details && typeof clone.details === "object") {
    const details = { ...(clone.details as Record<string, unknown>) };
    delete details.apiToken;
    clone.details = details;
  }
  if (clone.config && typeof clone.config === "object") {
    const config = { ...(clone.config as Record<string, unknown>) };
    delete config.integrations;
    clone.config = config;
  }
  return clone;
}

export const backupProviderConfig: RequestHandler<"BACKUP_PROVIDER_CONFIG"> = async ({ requestId, requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  const providerRef = db.collection("provedores").doc(payload.providerId);
  const [provider, secrets] = await Promise.all([
    providerRef.get(),
    providerRef.collection("secrets").doc("sgp").get(),
  ]);
  if (!provider.exists) throw new AppError("not-found", "Provedor não encontrado.");
  const backupRef = providerRef.collection("backups").doc(requestId);
  await backupRef.set({
    name: payload.name?.trim() || `Backup ${new Date().toISOString()}`,
    providerData: provider.data(),
    secrets: secrets.exists ? secrets.data() : null,
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
  const batch = db.batch();
  batch.set(providerRef, {
    ...sanitizePublicProviderData(data.providerData as Record<string, unknown>),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  if (data.secrets && typeof data.secrets === "object") {
    batch.set(providerRef.collection("secrets").doc("sgp"), data.secrets, { merge: true });
  }
  await batch.commit();
  return { success: true, message: "Backup restaurado." };
};

export const deleteProviderBackup: RequestHandler<"DELETE_PROVIDER_BACKUP"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  await db.collection("provedores").doc(payload.providerId).collection("backups").doc(payload.backupId).delete();
  return { success: true, message: "Backup apagado." };
};
