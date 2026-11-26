import { redis, cacheRedis } from "./redis";
import { createUpstream, readTtl } from "./upstream-runtime";
import axios, { type AxiosInstance } from "axios";
import { ApiError } from "../middlewares/errorHandler";
import { requirePgPool } from "./postgres";
import { getProviderRow, getProviderSecret } from "./providersStore";
import runtime from "./sgp-outbound";
import { createIxcGateway, ixcHeaders, ixcUrl } from "./ixc-gateway";
const outbound: any = runtime;

/** Credenciais de um SGP/IXC específico — cada provedor tem o seu. */
export interface SgpCredentials {
  baseUrl: string;
  token: string;
  app: string;
  providerId: string;
  /** ERP do provedor; ausente = SGP (legado). */
  erp?: "sgp" | "ixc";
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

/**
 * Bloqueia SSRF pela URL privada do ERP, cadastrada exclusivamente pelo SaaS.
 */
export async function assertSafeSgpBaseUrl(baseUrl: string): Promise<string> {
  try { return await outbound.assertSafeSgpBaseUrl(baseUrl); }
  catch { throw new ApiError(503, "Destino SGP inválido ou interno; integração indisponível.", "service-unavailable"); }
}

/**
 * Credenciais SGP/IXC do provedor, lidas da tabela cifrada `provider_secrets (kind='erp')`.
 */
async function loadSgpCredentials(providerId?: string): Promise<SgpCredentials> {
  if (!providerId || !/^[a-z0-9_-]+$/i.test(providerId)) {
    throw new ApiError(503, "Provedor SGP não identificado.", "service-unavailable");
  }

  const pool = requirePgPool();
  const [provider, integrations] = await Promise.all([
    getProviderRow(pool, providerId),
    getProviderSecret<Record<string, unknown>>(pool, providerId, "erp"),
  ]);
  if (!provider) throw new ApiError(404, "Provedor do cliente não encontrado.", "not-found");
  const baseUrl = stringField(integrations?.sgpBaseUrl);
  const token = stringField(integrations?.apiToken);
  const erp: "sgp" | "ixc" = stringField(integrations?.erp).toLowerCase() === "ixc" ? "ixc" : "sgp";
  // IXC autentica só pelo token do usuário de API; `app` é conceito do SGP.
  const app = erp === "ixc" ? "ixc" : stringField(integrations?.appName);
  if (!baseUrl || !token || !app) {
    throw new ApiError(503, "Integração SGP não configurada para este provedor.", "service-unavailable");
  }
  return { baseUrl: await assertSafeSgpBaseUrl(baseUrl), token, app, providerId, erp };
}

const credentialCache = new Map<string, { expires: number; value: Promise<SgpCredentials> }>();
export async function resolveSgpCredentials(providerId?: string): Promise<SgpCredentials> {
  if (!providerId || process.env.NODE_ENV === "test") return loadSgpCredentials(providerId);
  const cached = credentialCache.get(providerId);
  if (cached && cached.expires > Date.now()) return cached.value;
  if (credentialCache.size >= 128) credentialCache.delete(credentialCache.keys().next().value!);
  const value = loadSgpCredentials(providerId);
  credentialCache.set(providerId, { value, expires: Date.now() + 15000 });
  try { return await value; } catch (error) { credentialCache.delete(providerId); throw error; }
}

const positiveEnv = (name: string, fallback: number) => {
  const value = Number(process.env[name]);
  return Number.isInteger(value) && value > 0 ? value : fallback;
};
// Pedidos do app esperam por uma vaga (picos da home) em vez de 503 imediato.
const upstream = createUpstream({ getRedis: () => redis, getCacheRedis: () => cacheRedis, slotWaitMs: positiveEnv("SGP_SLOT_WAIT_MS", 8000) });
// IXC aceita bem consultas paralelas: teto maior por provedor (o de host continua).
const IXC_MAX_PER_PROVIDER = positiveEnv("IXC_MAX_PER_PROVIDER", 12);
const IXC_LIMITS = { maxPerProvider: IXC_MAX_PER_PROVIDER, maxPerHost: Math.max(8, IXC_MAX_PER_PROVIDER) };
export const ERP_BUSY_MESSAGE = "Muitos acessos agora. Tente novamente em alguns segundos.";

export function createSgpSession(
  providerId: string,
  baseUrl: string,
  credentials?: Pick<SgpCredentials, "erp" | "token">,
): Pick<AxiosInstance, "post"> {
  if (!providerId) throw new ApiError(503, "Provedor SGP não identificado.", "service-unavailable");
  const approved = outbound.parseSgpUrl(baseUrl);
  const ixc = credentials?.erp === "ixc" ? createIxcGateway({
    allowWrites: process.env.IXC_DISABLE_WRITES !== "true",
    call: async (table, payload, action) => (await outbound.request(ixcUrl(baseUrl, table), payload, {
      encoding: "json", timeout: 45000, headers: ixcHeaders(credentials.token, action),
    })).data,
  }) : null;
  return { post: async (url: string, body: unknown, config?: unknown) => {
      if (config && Object.keys(config).length) throw new ApiError(400, "Opções SGP não permitidas.", "invalid-argument");
      const target = outbound.parseSgpUrl(url);
      if (target.origin !== approved.origin || !target.pathname.startsWith(approved.pathname.replace(/\/$/, "") + "/")) {
        throw new ApiError(503, "Destino SGP divergente.", "service-unavailable");
      }
      const params = body instanceof URLSearchParams ? Object.fromEntries(body.entries()) : { ...(body as Record<string, unknown>) };
      delete params.token; delete params.app;
      const operation = ixc
        ? async () => ixc.handle(target.pathname.slice(approved.pathname.replace(/\/$/, "").length) || "/", params)
        : async () => (await outbound.request(url, body)).data;
      try {
        const data = await upstream.execute({
          providerId, url: String(url), body, ttl: readTtl(String(url)), mutate: /liberacaopromessa|wifi\/update/.test(String(url)),
          limits: ixc ? IXC_LIMITS : undefined,
        }, operation);
        return { data, status: 200, statusText: "OK", headers: {}, config: {} } as never;
      } catch (error) {
        const failure = error as { status?: number; busy?: boolean };
        if (failure.status === 503 && failure.busy) throw new ApiError(503, ERP_BUSY_MESSAGE, "unavailable");
        if (failure.status === 503) throw new ApiError(503, "SGP ocupado ou indisponível. Tente novamente.", "unavailable");
        throw error;
      }
    } } as Pick<AxiosInstance, "post">;
}

/** Todos os contratos do CPF/CNPJ no SGP/IXC do provedor, já normalizados. */
export async function listContracts(
  session: Pick<AxiosInstance, "post">,
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
