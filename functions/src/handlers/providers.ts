import { FieldValue } from "firebase-admin/firestore";
import type { RequestHandler } from "../app/request";
import { requirePayloadFields } from "../app/request";
import { AppError } from "../app/errors";
import { auth, db } from "../app/firebase";
import { requireProviderAccess, requireSuperAdmin } from "../app/permissions";
import { isValidNewProviderId } from "../utils";
import { parsePersonalization, parseDetails } from "../app/providerConfig";

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

export const createProvider: RequestHandler<"CREATE_PROVIDER"> = async ({ requestId, requesterUid, payload }) => {
  await requireSuperAdmin(requesterUid);
  requirePayloadFields(payload, ["providerId", "name"]);
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
  requirePayloadFields(payload, ["providerId", "config"]);
  let publicConfig: Record<string, unknown>;
  try { publicConfig = parsePersonalization(payload.config); }
  catch { throw new AppError("invalid-argument", "Configuração inválida ou campo não permitido."); }
  const providerRef = db.collection("provedores").doc(payload.providerId);
  const provider = await providerRef.get();
  if (!provider.exists) throw new AppError("not-found", "Provedor não encontrado.");


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
  requirePayloadFields(payload, ["providerId", "details"]);
  let details: Record<string, unknown>;
  try { details = parseDetails(payload.details); }
  catch { throw new AppError("invalid-argument", "Dados inválidos ou campo não permitido."); }
  const { name, ...publicDetails } = details;
  await db.collection("provedores").doc(payload.providerId).update({
    ...(typeof name === "string" ? { name } : {}),
    ...Object.fromEntries(Object.entries(publicDetails).map(([key, value]) => ["details." + key, value])),
    updatedAt: FieldValue.serverTimestamp(),
  });
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
