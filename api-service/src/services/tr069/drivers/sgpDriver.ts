import { ApiError } from "../../../middlewares/errorHandler";
import { proxyToSgp } from "../../proxySgpClient";
import {
  classifySignalQuality,
  type CpeConnectedHost,
  type CpeDiagnosticResult,
  type CpeIdentity,
  type CpeStatusOverview,
  type CpeWifiNetwork,
  type FiberStatus,
  type Tr069Driver,
} from "../types";

type ProxyCpeHost = { hostname?: string; mac?: string; ip?: string; interfaceType?: string; rssiDbm?: number | null };
type ProxyCpeDevice = {
  manager?: string;
  manufacturer?: string;
  model?: string;
  firmware?: string;
  wanIp?: string;
  wanUptimeSeconds?: number | null;
  lastBoot?: string | null;
  hosts?: ProxyCpeHost[];
  passwordReadable?: boolean;
};
type ProxyCpeList = { networks: CpeWifiNetwork[]; device: ProxyCpeDevice | null; servicoId: string; passwordReadable?: boolean };

export const UNNAMED_DEVICE = "Aparelho sem nome";
const UNSUPPORTED = "Recurso não suportado por este gerenciador.";

function mapSgpWifi(rawList: unknown): CpeWifiNetwork[] {
  if (!Array.isArray(rawList)) return [];
  return rawList.map((item: any, idx) => {
    const freq = String(item?.frequency || item?.band || item?.frequencia || "").toLowerCase();
    const band: CpeWifiNetwork["band"] = freq.includes("5") ? "5GHz" : "2.4GHz";
    const ssid = String(item?.ssid || item?.name || `Wi-Fi ${idx + 1}`);
    const mode = typeof item?.mode === "string" ? item.mode.trim() : "";
    const bandwidth = item?.bandwidth != null && item.bandwidth !== "" ? String(item.bandwidth) : null;
    return {
      id: String(item?.id ?? item?.wifi_id ?? idx + 1),
      ssid,
      band,
      channel: String(item?.channel || item?.canal || "Auto"),
      enabled: item?.enabled !== false && item?.active !== false,
      isGuest: /guest|visitante/i.test(ssid),
      ...(mode ? { mode } : {}),
      ...(bandwidth ? { bandwidth } : {}),
    };
  });
}

function mapHost(h: ProxyCpeHost): CpeConnectedHost {
  const interfaceType: CpeConnectedHost["interfaceType"] =
    h?.interfaceType === "wifi_2g" || h?.interfaceType === "wifi_5g" || h?.interfaceType === "ethernet" ? h.interfaceType : "unknown";
  const rssiDbm = typeof h?.rssiDbm === "number" && Number.isFinite(h.rssiDbm) ? h.rssiDbm : null;
  const name = String(h?.hostname || "").trim();
  return {
    // Sem nome DHCP, mostra um rótulo amigável em vez do MAC.
    hostname: name || UNNAMED_DEVICE,
    mac: String(h?.mac || "").toUpperCase(),
    ip: String(h?.ip || ""),
    interfaceType,
    rssiDbm,
    signalQuality: classifySignalQuality(interfaceType, rssiDbm),
    active: true,
  };
}

// Leituras do CPE Manager ficam em cache curto por assinante+contrato e
// pedidos simultâneos (status, hosts, overview do painel) dividem a mesma
// consulta. "Sem roteador gerenciado" (404/422) fica 10 min em cache.
const CPE_CACHE_MS = 45_000;
const CPE_NEGATIVE_CACHE_MS = 10 * 60_000;
const FIBER_CACHE_MS = 30_000;
const FIBER_DETAILS_CACHE_MS = 5 * 60_000;
const CACHE_MAX = 2000;
type Entry<T> = { value?: T; error?: ApiError; expires: number };
const cpeCache = new Map<string, Entry<ProxyCpeList>>();
const fiberCache = new Map<string, Entry<FiberStatus | null>>();
const fiberDetailsCache = new Map<string, Entry<Partial<FiberStatus> | null>>();
const inFlight = new Map<string, Promise<unknown>>();

export function clearSgpDriverCacheForTests(): void {
  cpeCache.clear();
  fiberCache.clear();
  fiberDetailsCache.clear();
  inFlight.clear();
}

function cacheKey(kind: string, identity: CpeIdentity): string {
  return `${kind}:${identity.providerId}:${identity.cpfCnpj}:${identity.contratoId}`;
}

function remember<T>(cache: Map<string, Entry<T>>, key: string, entry: Entry<T>): void {
  if (!cache.has(key) && cache.size >= CACHE_MAX) cache.delete(cache.keys().next().value as string);
  cache.set(key, entry);
}

async function cached<T>(cache: Map<string, Entry<T>>, key: string, ttl: number, load: () => Promise<T>, negativeTtl = 0): Promise<T> {
  const hit = cache.get(key);
  if (hit && hit.expires > Date.now()) {
    if (hit.error) throw hit.error;
    return hit.value as T;
  }
  const running = inFlight.get(key) as Promise<T> | undefined;
  if (running) return running;
  const promise = load().then((value) => {
    remember(cache, key, { value, expires: Date.now() + ttl });
    return value;
  }, (error) => {
    if (negativeTtl && error instanceof ApiError && (error.status === 404 || error.status === 422)) {
      remember(cache, key, { error, expires: Date.now() + negativeTtl });
    }
    throw error;
  }).finally(() => inFlight.delete(key));
  inFlight.set(key, promise);
  return promise;
}

// O proxy resolve o ID do serviço (o CPE Manager do SGP não aceita o ID do
// contrato), confirma a posse do contrato e normaliza a resposta real.
async function loadCpeList(identity: CpeIdentity): Promise<ProxyCpeList> {
  const res = await proxyToSgp("/cpe/wifi/list", {
    cpfCnpj: identity.cpfCnpj,
    contrato: identity.contratoId,
    providerId: identity.providerId,
  }, identity.authHeader);
  const body = (res.data ?? {}) as Record<string, any>;
  if (res.status >= 400) {
    throw new ApiError(res.status, body?.error?.message || "SGP CPE Manager indisponível para este contrato.", "upstream-error");
  }
  const device = body?.device && typeof body.device === "object" ? body.device as ProxyCpeDevice : null;
  const passwordReadable = typeof body?.passwordReadable === "boolean" ? body.passwordReadable
    : typeof device?.passwordReadable === "boolean" ? device.passwordReadable : undefined;
  return {
    networks: mapSgpWifi(body?.data ?? body),
    device,
    servicoId: typeof body?.servicoId === "string" ? body.servicoId : "",
    ...(passwordReadable !== undefined ? { passwordReadable } : {}),
  };
}

async function fetchCpeList(identity: CpeIdentity): Promise<ProxyCpeList> {
  if (!identity.contratoId) {
    throw new ApiError(404, "Contrato não localizado para consulta no SGP CPE Manager.", "not-found");
  }
  return cached(cpeCache, cacheKey("cpe", identity), CPE_CACHE_MS, () => loadCpeList(identity), CPE_NEGATIVE_CACHE_MS);
}

function finiteOrNull(value: unknown): number | null {
  const n = typeof value === "number" ? value : typeof value === "string" && value.trim() ? Number(value) : NaN;
  return Number.isFinite(n) ? n : null;
}

// Fibra/ONU pelo último registro do ERP (fttx/onu/list, ~0,5 s).
async function loadFiber(identity: CpeIdentity): Promise<FiberStatus | null> {
  const res = await proxyToSgp("/diagnostic/onu-signal-base", {
    cpfCnpj: identity.cpfCnpj,
    contrato: identity.contratoId,
    providerId: identity.providerId,
  }, identity.authHeader);
  if (res.status >= 400) return null;
  const data = ((res.data as Record<string, any>)?.data ?? null) as Record<string, any> | null;
  if (!data) return null;
  const status = String(data.connectionStatus || "").toLowerCase();
  return {
    online: status === "online" ? true : status === "offline" ? false : null,
    rxPowerDbm: finiteOrNull(data.signalRx),
    txPowerDbm: finiteOrNull(data.signalTx),
    onlineSince: null,
    lastDownCause: null,
    distanceMeters: null,
    source: "snapshot",
    updatedAt: typeof data.lastUpdate === "string" && data.lastUpdate ? data.lastUpdate : null,
  };
}

// Detalhes ao vivo na OLT (on-demand). Falha não derruba o status.
async function loadFiberDetails(identity: CpeIdentity): Promise<Partial<FiberStatus> | null> {
  const res = await proxyToSgp("/diagnostic/onu-details", {
    cpfCnpj: identity.cpfCnpj,
    contrato: identity.contratoId,
    providerId: identity.providerId,
  }, identity.authHeader);
  if (res.status >= 400) return null;
  const d = ((res.data as Record<string, any>)?.data ?? null) as Record<string, any> | null;
  if (!d) return null;
  return {
    online: typeof d.online === "boolean" ? d.online : null,
    rxPowerDbm: finiteOrNull(d.rxPowerDbm),
    txPowerDbm: finiteOrNull(d.txPowerDbm),
    onlineSince: typeof d.onlineSince === "string" ? d.onlineSince : null,
    lastDownCause: typeof d.lastDownCause === "string" ? d.lastDownCause : null,
    distanceMeters: finiteOrNull(d.distanceMeters),
    source: "olt",
    updatedAt: typeof d.fetchedAt === "string" ? d.fetchedAt : null,
  };
}

async function fetchFiber(identity: CpeIdentity, details: boolean): Promise<FiberStatus | null> {
  if (!identity.contratoId) return null;
  const base = await cached(fiberCache, cacheKey("fiber", identity), FIBER_CACHE_MS, () => loadFiber(identity)).catch(() => null);
  if (!details) {
    const live = fiberDetailsCache.get(cacheKey("olt", identity));
    if (live?.value && live.expires > Date.now()) return mergeFiber(base, live.value);
    return base;
  }
  const olt = await cached(fiberDetailsCache, cacheKey("olt", identity), FIBER_DETAILS_CACHE_MS, () => loadFiberDetails(identity)).catch(() => null);
  return mergeFiber(base, olt);
}

function mergeFiber(base: FiberStatus | null, olt: Partial<FiberStatus> | null): FiberStatus | null {
  if (!olt) return base;
  return {
    online: olt.online ?? base?.online ?? null,
    rxPowerDbm: olt.rxPowerDbm ?? base?.rxPowerDbm ?? null,
    txPowerDbm: olt.txPowerDbm ?? base?.txPowerDbm ?? null,
    onlineSince: olt.onlineSince ?? null,
    lastDownCause: olt.lastDownCause ?? null,
    distanceMeters: olt.distanceMeters ?? null,
    source: "olt",
    updatedAt: olt.updatedAt ?? base?.updatedAt ?? null,
  };
}

function unmanaged(error: unknown): boolean {
  return error instanceof ApiError && (error.status === 404 || error.status === 422);
}

export const sgpDriver: Tr069Driver = {
  async testConnection(config) {
    return {
      ok: config.enabled,
      message: "Driver SGP CPE Manager ativo — utiliza a integração SGP já cadastrada do provedor.",
    };
  },

  async getOverview(_config, identity, options = {}): Promise<CpeStatusOverview> {
    const [cpe, fiber] = await Promise.all([
      fetchCpeList(identity).then((value) => ({ value, error: null as unknown }), (error) => ({ value: null, error })),
      fetchFiber(identity, options.fiberDetails === true),
    ]);
    // Sem roteador gerenciado, mas com dados da fibra: devolve só a fibra.
    if (!cpe.value && !(unmanaged(cpe.error) && fiber)) throw cpe.error;
    const networks = cpe.value?.networks ?? [];
    const device = cpe.value?.device ?? null;
    const hosts = (device?.hosts ?? []).map(mapHost);
    const passwordReadable = cpe.value?.passwordReadable;
    return {
      // O CPE Manager devolve o último registro salvo, não o estado ao vivo:
      // o roteador só é dado como fora do ar quando a fibra está fora.
      online: fiber?.online === false ? false : null,
      driver: "sgp",
      deviceId: identity.serial || identity.contratoId,
      manufacturer: device?.manufacturer || "",
      model: device?.model || (cpe.value ? "CPE gerenciada via SGP" : ""),
      serial: identity.serial,
      mac: identity.mac,
      firmware: device?.firmware || "",
      uptimeSeconds: device?.wanUptimeSeconds ?? null,
      wanIp: device?.wanIp || "",
      opticalRxDbm: fiber?.rxPowerDbm ?? null,
      lanPorts: [],
      lanBottleneck100Mbps: false,
      planDownloadMbps: identity.planDownloadMbps,
      wifiNetworks: networks,
      hostsCount: hosts.length,
      hosts,
      lastInform: null,
      snapshotAt: null,
      fiber,
      deviceManaged: Boolean(cpe.value),
      ...(passwordReadable !== undefined ? { passwordReadable } : {}),
    };
  },

  async listHosts(_config, identity): Promise<CpeConnectedHost[]> {
    if (!identity.contratoId) return [];
    // Esta versão do SGP não tem /hosts/: os dispositivos vêm em lan_devices do wifi/list.
    const { device } = await fetchCpeList(identity);
    return (device?.hosts ?? []).map(mapHost);
  },

  async updateWifi(_config, identity, input) {
    if (!identity.contratoId) {
      throw new ApiError(400, "Contrato obrigatório para atualizar Wi-Fi via SGP.", "invalid-argument");
    }
    // Roteador que não informa a senha salva: renomear exige digitar a senha.
    // Responde na hora, sem gastar chamadas ao ERP que terminariam em erro.
    const known = cpeCache.get(cacheKey("cpe", identity));
    if (!input.password && known?.value?.passwordReadable === false) {
      throw new ApiError(400, "Digite a senha do Wi-Fi (a atual ou uma nova, com 8 ou mais caracteres). O roteador não informa a senha salva.", "invalid-argument");
    }
    // Escrita: o proxy pode fazer até 3 chamadas ao ERP, então o teto aqui é
    // maior que o padrão (o app espera 45 s).
    const res = await proxyToSgp("/cpe/wifi/update", {
      cpfCnpj: identity.cpfCnpj,
      contrato: identity.contratoId,
      providerId: identity.providerId,
      wifiId: input.wifiId,
      ssid: input.ssid || "",
      password: input.password || "",
    }, identity.authHeader, undefined, { timeoutMs: 40_000 });
    const body = (res.data ?? {}) as Record<string, any>;
    if (res.status >= 400) {
      throw new ApiError(res.status, body?.error?.message || "Não foi possível atualizar o Wi-Fi via SGP.", "upstream-error");
    }
    cpeCache.delete(cacheKey("cpe", identity));
    return { success: true, message: "Configuração Wi-Fi enviada via SGP CPE Manager." };
  },

  // A API do SGP (token/app) não tem rota de reinício: responde sem tocar no ERP.
  async reboot() {
    throw new ApiError(409, UNSUPPORTED, "not-supported");
  },

  async optimizeWifi() {
    throw new ApiError(409, UNSUPPORTED, "not-supported");
  },

  async runDiagnostic(_config, _identity, target = "8.8.8.8"): Promise<CpeDiagnosticResult> {
    return {
      origin: "cpe",
      driver: "sgp",
      target,
      pingMs: null,
      packetLossPercent: null,
      downloadMbps: null,
      uploadMbps: null,
      verdict: "unavailable",
      summary: "Diagnóstico TR-143 direto no roteador requer integração com GenieACS ou Anlix Flashman.",
      measuredAt: new Date().toISOString(),
    };
  },
};
