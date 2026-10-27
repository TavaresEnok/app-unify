import axios, { type AxiosInstance } from "axios";
import { lookup } from "node:dns/promises";
import { isIP } from "node:net";
import * as https from "node:https";
import { env } from "../config/env";
import { ApiError } from "../middlewares/errorHandler";
import { isPrivateIpv4 } from "../validators/traceroute";
import { firestore } from "./firebaseAdmin";

/** Credenciais de um SGP específico — cada provedor tem o seu. */
export interface SgpCredentials {
  baseUrl: string;
  token: string;
  app: string;
  /** Ausente quando caiu nas credenciais globais legadas do .env. */
  providerId?: string;
}

export interface SgpContract {
  contratoId: string;
  senhaCentral: string;
  contrato: Record<string, any>;
}

function stringField(...values: unknown[]): string {
  for (const value of values) {
    if (typeof value === "string" && value.trim()) return value.trim();
  }
  return "";
}

function isPrivateIpv6(address: string): boolean {
  const ip = address.toLowerCase();
  const mapped = ip.match(/^::ffff:(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
  if (mapped) return isPrivateIpv4(mapped.slice(1).map(Number));
  // O parser de URL normaliza `::ffff:10.0.0.1` para `::ffff:a00:1`.
  const mappedHex = ip.match(/^::ffff:([0-9a-f]{1,4}):([0-9a-f]{1,4})$/);
  if (mappedHex) {
    const [high, low] = mappedHex.slice(1).map((part) => parseInt(part, 16));
    return isPrivateIpv4([high >> 8, high & 255, low >> 8, low & 255]);
  }
  return ip === "::" || ip === "::1" || /^f[cd]/.test(ip) || /^fe[89ab]/.test(ip) || ip.startsWith("ff");
}

function isPrivateAddress(address: string): boolean {
  if (isIP(address) === 4) return isPrivateIpv4(address.split(".").map(Number));
  if (isIP(address) === 6) return isPrivateIpv6(address);
  return true;
}

/**
 * Bloqueia SSRF pela URL do SGP, que vem da configuração do provedor (editável
 * pelo admin do provedor). Resolve o DNS e exige que TODO endereço resolvido —
 * IPv4 e IPv6 — seja público, o que cobre `[::1]`, `127.0.0.1.nip.io` e afins.
 */
export async function assertSafeSgpBaseUrl(baseUrl: string): Promise<string> {
  let parsed: URL;
  try {
    parsed = new URL(baseUrl);
  } catch {
    throw new ApiError(503, "URL do SGP do provedor é inválida.", "service-unavailable");
  }
  if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
    throw new ApiError(503, "URL do SGP do provedor deve usar http(s).", "service-unavailable");
  }
  const host = parsed.hostname.replace(/^\[|\]$/g, "");
  const addresses = isIP(host)
    ? [host]
    : (await lookup(host, { all: true }).catch(() => [] as { address: string }[])).map((item) => item.address);
  if (!addresses.length) throw new ApiError(502, "Host do SGP não pôde ser resolvido.", "upstream-error");
  if (addresses.some(isPrivateAddress)) {
    throw new ApiError(503, "URL do SGP do provedor aponta para endereço interno.", "service-unavailable");
  }
  return parsed.toString().replace(/\/$/, "");
}

/**
 * Credenciais SGP do provedor, lidas da subcoleção privada `secrets/sgp` (o
 * token nunca vem do documento público). Com provedor identificado NÃO há
 * fallback para o .env — isso mandaria o CPF de um provedor ao SGP de outro.
 * Sem provedor (assinante legado fora de `clientes`), usa o SGP global.
 */
export async function resolveSgpCredentials(providerId?: string): Promise<SgpCredentials> {
  if (!providerId) {
    if (!env.sgpToken || !env.sgpAppName) throw new ApiError(503, "Credenciais do SGP não configuradas no servidor.", "service-unavailable");
    return { baseUrl: await assertSafeSgpBaseUrl(env.sgpBaseUrl), token: env.sgpToken, app: env.sgpAppName };
  }

  const providerRef = firestore.collection("provedores").doc(providerId);
  const [provider, secret] = await Promise.all([
    providerRef.get(),
    providerRef.collection("secrets").doc("sgp").get(),
  ]);
  if (!provider.exists) throw new ApiError(404, "Provedor do cliente não encontrado.", "not-found");
  const data = provider.data() || {};
  const integrations = secret.data()?.integrations || {};
  const baseUrl = stringField(integrations.sgpBaseUrl, data.details?.systemUrl, data.sgpBaseUrl);
  const token = stringField(integrations.apiToken);
  // Mesmo padrão de app das functions (handlers/sgp.ts).
  const app = stringField(integrations.appName, data.details?.appName, data.appName) || "APP-PROVEDOR";
  if (!baseUrl || !token) {
    throw new ApiError(503, "Integração SGP não configurada para este provedor.", "service-unavailable");
  }
  return { baseUrl: await assertSafeSgpBaseUrl(baseUrl), token, app, providerId };
}

export function createSgpSession(): AxiosInstance {
  return axios.create({
    timeout: 30_000,
    httpsAgent: new https.Agent({ rejectUnauthorized: env.sgpRejectUnauthorized }),
    headers: { "User-Agent": "Unify-API/1.0", "Content-Type": "application/json" },
  });
}

/** Todos os contratos do CPF/CNPJ no SGP do provedor, já normalizados. */
export async function listContracts(
  session: AxiosInstance,
  credentials: SgpCredentials,
  cpfCnpj: string,
): Promise<SgpContract[]> {
  const response = await session.post(`${credentials.baseUrl}/ws/ura/consultacliente/`, {
    token: credentials.token,
    app: credentials.app,
    cpfcnpj: cpfCnpj,
  });
  const contracts = response.data?.contratos;
  if (!Array.isArray(contracts) || !contracts.length) throw new ApiError(404, "Nenhum contrato encontrado para este cliente.", "not-found");
  return contracts.map((contrato: Record<string, any>) => {
    const contratoId = contrato.contratoId || contrato.contrato_id || contrato.id;
    if (!contratoId) throw new ApiError(502, "Contrato retornado pelo SGP sem identificador.", "invalid-upstream-response");
    return {
      contrato,
      contratoId: String(contratoId),
      senhaCentral: contrato.contratoCentralSenha || contrato.central_senha || "",
    };
  });
}

/**
 * Filtra pelo `contratoId` pedido. Como a lista vem do SGP para o CPF do
 * chamador, isto também impede operar contrato de outro cliente.
 */
export function pickContracts(contracts: SgpContract[], contratoId: unknown): SgpContract[] {
  if (contratoId === undefined || contratoId === null || contratoId === "") return contracts;
  const match = contracts.filter((item) => item.contratoId === String(contratoId));
  if (!match.length) throw new ApiError(404, "Contrato não encontrado para este cliente.", "not-found");
  return match;
}

export function externalErrorMessage(error: unknown, fallback: string): string {
  if (axios.isAxiosError(error)) {
    const upstream = error.response?.data?.msg || error.response?.data?.message;
    return typeof upstream === "string" && upstream ? upstream : fallback;
  }
  return error instanceof Error ? error.message : fallback;
}
