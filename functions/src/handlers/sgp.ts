import { FieldValue } from "firebase-admin/firestore";
import type { RequestHandler } from "../app/request";
import { AppError } from "../app/errors";
import { proxySecretParam, proxyUrlSecret } from "../app/config";
import { db } from "../app/firebase";
import { requireProviderAccess } from "../app/permissions";

const SENSITIVE_KEYS = new Set(["contratocentralsenha", "senha", "password", "token", "apitoken", "authorization", "secret"]);

function sanitizeContracts(value: unknown): unknown[] {
  if (!Array.isArray(value)) return [];
  return value.map((contract) => {
    if (!contract || typeof contract !== "object") return contract;
    const output: Record<string, unknown> = {};
    for (const [key, next] of Object.entries(contract as Record<string, unknown>)) {
      if (!SENSITIVE_KEYS.has(key.toLowerCase())) output[key] = next;
    }
    return output;
  });
}

async function postProxy(path: string, body: Record<string, unknown>, timeoutMs = 30_000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(`${proxyUrlSecret.value()}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
    const text = await response.text();
    let data: unknown;
    try { data = text ? JSON.parse(text) : {}; } catch { data = { raw: text }; }
    if (!response.ok) throw new AppError("internal", `Proxy SGP respondeu ${response.status}.`);
    return data as Record<string, unknown>;
  } finally {
    clearTimeout(timeout);
  }
}

async function credentials(providerId: string) {
  const providerRef = db.collection("provedores").doc(providerId);
  const [provider, secret] = await Promise.all([
    providerRef.get(),
    providerRef.collection("secrets").doc("sgp").get(),
  ]);
  if (!provider.exists) throw new AppError("not-found", "Provedor não encontrado.");
  const data = provider.data() || {};
  const integrations = secret.data()?.integrations || data.integrations || {};
  const result = {
    url: integrations.sgpBaseUrl || data.details?.systemUrl || data.sgpBaseUrl,
    token: integrations.apiToken || data.details?.apiToken || data.apiToken,
    app: integrations.appName || data.details?.appName || data.appName || "APP-PROVEDOR",
  };
  if (!result.url || !result.token) throw new AppError("invalid-argument", "Configurações do SGP incompletas.");
  if (!proxyUrlSecret.value() || !proxySecretParam.value()) throw new AppError("internal", "Proxy SGP não configurado.");
  return result;
}

export const sgpApiProxy: RequestHandler<"SGP_API_PROXY"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  const config = await credentials(payload.providerId);
  const clientsRef = db.collection("provedores").doc(payload.providerId).collection("clientes");

  if (payload.action === "get") {
    const limit = Math.min(Math.max(Number(payload.params?.limit) || 25, 1), 100);
    const offset = Math.max(Number(payload.params?.offset) || 0, 0);
    const searchTerm = String(payload.params?.searchTerm || "").trim();
    let query: FirebaseFirestore.Query = clientsRef;
    if (searchTerm) query = query.where("nome", ">=", searchTerm).where("nome", "<=", `${searchTerm}\uf8ff`);
    query = query.orderBy("nome").offset(offset).limit(limit);
    const [snapshot, count] = await Promise.all([query.get(), clientsRef.count().get()]);
    return {
      clientes: snapshot.docs.map((client) => ({ ...client.data(), contratos: sanitizeContracts(client.data().contratos) })),
      paginacao: { total: count.data().count, limit, offset },
    };
  }

  if (payload.action === "get_single") {
    const clientId = String(payload.params?.clientId || "");
    if (!clientId) throw new AppError("invalid-argument", "ClientID obrigatório.");
    let snapshot = await clientsRef.where("id", "==", Number(clientId)).limit(1).get();
    if (snapshot.empty) snapshot = await clientsRef.where("id", "==", clientId).limit(1).get();
    if (snapshot.empty) throw new AppError("not-found", "Cliente não encontrado.");
    const data = snapshot.docs[0].data();
    return { ...data, contratos: sanitizeContracts(data.contratos) };
  }

  await postProxy("/sync-clients", {
    secret: proxySecretParam.value(),
    providerId: payload.providerId,
    sgpBaseUrl: config.url,
    params: { token: config.token, app: config.app },
  }, 5 * 60_000);

  let offset = 0;
  let total = 0;
  const pageSize = 100;
  while (true) {
    const page = await postProxy("/get-cached-clients", {
      secret: proxySecretParam.value(),
      providerId: payload.providerId,
      params: { limit: pageSize, offset },
    });
    const clients = Array.isArray(page.clientes) ? page.clientes as Array<Record<string, unknown>> : [];
    if (!clients.length) break;
    for (let start = 0; start < clients.length; start += 400) {
      const batch = db.batch();
      for (const client of clients.slice(start, start + 400)) {
        const cpf = String(client.cpfcnpj || "").replace(/\D/g, "");
        if (!cpf) continue;
        batch.set(clientsRef.doc(cpf), {
          ...client,
          contratos: sanitizeContracts(client.contratos),
          providerId: payload.providerId,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
      await batch.commit();
    }
    total += clients.length;
    if (clients.length < pageSize) break;
    offset += pageSize;
  }
  return { count: total, message: `Sincronização concluída: ${total} clientes atualizados.` };
};
