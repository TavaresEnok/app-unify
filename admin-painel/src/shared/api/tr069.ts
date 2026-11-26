import { clearPanelReads, panelRequest } from './panelHttp';

export type AcsDriverType = 'none' | 'sgp' | 'genieacs' | 'flashman';

export interface AcsFeatureFlags {
  wifi: boolean;
  reboot: boolean;
  hosts: boolean;
  guestWifi: boolean;
  channelOptimize: boolean;
  speedDiagnostic: boolean;
}

export interface AcsConfigSummary {
  driver: AcsDriverType;
  enabled: boolean;
  url: string;
  username: string;
  hasPassword: boolean;
  hasApiKey: boolean;
  features: AcsFeatureFlags;
  updatedAt: string | null;
}

export interface CpeWifiNetwork {
  id: string;
  ssid: string;
  band: '2.4GHz' | '5GHz' | 'dual';
  channel: string;
  enabled: boolean;
  isGuest: boolean;
}

export interface CpeConnectedHost {
  hostname: string;
  mac: string;
  ip: string;
  interfaceType: 'wifi_2g' | 'wifi_5g' | 'ethernet' | 'unknown';
  rssiDbm: number | null;
  signalQuality: 'excellent' | 'good' | 'fair' | 'weak' | 'wired' | 'unknown';
  active: boolean;
}

export interface CpeLanPort {
  name: string;
  status: string;
  speedMbps: number | null;
}

export interface CpeStatusOverview {
  /** null quando o gerenciador não sabe o estado ao vivo (ex.: SGP CPE Manager). */
  online: boolean | null;
  /** Quando os dados do roteador foram capturados (null = leitura ao vivo). */
  snapshotAt?: string | null;
  driver: Exclude<AcsDriverType, 'none'>;
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
}

export interface AdminCpeOverviewResponse {
  enabled: boolean;
  driver: AcsDriverType;
  features?: Partial<AcsFeatureFlags>;
  overview: CpeStatusOverview | null;
  hosts: CpeConnectedHost[];
}

export interface CpeDiagnosticResult {
  origin: 'cpe';
  driver: Exclude<AcsDriverType, 'none'>;
  target: string;
  pingMs: number | null;
  packetLossPercent: number | null;
  downloadMbps: number | null;
  uploadMbps: number | null;
  verdict: 'ok' | 'attention' | 'unavailable';
  summary: string;
  measuredAt: string;
}

export async function fetchAcsConfig(providerId: string): Promise<AcsConfigSummary> {
  const params = new URLSearchParams({ providerId });
  const res = await panelRequest<{ data: AcsConfigSummary }>(`/admin/tr069/config?${params.toString()}`);
  return res.data;
}

export async function saveAcsConfig(
  providerId: string,
  payload: {
    driver: AcsDriverType;
    enabled: boolean;
    url?: string;
    username?: string;
    password?: string;
    apiKey?: string;
    features: AcsFeatureFlags;
  },
): Promise<{ success: boolean; message: string; data: AcsConfigSummary }> {
  const res = await panelRequest<{ success: boolean; message: string; data: AcsConfigSummary }>(
    '/admin/tr069/config',
    { method: 'PUT', body: { providerId, ...payload } },
  );
  clearPanelReads();
  return res;
}

export async function testAcsConnection(
  providerId: string,
): Promise<{ success: boolean; data: { ok: boolean; message: string; devicesSample?: number } }> {
  return panelRequest('/admin/tr069/test', { method: 'POST', body: { providerId } });
}

export async function fetchAdminClientCpeOverview(
  providerId: string,
  identifier: string,
): Promise<AdminCpeOverviewResponse> {
  const params = new URLSearchParams({ providerId });
  const res = await panelRequest<{ data: AdminCpeOverviewResponse }>(
    `/admin/tr069/clients/${encodeURIComponent(identifier)}/overview?${params.toString()}`,
  );
  return res.data;
}

export async function rebootAdminClientCpe(
  providerId: string,
  identifier: string,
): Promise<{ success: boolean; message: string }> {
  return panelRequest(`/admin/tr069/clients/${encodeURIComponent(identifier)}/reboot`, {
    method: 'POST',
    body: { providerId },
  });
}

export async function optimizeAdminClientWifi(
  providerId: string,
  identifier: string,
): Promise<{ success: boolean; message: string }> {
  return panelRequest(`/admin/tr069/clients/${encodeURIComponent(identifier)}/optimize-wifi`, {
    method: 'POST',
    body: { providerId },
  });
}

export async function runAdminClientCpeDiagnostic(
  providerId: string,
  identifier: string,
  target = '8.8.8.8',
): Promise<CpeDiagnosticResult> {
  const res = await panelRequest<{ data: CpeDiagnosticResult }>(
    `/admin/tr069/clients/${encodeURIComponent(identifier)}/diagnostic`,
    { method: 'POST', body: { providerId, target } },
  );
  return res.data;
}

/** Recursos que o SGP CPE Manager não executa (ver DRIVER_LIMITS no api-service). */
const SGP_UNSUPPORTED: ReadonlyArray<keyof AcsFeatureFlags> = ['reboot', 'channelOptimize', 'speedDiagnostic', 'guestWifi'];

/** Recursos que o driver escolhido consegue executar. */
export function driverSupportsFeature(driver: AcsDriverType, feature: keyof AcsFeatureFlags): boolean {
  if (driver === 'none') return false;
  if (driver === 'sgp') return !SGP_UNSUPPORTED.includes(feature);
  return true;
}

export interface CpeActionAvailability {
  reboot: boolean;
  optimize: boolean;
  diagnostic: boolean;
}

/**
 * Quais ações N1 mostrar para o roteador. Usa `features` devolvido pelo servidor;
 * sem ele (API antiga), cai nos limites conhecidos do driver.
 * Super Admin acessa a base do provedor só para consulta.
 */
export function cpeActionAvailability(data: AdminCpeOverviewResponse | null, readOnly = false): CpeActionAvailability {
  const none = { reboot: false, optimize: false, diagnostic: false };
  if (readOnly || !data?.enabled || !data.overview) return none;
  const allowed = (feature: keyof AcsFeatureFlags) => {
    const flag = data.features?.[feature];
    if (typeof flag === 'boolean') return flag && driverSupportsFeature(data.driver, feature);
    return driverSupportsFeature(data.driver, feature);
  };
  return { reboot: allowed('reboot'), optimize: allowed('channelOptimize'), diagnostic: allowed('speedDiagnostic') };
}
