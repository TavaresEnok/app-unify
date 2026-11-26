export type AcsDriverType = "none" | "sgp" | "genieacs" | "flashman";

export interface AcsFeatureFlags {
  wifi: boolean;
  reboot: boolean;
  hosts: boolean;
  guestWifi: boolean;
  channelOptimize: boolean;
  speedDiagnostic: boolean;
}

export const DEFAULT_ACS_FEATURES: AcsFeatureFlags = {
  wifi: true,
  reboot: true,
  hosts: true,
  guestWifi: true,
  channelOptimize: true,
  speedDiagnostic: true,
};

export interface AcsPrivateConfig {
  driver: AcsDriverType;
  enabled: boolean;
  url: string;
  username: string;
  password: string;
  apiKey: string;
  features: AcsFeatureFlags;
  updatedAt?: string | null;
}

export interface AcsPublicSummary {
  driver: AcsDriverType;
  enabled: boolean;
  url: string;
  username: string;
  hasPassword: boolean;
  hasApiKey: boolean;
  features: AcsFeatureFlags;
  updatedAt: string | null;
}

export interface CpeIdentity {
  providerId: string;
  cpfCnpj: string;
  contratoId: string;
  serial: string;
  mac: string;
  pppoeLogin: string;
  planName: string;
  planDownloadMbps: number | null;
  authHeader?: string;
}

export interface CpeWifiNetwork {
  id: string;
  ssid: string;
  band: "2.4GHz" | "5GHz" | "dual";
  channel: string;
  enabled: boolean;
  isGuest: boolean;
  encryption?: string;
  /** Padrão do rádio informado pelo roteador (ex.: "ac", "n"). */
  mode?: string;
  bandwidth?: string | null;
}

export interface CpeConnectedHost {
  hostname: string;
  mac: string;
  ip: string;
  interfaceType: "wifi_2g" | "wifi_5g" | "ethernet" | "unknown";
  rssiDbm: number | null;
  signalQuality: "excellent" | "good" | "fair" | "weak" | "wired" | "unknown";
  active: boolean;
}

export interface CpeLanPort {
  name: string;
  status: string;
  speedMbps: number | null;
}

/** Estado da fibra/ONU (contrato 2 de /tr069/status). */
export interface FiberStatus {
  online: boolean | null;
  rxPowerDbm: number | null;
  txPowerDbm: number | null;
  onlineSince: string | null;
  lastDownCause: string | null;
  distanceMeters: number | null;
  /** "olt": leitura ao vivo na OLT; "snapshot": último registro do ERP. */
  source: "olt" | "snapshot";
  updatedAt?: string | null;
}

export interface CpeStatusOverview {
  /** null quando o gerenciador não sabe o estado do roteador ao vivo. */
  online: boolean | null;
  driver: Exclude<AcsDriverType, "none">;
  deviceId: string;
  manufacturer: string;
  model: string;
  serial: string;
  mac: string;
  firmware: string;
  uptimeSeconds: number | null;
  wanIp: string;
  opticalRxDbm: number | null;
  lanPorts: CpeLanPort[];
  lanBottleneck100Mbps: boolean;
  planDownloadMbps: number | null;
  wifiNetworks: CpeWifiNetwork[];
  hostsCount: number;
  lastInform: string | null;
  /** Quando os dados do roteador foram capturados (null = desconhecido). */
  snapshotAt?: string | null;
  fiber?: FiberStatus | null;
  hosts?: CpeConnectedHost[];
  /** false: o roteador não informa a senha salva; o app deve pedir a senha. */
  passwordReadable?: boolean;
  /** false: o serviço deste assinante não tem roteador gerenciado. */
  deviceManaged?: boolean;
}

export interface CpeOverviewOptions {
  /** Consulta ao vivo na OLT (lenta, ~10 s, com cache de 5 min). */
  fiberDetails?: boolean;
}

export interface CpeWifiUpdateInput {
  wifiId: string;
  ssid?: string;
  password?: string;
  enabled?: boolean;
  channel?: string;
}

export interface CpeDiagnosticResult {
  origin: "cpe";
  driver: Exclude<AcsDriverType, "none">;
  target: string;
  pingMs: number | null;
  packetLossPercent: number | null;
  downloadMbps: number | null;
  uploadMbps: number | null;
  verdict: "ok" | "attention" | "unavailable";
  summary: string;
  measuredAt: string;
}

export interface Tr069Driver {
  testConnection(config: AcsPrivateConfig): Promise<{ ok: boolean; message: string; devicesSample?: number }>;
  getOverview(config: AcsPrivateConfig, identity: CpeIdentity, options?: CpeOverviewOptions): Promise<CpeStatusOverview>;
  listHosts(config: AcsPrivateConfig, identity: CpeIdentity): Promise<CpeConnectedHost[]>;
  updateWifi(config: AcsPrivateConfig, identity: CpeIdentity, input: CpeWifiUpdateInput): Promise<{ success: boolean; message: string }>;
  reboot(config: AcsPrivateConfig, identity: CpeIdentity): Promise<{ success: boolean; message: string }>;
  optimizeWifi(config: AcsPrivateConfig, identity: CpeIdentity): Promise<{ success: boolean; message: string }>;
  runDiagnostic(config: AcsPrivateConfig, identity: CpeIdentity, target?: string): Promise<CpeDiagnosticResult>;
}

export function classifySignalQuality(
  interfaceType: CpeConnectedHost["interfaceType"],
  rssiDbm: number | null,
): CpeConnectedHost["signalQuality"] {
  if (interfaceType === "ethernet") return "wired";
  if (rssiDbm == null || !Number.isFinite(rssiDbm)) return "unknown";
  if (rssiDbm >= -55) return "excellent";
  if (rssiDbm >= -67) return "good";
  if (rssiDbm >= -75) return "fair";
  return "weak";
}

export function inferPlanDownloadMbps(planName: string): number | null {
  const clean = String(planName || "").toUpperCase();
  // Aceita "300 MEGAS", "10_mega_pro", "1,5 GIGA", "800MB"; o "_" conta como separador.
  const giga = clean.match(/(\d+(?:[.,]\d+)?)[\s_]*(?:GIGAS?|GBPS|GB|G)(?![A-Z])/);
  if (giga) {
    const val = Number(giga[1].replace(",", "."));
    return Number.isFinite(val) && val > 0 ? Math.round(val * 1000) : null;
  }
  const mega = clean.match(/(\d+(?:[.,]\d+)?)[\s_]*(?:MEGAS?|MBPS|MB|M)(?![A-Z])/);
  if (mega) {
    const val = Number(mega[1].replace(",", "."));
    return Number.isFinite(val) && val > 0 ? Math.round(val) : null;
  }
  return null;
}

export function detectLanBottleneck100Mbps(lanPorts: CpeLanPort[], planDownloadMbps: number | null): boolean {
  if (!planDownloadMbps || planDownloadMbps <= 100) return false;
  return lanPorts.some((p) => {
    const up = /up|connected|ativo|link/i.test(p.status);
    return up && p.speedMbps != null && p.speedMbps > 0 && p.speedMbps <= 100;
  });
}
