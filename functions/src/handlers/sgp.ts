import { clientPage } from "../app/clientPage";
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
      redirect: "error",
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
  // All operational fields come from the private integration, never branding.
  const integrations = secret.data()?.integrations || {};
  const result = {
    url: integrations.sgpBaseUrl,
    token: integrations.apiToken,
    app: integrations.appName,
  };
  if (![result.url, result.token, result.app].every(value => typeof value === "string" && value.trim())) throw new AppError("invalid-argument", "Configurações privadas do SGP incompletas.");
  if (!proxyUrlSecret.value() || !proxySecretParam.value()) throw new AppError("internal", "Proxy SGP não configurado.");
  return result;
}

export const sgpApiProxy: RequestHandler<"SGP_API_PROXY"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  if ([payload, payload.params].some(value => value && ["url", "token", "app", "sgpBaseUrl", "sgpParams", "apiToken", "appName"].some(key => Object.prototype.hasOwnProperty.call(value, key)))) throw new AppError("invalid-argument", "Configuração SGP não permitida no pedido.");

  const clientsRef = db.collection("provedores").doc(payload.providerId).collection("clientes");

  if (payload.action === "get") {
    const page = await clientPage(payload.providerId, { ...payload.params, search: payload.params?.searchTerm });
    return { clientes: page.items, paginacao: { total: page.total, limit: Math.min(Number(payload.params?.limit) || 25, 50), nextCursor: page.nextCursor } };
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

  if (payload.action === "status") {
    return await postProxy("/sync-status", {
      secret: proxySecretParam.value(), providerId: payload.providerId, jobId: payload.params?.jobId,
    });
  }
  await credentials(payload.providerId);
  return await postProxy("/sync-clients", {
    secret: proxySecretParam.value(), providerId: payload.providerId,
  });
};
