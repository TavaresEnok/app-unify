import axios, { type AxiosInstance } from "axios";
import sgpOutbound from "../../sgp-outbound";
import { ApiError } from "../../../middlewares/errorHandler";
import {
  classifySignalQuality,
  detectLanBottleneck100Mbps,
  type AcsPrivateConfig,
  type CpeConnectedHost,
  type CpeDiagnosticResult,
  type CpeIdentity,
  type CpeLanPort,
  type CpeStatusOverview,
  type CpeWifiNetwork,
  type CpeWifiUpdateInput,
  type Tr069Driver,
} from "../types";

type FlashmanDevice = Record<string, any>;

function toNum(v: unknown): number | null {
  if (v == null || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

async function createFlashmanClient(config: AcsPrivateConfig): Promise<AxiosInstance> {
  const baseUrl = config.url.trim().replace(/\/+$/, "");
  if (!baseUrl) throw new ApiError(400, "URL do Anlix Flashman não configurada.", "invalid-argument");
  await sgpOutbound.assertSafeSgpBaseUrl(baseUrl);
  const headers: Record<string, string> = { Accept: "application/json" };
  if (config.apiKey) {
    headers.Authorization = `Bearer ${config.apiKey}`;
  } else if (config.username || config.password) {
    const basic = Buffer.from(`${config.username}:${config.password}`).toString("base64");
    headers.Authorization = `Basic ${basic}`;
  }
  return axios.create({
    baseURL: baseUrl,
    timeout: 12_000,
    headers,
    maxRedirects: 0,
  });
}

async function findFlashmanDevice(client: AxiosInstance, identity: CpeIdentity): Promise<FlashmanDevice> {
  const query = identity.mac || identity.serial || identity.pppoeLogin;
  if (!query) {
    throw new ApiError(404, "Cliente sem MAC, serial ou login PPPoE sincronizado para localizar no Flashman.", "not-found");
  }
  const res = await client.put("/api/v2/device/search", { filter_list: query });
  const devices: FlashmanDevice[] = Array.isArray(res.data?.devices)
    ? res.data.devices
    : Array.isArray(res.data)
      ? res.data
      : [];
  if (!devices.length) {
    throw new ApiError(404, "Roteador deste assinante não encontrado no Anlix Flashman.", "not-found");
  }
  return devices[0];
}

export function extractFlashmanWifi(dev: FlashmanDevice): CpeWifiNetwork[] {
  const out: CpeWifiNetwork[] = [];
  if (dev.wifi_ssid) {
    out.push({
      id: "2g",
      ssid: String(dev.wifi_ssid),
      band: "2.4GHz",
      channel: String(dev.wifi_channel || "auto"),
      enabled: dev.wifi_state !== 0 && dev.wifi_state !== false,
      isGuest: false,
    });
  }
  if (dev.wifi_is_5ghz_capable !== false && dev.wifi_ssid_5ghz) {
    out.push({
      id: "5g",
      ssid: String(dev.wifi_ssid_5ghz),
      band: "5GHz",
      channel: String(dev.wifi_channel_5ghz || "auto"),
      enabled: dev.wifi_state_5ghz !== 0 && dev.wifi_state_5ghz !== false,
      isGuest: false,
    });
  }
  return out;
}

export function extractFlashmanHosts(dev: FlashmanDevice): CpeConnectedHost[] {
  const raw: any[] = Array.isArray(dev.lan_devices) ? dev.lan_devices : [];
  return raw
    .filter((d) => d && d.is_online !== false)
    .map((d) => {
      const conn = String(d.conn_type ?? "").toLowerCase();
      const interfaceType: CpeConnectedHost["interfaceType"] =
        conn === "0" || conn.includes("cable") || conn.includes("eth")
          ? "ethernet"
          : d.wifi_freq === 5 || String(d.wifi_freq || "").includes("5")
            ? "wifi_5g"
            : conn === "1" || conn.includes("wifi")
              ? "wifi_2g"
              : "unknown";
      const rssiDbm = toNum(d.wifi_signal ?? d.rssi);
      return {
        hostname: String(d.dhcp_name || d.name || d.mac || "Dispositivo"),
        mac: String(d.mac || "").toUpperCase(),
        ip: String(d.ip || ""),
        interfaceType,
        rssiDbm,
        signalQuality: classifySignalQuality(interfaceType, rssiDbm),
        active: true,
      };
    });
}

export function buildFlashmanOverview(dev: FlashmanDevice, identity: CpeIdentity): CpeStatusOverview {
  const hosts = extractFlashmanHosts(dev);
  const lanPorts: CpeLanPort[] = [];
  if (Array.isArray(dev.lan_devices)) {
    const wired = dev.lan_devices.filter((d: any) => String(d?.conn_type) === "0" && toNum(d?.conn_speed) != null);
    wired.forEach((d: any, idx: number) => {
      lanPorts.push({
        name: `LAN ${idx + 1}`,
        status: "Up",
        speedMbps: toNum(d.conn_speed),
      });
    });
  }
  const lastContact = dev.last_contact ? new Date(dev.last_contact).toISOString() : null;
  const online = lastContact ? Date.now() - Date.parse(lastContact) < 15 * 60_000 : Boolean(dev.is_online);
  return {
    online,
    driver: "flashman",
    deviceId: String(dev._id || dev.mac || ""),
    manufacturer: String(dev.vendor || ""),
    model: String(dev.model || ""),
    serial: String(dev.serial_tr069 || identity.serial || ""),
    mac: String(dev._id || dev.mac || identity.mac || "").toUpperCase(),
    firmware: String(dev.version || ""),
    uptimeSeconds: toNum(dev.sys_up_time),
    wanIp: String(dev.wan_ip || ""),
    opticalRxDbm: toNum(dev.pon_rxpower),
    lanPorts,
    lanBottleneck100Mbps: detectLanBottleneck100Mbps(lanPorts, identity.planDownloadMbps),
    planDownloadMbps: identity.planDownloadMbps,
    wifiNetworks: extractFlashmanWifi(dev),
    hostsCount: hosts.length,
    lastInform: lastContact,
  };
}

export const flashmanDriver: Tr069Driver = {
  async testConnection(config) {
    const client = await createFlashmanClient(config);
    const res = await client.put("/api/v2/device/search", { filter_list: "" });
    const count = Array.isArray(res.data?.devices) ? res.data.devices.length : 0;
    return { ok: true, message: "Conexão com Anlix Flashman validada com sucesso.", devicesSample: count };
  },

  async getOverview(config, identity) {
    const client = await createFlashmanClient(config);
    const dev = await findFlashmanDevice(client, identity);
    return buildFlashmanOverview(dev, identity);
  },

  async listHosts(config, identity) {
    const client = await createFlashmanClient(config);
    const dev = await findFlashmanDevice(client, identity);
    const mac = encodeURIComponent(String(dev._id || dev.mac));
    await client.post(`/api/v2/device/command/${mac}/onlinedevs`).catch(() => undefined);
    return extractFlashmanHosts(dev);
  },

  async updateWifi(config, identity, input: CpeWifiUpdateInput) {
    const client = await createFlashmanClient(config);
    const dev = await findFlashmanDevice(client, identity);
    const mac = encodeURIComponent(String(dev._id || dev.mac));
    const is5g = input.wifiId === "5g";
    const body: Record<string, unknown> = {};
    if (is5g) {
      if (input.ssid) body.wifi_ssid_5ghz = input.ssid.trim();
      if (input.password) body.wifi_password_5ghz = input.password;
      if (typeof input.enabled === "boolean") body.wifi_state_5ghz = input.enabled ? 1 : 0;
      if (input.channel) body.wifi_channel_5ghz = input.channel;
    } else {
      if (input.ssid) body.wifi_ssid = input.ssid.trim();
      if (input.password) body.wifi_password = input.password;
      if (typeof input.enabled === "boolean") body.wifi_state = input.enabled ? 1 : 0;
      if (input.channel) body.wifi_channel = input.channel;
    }
    await client.put(`/api/v2/device/update/${mac}`, body);
    return { success: true, message: "Configuração Wi-Fi enviada ao roteador via Anlix Flashman." };
  },

  async reboot(config, identity) {
    const client = await createFlashmanClient(config);
    const dev = await findFlashmanDevice(client, identity);
    const mac = encodeURIComponent(String(dev._id || dev.mac));
    await client.post(`/api/v2/device/command/${mac}/boot`);
    return { success: true, message: "Reinicialização enviada ao roteador via Flashman. Aguarde ~2 minutos." };
  },

  async optimizeWifi(config, identity) {
    const client = await createFlashmanClient(config);
    const dev = await findFlashmanDevice(client, identity);
    const mac = encodeURIComponent(String(dev._id || dev.mac));
    await client.put(`/api/v2/device/update/${mac}`, {
      wifi_channel: "auto",
      ...(dev.wifi_is_5ghz_capable !== false ? { wifi_channel_5ghz: "auto" } : {}),
    });
    return { success: true, message: "Seleção automática de melhor canal Wi-Fi aplicada via Flashman." };
  },

  async runDiagnostic(config, identity, target = "8.8.8.8"): Promise<CpeDiagnosticResult> {
    const client = await createFlashmanClient(config);
    const dev = await findFlashmanDevice(client, identity);
    const mac = encodeURIComponent(String(dev._id || dev.mac));
    await client.post(`/api/v2/device/command/${mac}/speedtest`).catch(() => undefined);
    const lastSpeed = toNum(dev.last_speedtest?.down_speed);
    const pingMs = toNum(dev.ping_hosts_result?.[0]?.lat);
    return {
      origin: "cpe",
      driver: "flashman",
      target,
      pingMs,
      packetLossPercent: null,
      downloadMbps: lastSpeed,
      uploadMbps: null,
      verdict: lastSpeed != null ? "ok" : "unavailable",
      summary: lastSpeed != null
        ? `Última medição direta no roteador via Flashman: ${lastSpeed} Mbps de download.`
        : "Teste de velocidade disparado no roteador via Flashman.",
      measuredAt: new Date().toISOString(),
    };
  },
};
