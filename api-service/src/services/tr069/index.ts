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
    features: parseFeatures(d.features),
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
    features,
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

  if (pool && (raw || digits)) {
    const res = await pool.query<{ cpfcnpj: string; contratos: unknown }>(
      `SELECT cpfcnpj, contratos
         FROM sgp_clients
        WHERE provider_id = $1 AND (cpfcnpj = $2 OR client_id = $3)
        LIMIT 1`,
      [providerId, digits || raw, raw],
    ).catch(() => ({ rows: [] }));

    const row = res.rows[0];
    if (row) {
      cpfCnpj = String(row.cpfcnpj || cpfCnpj);
      const contratos = Array.isArray(row.contratos) ? row.contratos : [];
      const selected = (contratoId
        ? contratos.find((c: any) => String(c?.id ?? c?.contratoId ?? "") === contratoId)
        : null) || contratos[0];
      if (selected && typeof selected === "object") {
        const c = selected as Record<string, any>;
        contratoId = contratoId || String(c.id ?? c.contratoId ?? "");
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
