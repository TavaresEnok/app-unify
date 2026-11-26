import { ApiError } from "../../middlewares/errorHandler";
import { requirePgPool, type SqlQueryable } from "../postgres";
import { getProviderSecret, saveProviderSecret } from "../providersStore";
import sgpOutbound from "../sgp-outbound";
import { flashmanDriver } from "./drivers/flashmanDriver";
import { genieacsDriver } from "./drivers/genieacsDriver";
import { sgpDriver } from "./drivers/sgpDriver";
import {
  DEFAULT_ACS_FEATURES,
  inferPlanDownloadMbps,
  type AcsDriverType,
  type AcsFeatureFlags,
  type AcsPrivateConfig,
  type AcsPublicSummary,
  type CpeIdentity,
  type Tr069Driver,
} from "./types";

const ALLOWED_DRIVERS = new Set<AcsDriverType>(["none", "sgp", "genieacs", "flashman"]);

function parseFeatures(raw: unknown): AcsFeatureFlags {
  const src = raw && typeof raw === "object" ? (raw as Record<string, unknown>) : {};
  return {
    wifi: src.wifi !== false,
    reboot: src.reboot !== false,
    hosts: src.hosts !== false,
    guestWifi: src.guestWifi !== false,
    channelOptimize: src.channelOptimize !== false,
    speedDiagnostic: src.speedDiagnostic !== false,
  };
}

// O que cada driver realmente consegue executar. A API do SGP (token/app) só
// expõe wifi/list, wifi/set e wifi/update no CPE Manager: não há rota de
// reinício, otimização de canal nem diagnóstico (validado na InsNet, nov/2026).
const DRIVER_LIMITS: Partial<Record<AcsDriverType, Partial<AcsFeatureFlags>>> = {
  sgp: { reboot: false, channelOptimize: false, speedDiagnostic: false },
};

export function effectiveFeatures(driver: AcsDriverType, features: AcsFeatureFlags): AcsFeatureFlags {
  return { ...features, ...(DRIVER_LIMITS[driver] ?? {}) };
}

/** true quando o gerenciador (driver) não consegue executar o recurso. */
export function driverLacksFeature(driver: AcsDriverType, feature: keyof AcsFeatureFlags): boolean {
  return DRIVER_LIMITS[driver]?.[feature] === false;
}

function toIso(raw: unknown): string | null {
  if (!raw) return null;
  if (typeof raw === "string") return raw;
  if (typeof raw === "object" && raw !== null && typeof (raw as { toDate?: () => Date }).toDate === "function") {
    return (raw as { toDate: () => Date }).toDate().toISOString();
  }
  return null;
}

export async function getAcsPrivateConfig(providerId: string): Promise<AcsPrivateConfig> {
  const d = await getProviderSecret<Record<string, any>>(requirePgPool(), providerId, "acs");
  if (!d) {
    return {
      driver: "none",
      enabled: false,
      url: "",
      username: "",
      password: "",
      apiKey: "",
      features: { ...DEFAULT_ACS_FEATURES },
      updatedAt: null,
    };
  }
  const driver = ALLOWED_DRIVERS.has(d.driver) ? (d.driver as AcsDriverType) : "none";
  return {
    driver,
    enabled: Boolean(d.enabled) && driver !== "none",
    url: typeof d.url === "string" ? d.url.trim() : "",
    username: typeof d.username === "string" ? d.username.trim() : "",
    password: typeof d.password === "string" ? d.password : "",
    apiKey: typeof d.apiKey === "string" ? d.apiKey : "",
    features: effectiveFeatures(driver, parseFeatures(d.features)),
    updatedAt: toIso(d.updatedAt),
  };
}

export function toPublicAcsSummary(config: AcsPrivateConfig): AcsPublicSummary {
  return {
    driver: config.driver,
    enabled: config.enabled,
    url: config.url,
    username: config.username,
    hasPassword: Boolean(config.password),
    hasApiKey: Boolean(config.apiKey),
    features: config.features,
    updatedAt: config.updatedAt || null,
  };
}

export async function saveAcsPrivateConfig(
  providerId: string,
  input: Record<string, unknown>,
): Promise<AcsPrivateConfig> {
  const existing = await getAcsPrivateConfig(providerId);
  const rawDriver = typeof input.driver === "string" ? input.driver.trim().toLowerCase() : existing.driver;
  if (!ALLOWED_DRIVERS.has(rawDriver as AcsDriverType)) {
    throw new ApiError(400, "Driver TR-069/ACS inválido. Use: none, sgp, genieacs ou flashman.", "invalid-argument");
  }
  const driver = rawDriver as AcsDriverType;
  const enabled = driver !== "none" && input.enabled !== false;
  const url = typeof input.url === "string" ? input.url.trim().replace(/\/+$/, "") : existing.url;

  if (enabled && (driver === "genieacs" || driver === "flashman")) {
    if (!url) throw new ApiError(400, "URL do servidor ACS é obrigatória.", "invalid-argument");
    try {
      await sgpOutbound.assertSafeSgpBaseUrl(url);
    } catch {
      throw new ApiError(400, "URL do servidor ACS inválida ou em faixa interna bloqueada.", "invalid-argument");
    }
  }

  const username = typeof input.username === "string" ? input.username.trim().slice(0, 120) : existing.username;
  // Só sobrescreve segredos se novos valores não-vazios forem enviados (ou se driver virar none)
  const password = driver === "none"
    ? ""
    : typeof input.password === "string" && input.password.length > 0
      ? input.password
      : existing.password;
  const apiKey = driver === "none"
    ? ""
    : typeof input.apiKey === "string" && input.apiKey.length > 0
      ? input.apiKey
      : existing.apiKey;

  const features = input.features !== undefined ? parseFeatures(input.features) : existing.features;
  const updatedAt = new Date().toISOString();

  await saveProviderSecret(requirePgPool(), providerId, "acs", {
    driver,
    enabled,
    url,
    username,
    password,
    apiKey,
    features,
    updatedAt,
  });

  return {
    driver,
    enabled,
    url,
    username,
    password,
    apiKey,
    features: effectiveFeatures(driver, features),
    updatedAt,
  };
}

export function getTr069Driver(config: AcsPrivateConfig): Tr069Driver {
  if (!config.enabled || config.driver === "none") {
    throw new ApiError(503, "Integração TR-069/ACS não habilitada para este provedor.", "service-unavailable");
  }
  switch (config.driver) {
    case "genieacs":
      return genieacsDriver;
    case "flashman":
      return flashmanDriver;
    case "sgp":
      return sgpDriver;
    default:
      throw new ApiError(503, "Driver TR-069 não suportado.", "service-unavailable");
  }
}

type ContractRecord = Record<string, any>;

function contractIdOf(c: ContractRecord): string {
  return String(c?.id ?? c?.contratoId ?? "");
}

function internetServices(c: ContractRecord): ContractRecord[] {
  const servicos = Array.isArray(c?.servicos) ? c.servicos : [];
  return servicos.filter((s: any) => s && typeof s === "object" && String(s.tipo || "").toLowerCase() === "internet");
}

function activeStatus(value: unknown): boolean {
  return /^ativo/i.test(String(value || "").trim());
}

/** O serviço de internet do contrato tem roteador no CPE Manager (serial preenchido). */
export function contractHasManagedRouter(c: ContractRecord | null | undefined): boolean {
  if (!c) return false;
  return internetServices(c).some((s) => String(s.serial || "").trim() !== "");
}

/**
 * Contrato padrão quando o app/painel não informa um: primeiro ativo com
 * roteador gerenciado, depois o primeiro ativo, depois o primeiro.
 */
export function pickDefaultContract(contratos: ContractRecord[]): ContractRecord | null {
  const list = contratos.filter((c) => c && typeof c === "object");
  return list.find((c) => activeStatus(c.status) && contractHasManagedRouter(c))
    || list.find((c) => contractHasManagedRouter(c))
    || list.find((c) => activeStatus(c.status))
    || list[0]
    || null;
}

export async function loadSubscriberContracts(
  pool: SqlQueryable | null,
  providerId: string,
  identifier: string,
): Promise<{ cpfCnpj: string; contratos: ContractRecord[] } | null> {
  const raw = String(identifier || "").trim();
  const digits = raw.replace(/\D/g, "");
  if (!pool || !(raw || digits)) return null;
  const res = await pool.query<{ cpfcnpj: string; contratos: unknown }>(
    `SELECT cpfcnpj, contratos
       FROM sgp_clients
      WHERE provider_id = $1 AND (cpfcnpj = $2 OR client_id = $3)
      LIMIT 1`,
    [providerId, digits || raw, raw],
  ).catch(() => ({ rows: [] as Array<{ cpfcnpj: string; contratos: unknown }> }));
  const row = res.rows[0];
  if (!row) return null;
  return { cpfCnpj: String(row.cpfcnpj || digits || raw), contratos: Array.isArray(row.contratos) ? row.contratos as ContractRecord[] : [] };
}

/**
 * Para o driver SGP: este assinante tem roteador gerenciado? null quando o
 * cache local não conhece o contrato (quem chama decide confirmar ao vivo).
 */
export async function resolveDeviceManaged(
  pool: SqlQueryable | null,
  providerId: string,
  cpfCnpj: string,
  contratoId?: string,
): Promise<boolean | null> {
  const found = await loadSubscriberContracts(pool, providerId, cpfCnpj);
  if (!found) return null;
  const wanted = String(contratoId || "").trim();
  const contract = wanted ? found.contratos.find((c) => contractIdOf(c) === wanted) : pickDefaultContract(found.contratos);
  if (!contract) return null;
  return contractHasManagedRouter(contract);
}

/**
 * Resolve serial da ONU, MAC, login PPPoE, contrato e plano direto do PostgreSQL (`sgp_clients`)
 * para localizar o roteador no ACS sem consultas extras ao Firestore ou SGP.
 */
export async function resolveCpeIdentityFromPg(
  pool: SqlQueryable | null,
  providerId: string,
  identifier: string,
  options: { contratoId?: string; authHeader?: string } = {},
): Promise<CpeIdentity> {
  const raw = String(identifier || "").trim();
  const digits = raw.replace(/\D/g, "");
  let serial = "";
  let mac = "";
  let pppoeLogin = "";
  let contratoId = String(options.contratoId || "").trim();
  let planName = "";
  let cpfCnpj = digits || raw;

  const found = await loadSubscriberContracts(pool, providerId, raw || digits);
  if (found) {
    cpfCnpj = found.cpfCnpj || cpfCnpj;
    const contratos = found.contratos;
    // Contrato informado e ausente do cache: mantém o ID pedido, mas nunca usa
    // serial/MAC/PPPoE de OUTRO contrato (o ERP confere a posse do pedido).
    const selected = contratoId
      ? contratos.find((c) => contractIdOf(c) === contratoId) || null
      : pickDefaultContract(contratos);
    if (selected && typeof selected === "object") {
      const c = selected as Record<string, any>;
      contratoId = contratoId || contractIdOf(c);
      const servicos = Array.isArray(c.servicos) ? c.servicos : [];
      const srv = (servicos.find((s: any) => s?.onu) || servicos[0] || {}) as Record<string, any>;
      const onu = (srv.onu && typeof srv.onu === "object" ? srv.onu : {}) as Record<string, any>;
      serial = String(onu.serial || onu.phy_addr || onu.serial_number || "").trim();
      mac = String(onu.mac || srv.mac || c.mac || "").trim();
      pppoeLogin = String(srv.login || c.contratoCentralLogin || c.login || "").trim();
      const planoObj = srv.plano;
      planName = String(
        (typeof planoObj === "object" && planoObj ? planoObj.descricao : planoObj) ||
        c.servico_plano ||
        c.plano ||
        "",
      ).trim();
    }
  }

  return {
    providerId,
    cpfCnpj,
    contratoId,
    serial,
    mac,
    pppoeLogin,
    planName,
    planDownloadMbps: inferPlanDownloadMbps(planName),
    authHeader: options.authHeader,
  };
}

export * from "./types";
