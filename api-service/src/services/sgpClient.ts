import { redis, cacheRedis } from "./redis";
import { createUpstream, readTtl } from "./upstream-runtime";
import axios, { type AxiosInstance } from "axios";
import { ApiError } from "../middlewares/errorHandler";
import { firestore } from "./firebaseAdmin";
import runtime from "./sgp-outbound";
const outbound: any = runtime;

/** Credenciais de um SGP específico — cada provedor tem o seu. */
export interface SgpCredentials {
  baseUrl: string;
  token: string;
  app: string;
  providerId: string;
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
 * Bloqueia SSRF pela URL privada do SGP, cadastrada exclusivamente pelo SaaS.
 * Resolve o DNS e exige que TODO endereço resolvido —
 * IPv4 e IPv6 — seja público, o que cobre `[::1]`, `127.0.0.1.nip.io` e afins.
 */
export async function assertSafeSgpBaseUrl(baseUrl: string): Promise<string> {
  try { return await outbound.assertSafeSgpBaseUrl(baseUrl); }
  catch { throw new ApiError(503, "Destino SGP inválido ou interno; integração indisponível.", "service-unavailable"); }
}

/**
 * Credenciais SGP do provedor, lidas da subcoleção privada `secrets/sgp` (o
 * token nunca vem do documento público). Com provedor identificado NÃO há
 * fallback para o .env — isso mandaria o CPF de um provedor ao SGP de outro.
 * Sem provedor verificável ou integração privada completa, falha fechado.
 */
async function loadSgpCredentials(providerId?: string): Promise<SgpCredentials> {
  if (!providerId || !/^[a-z0-9_-]+$/i.test(providerId)) throw new ApiError(503, "Provedor SGP não identificado.", "service-unavailable");

  const providerRef = firestore.collection("provedores").doc(providerId);
  const [provider, secret] = await Promise.all([
    providerRef.get(),
    providerRef.collection("secrets").doc("sgp").get(),
  ]);
  if (!provider.exists) throw new ApiError(404, "Provedor do cliente não encontrado.", "not-found");
  const integrations = secret.data()?.integrations || {};
  const baseUrl = stringField(integrations.sgpBaseUrl);
  const token = stringField(integrations.apiToken);
  const app = stringField(integrations.appName);
  if (!baseUrl || !token || !app) {
    throw new ApiError(503, "Integração SGP não configurada para este provedor.", "service-unavailable");
  }
  return { baseUrl: await assertSafeSgpBaseUrl(baseUrl), token, app, providerId };
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

const upstream = createUpstream({ getRedis: () => redis, getCacheRedis: () => cacheRedis });

export function createSgpSession(providerId: string, baseUrl: string): Pick<AxiosInstance, "post"> {
  if (!providerId) throw new ApiError(503, "Provedor SGP não identificado.", "service-unavailable");
  const approved = outbound.parseSgpUrl(baseUrl);
  return { post: async (url: string, body: unknown, config?: unknown) => {
      if (config && Object.keys(config).length) throw new ApiError(400, "Opções SGP não permitidas.", "invalid-argument");
      const target = outbound.parseSgpUrl(url);
      if (target.origin !== approved.origin || !target.pathname.startsWith(approved.pathname.replace(/\/$/, "") + "/")) throw new ApiError(503, "Destino SGP divergente.", "service-unavailable");
      const operation = () => outbound.request(url, body);
      try {
        const data = await upstream.execute({ providerId, url: String(url), body, ttl: readTtl(String(url)), mutate: /liberacaopromessa|wifi\/update/.test(String(url)) },
          async () => (await operation()).data);
        return { data, status: 200, statusText: "OK", headers: {}, config: {} } as never;
      } catch (error) {
        if ((error as { status?: number }).status === 503) throw new ApiError(503, "SGP ocupado ou indisponível. Tente novamente.", "unavailable");
        throw error;
      }
    } } as Pick<AxiosInstance, "post">;
}

/** Todos os contratos do CPF/CNPJ no SGP do provedor, já normalizados. */
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
