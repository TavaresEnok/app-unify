import { FieldValue } from "firebase-admin/firestore";
import type { RequestHandler } from "../app/request";
import { AppError } from "../app/errors";
import { auth, db } from "../app/firebase";
import { requireProviderAccess, requireSuperAdmin } from "../app/permissions";
import { isValidNewProviderId } from "../utils";

const DEFAULT_PROVIDER_CONFIG = {
  layoutType: "layout_06",
  themeColor: "#673AB7",
  secondaryColor: "#9575CD",
  textColor: "#FFFFFF",
  invoiceColor: "#10B981",
  actionColor: "#E11D48",
  cardColor: "#F8F8F8",
  cardTextColor: "#333333",
  logoUrl: "",
  loginQuote: "Bem-vindo ao App do Assinante",
  features: { consumption: true, support: true, invoices: true },
  menuConfig: { order: ["invoices", "support", "contract"], items: {} },
};

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

export const createProvider: RequestHandler<"CREATE_PROVIDER"> = async ({ requestId, requesterUid, payload }) => {
  await requireSuperAdmin(requesterUid);
  const providerId = payload.providerId.trim();
  const name = payload.name.trim();
  if (!providerId || !name || !isValidNewProviderId(providerId)) {
    throw new AppError("invalid-argument", "Nome ou ID de provedor inválido.");
  }

  const providerRef = db.collection("provedores").doc(providerId);
  const existing = await providerRef.get();
  if (existing.exists && existing.data()?.createdByRequestId === requestId) {
    return { success: true, message: "Provedor criado com sucesso.", providerId };
  }
  if (existing.exists) {
    throw new AppError("conflict", "Já existe um provedor com este ID.");
  }
  await providerRef.set({
    ...DEFAULT_PROVIDER_CONFIG,
    name,
    active: true,
    createdByRequestId: requestId,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { success: true, message: "Provedor criado com sucesso.", providerId };
};

export const updateProviderConfig: RequestHandler<"UPDATE_PROVIDER_CONFIG"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  const config = asRecord(payload.config);
  const publicConfig = { ...config };
  delete publicConfig.config;
  const integrations = asRecord(publicConfig.integrations);
  delete publicConfig.integrations;

  const providerRef = db.collection("provedores").doc(payload.providerId);
  const provider = await providerRef.get();
  if (!provider.exists) return { success: true, message: "Provedor apagado com sucesso." };

  if (Object.keys(integrations).length) {
    await providerRef.collection("secrets").doc("sgp").set({ integrations }, { merge: true });
  }
  await providerRef.update({
    ...publicConfig,
    integrations: FieldValue.delete(),
    "config.integrations": FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { success: true, message: "Configurações atualizadas.", providerId: payload.providerId };
};

export const updateProviderDetails: RequestHandler<"UPDATE_PROVIDER_DETAILS"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  const details = asRecord(payload.details);
  const publicDetails = { ...details };
  delete publicDetails.apiToken;
  delete publicDetails.token;
  delete publicDetails.password;
  delete publicDetails.secret;
  delete publicDetails.name;
  const secretIntegrations: Record<string, unknown> = {};
  if ("appName" in details) secretIntegrations.appName = details.appName;
  if ("apiToken" in details) secretIntegrations.apiToken = details.apiToken;
  if ("systemUrl" in details) secretIntegrations.sgpBaseUrl = details.systemUrl;
  const providerRef = db.collection("provedores").doc(payload.providerId);
  await Promise.all([
    providerRef.set({
      ...(typeof details.name === "string" && details.name ? { name: details.name } : {}),
      ...(typeof details.apiUrl === "string" && details.apiUrl ? { apiUrl: details.apiUrl } : {}),
      details: publicDetails,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true }),
    Object.keys(secretIntegrations).length
      ? providerRef.collection("secrets").doc("sgp").set({ integrations: secretIntegrations }, { merge: true })
      : Promise.resolve(),
  ]);
  return { success: true, message: "Provedor atualizado com sucesso.", providerId: payload.providerId };
};

export const deleteProvider: RequestHandler<"DELETE_PROVIDER"> = async ({ requesterUid, payload }) => {
  await requireSuperAdmin(requesterUid);
  const providerRef = db.collection("provedores").doc(payload.providerId);
  const provider = await providerRef.get();
  if (!provider.exists) throw new AppError("not-found", "Provedor não encontrado.");

  const [users, tickets] = await Promise.all([
    db.collection("users").where("providerId", "==", payload.providerId).get(),
    db.collection("tickets").where("providerId", "==", payload.providerId).get(),
  ]);

  for (const userDoc of users.docs) {
    await auth.deleteUser(userDoc.id).catch(() => undefined);
    await userDoc.ref.delete();
  }
  for (const ticket of tickets.docs) await db.recursiveDelete(ticket.ref);
  await db.recursiveDelete(providerRef);
  return { success: true, message: "Provedor apagado com sucesso." };
};
