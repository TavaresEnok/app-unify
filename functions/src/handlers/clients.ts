import type { RequestHandler } from "../app/request";
import { AppError } from "../app/errors";
import { db } from "../app/firebase";
import { requireProviderAccess } from "../app/permissions";

function sanitizeClient(id: string, data: FirebaseFirestore.DocumentData) {
  const output = { id, ...data } as Record<string, unknown>;
  const contracts = Array.isArray(data.contratos) ? data.contratos : [];
  output.contratos = contracts.map((contract: unknown) => {
    if (!contract || typeof contract !== "object") return contract;
    const sanitized = { ...(contract as Record<string, unknown>) };
    for (const key of Object.keys(sanitized)) {
      if (["senha", "password", "token", "apitoken", "authorization", "secret", "contratocentralsenha"].includes(key.toLowerCase())) {
        delete sanitized[key];
      }
    }
    return sanitized;
  });
  return output;
}

export const listProviderClients: RequestHandler<"LIST_PROVIDER_CLIENTS"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  const snapshot = await db.collection("provedores").doc(payload.providerId).collection("clientes").orderBy("nome").get();
  return snapshot.docs.map((client) => sanitizeClient(client.id, client.data()));
};

export const getClientDetails: RequestHandler<"GET_CLIENT_DETAILS"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  const collection = db.collection("provedores").doc(payload.providerId).collection("clientes");
  let client = await collection.doc(payload.clientId).get();
  if (!client.exists) {
    const bySgpId = await collection.where("id", "==", Number(payload.clientId)).limit(1).get();
    client = bySgpId.docs[0];
  }
  if (!client?.exists) throw new AppError("not-found", "Cliente não encontrado.");
  return sanitizeClient(client.id, client.data() || {});
};

export const deleteClient: RequestHandler<"DELETE_CLIENT"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  const nestedRef = db.collection("provedores").doc(payload.providerId).collection("clientes").doc(payload.clientId);
  const globalRef = db.collection("clientes").doc(payload.clientId);
  const global = await globalRef.get();
  const batch = db.batch();
  batch.delete(nestedRef);
  if (global.exists && global.data()?.providerId === payload.providerId) batch.delete(globalRef);
  await batch.commit();
  return { success: true, message: "Cliente removido do cache." };
};
