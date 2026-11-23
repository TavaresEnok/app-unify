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

type GenieObj = Record<string, any>;

function val(node: any): any {
  if (node && typeof node === "object" && "_value" in node) return node._value;
  return node;
}

function getPath(obj: GenieObj, path: string): any {
  const parts = path.split(".");
  let cur: any = obj;
  for (const part of parts) {
    if (!cur || typeof cur !== "object") return undefined;
    cur = cur[part];
  }
  return val(cur);
}

function numericKeys(obj: any): string[] {
  if (!obj || typeof obj !== "object") return [];
  return Object.keys(obj).filter((k) => /^\d+$/.test(k)).sort((a, b) => Number(a) - Number(b));
}

function normalizeMac(raw: string): string {
  return String(raw || "").trim().toUpperCase().replace(/[^0-9A-F]/g, "").replace(/(.{2})(?=.)/g, "$1:");
}

function toNum(v: unknown): number | null {
  if (v == null || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

async function createGenieClient(config: AcsPrivateConfig): Promise<AxiosInstance> {
  const baseUrl = config.url.trim().replace(/\/+$/, "");
  if (!baseUrl) throw new ApiError(400, "URL do GenieACS não configurada.", "invalid-argument");
  await sgpOutbound.assertSafeSgpBaseUrl(baseUrl);
  const headers: Record<string, string> = { Accept: "application/json" };
  if (config.apiKey) {
    headers["X-API-Key"] = config.apiKey;
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

async function findGenieDevice(client: AxiosInstance, identity: CpeIdentity): Promise<GenieObj> {
  const clauses: Record<string, unknown>[] = [];
  if (identity.serial) {
    clauses.push({ "_deviceId._SerialNumber": identity.serial });
    clauses.push({ "_deviceId._SerialNumber": identity.serial.toUpperCase() });
  }
  if (identity.pppoeLogin) {
    clauses.push({ "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANPPPConnection.1.Username._value": identity.pppoeLogin });
    clauses.push({ "Device.PPP.Interface.1.Username._value": identity.pppoeLogin });
    clauses.push({ "VirtualParameters.pppoeUsername._value": identity.pppoeLogin });
  }
  if (identity.mac) {
    const mac = normalizeMac(identity.mac);
    clauses.push({ "InternetGatewayDevice.LANDevice.1.LANEthernetInterfaceConfig.1.MACAddress._value": mac });
    clauses.push({ "Device.Ethernet.Interface.1.MACAddress._value": mac });
    clauses.push({ "VirtualParameters.mac._value": mac });
  }
  if (!clauses.length) {
    throw new ApiError(404, "Cliente sem serial, MAC ou login PPPoE sincronizado para localizar o roteador no GenieACS.", "not-found");
  }
  const query = JSON.stringify({ $or: clauses });
  const res = await client.get<GenieObj[]>("/devices", { params: { query } });
  const list = Array.isArray(res.data) ? res.data : [];
  if (!list.length) {
    throw new ApiError(404, "Roteador deste assinante não encontrado no GenieACS.", "not-found");
  }
  return list[0];
}

export function extractGenieWifiNetworks(device: GenieObj): CpeWifiNetwork[] {
  const out: CpeWifiNetwork[] = [];

  // TR-098: InternetGatewayDevice.LANDevice.1.WLANConfiguration.{i}
  const tr098Wlans = device?.InternetGatewayDevice?.LANDevice?.["1"]?.WLANConfiguration;
  for (const idx of numericKeys(tr098Wlans)) {
    const w = tr098Wlans[idx];
    const ssid = String(val(w?.SSID) || "").trim();
    if (!ssid && val(w?.Enable) === undefined) continue;
    const channel = String(val(w?.Channel) ?? "Auto");
    const std = String(val(w?.Standard) || val(w?.OperatingFrequencyBand) || "").toLowerCase();
    const chNum = Number(channel);
    const band: CpeWifiNetwork["band"] =
      std.includes("5") || std.includes("ac") || std.includes("ax") || (Number.isFinite(chNum) && chNum >= 36)
        ? "5GHz"
        : "2.4GHz";
    const isGuest = /guest|visitante/i.test(ssid) || Number(idx) === 2 || Number(idx) === 6;
    out.push({
      id: `tr098:${idx}`,
      ssid: ssid || `Wi-Fi ${band} #${idx}`,
      band,
      channel,
      enabled: val(w?.Enable) !== false && val(w?.Enable) !== "false",
      isGuest,
      encryption: String(val(w?.BeaconType) || val(w?.WPAEncryptionModes) || "WPA2"),
    });
  }

  // TR-181: Device.WiFi.SSID.{i}
  if (!out.length) {
    const tr181Ssids = device?.Device?.WiFi?.SSID;
    const radios = device?.Device?.WiFi?.Radio || {};
    for (const idx of numericKeys(tr181Ssids)) {
      const s = tr181Ssids[idx];
      const ssid = String(val(s?.SSID) || "").trim();
      if (!ssid && val(s?.Enable) === undefined) continue;
      const lower = String(val(s?.LowerLayers) || "");
      const radioMatch = lower.match(/Radio\.(\d+)/);
      const radio = radioMatch ? radios[radioMatch[1]] : radios[idx];
      const bandStr = String(val(radio?.OperatingFrequencyBand) || "").toLowerCase();
      const channel = String(val(radio?.Channel) ?? "Auto");
      const chNum = Number(channel);
      const band: CpeWifiNetwork["band"] =
        bandStr.includes("5") || (Number.isFinite(chNum) && chNum >= 36) ? "5GHz" : "2.4GHz";
      out.push({
        id: `tr181:${idx}`,
        ssid: ssid || `Wi-Fi ${band} #${idx}`,
        band,
        channel,
        enabled: val(s?.Enable) !== false && val(s?.Enable) !== "false",
        isGuest: /guest|visitante/i.test(ssid),
      });
    }
  }

  return out;
}

export function extractGenieLanPorts(device: GenieObj): CpeLanPort[] {
  const ports: CpeLanPort[] = [];
  const tr098Eth = device?.InternetGatewayDevice?.LANDevice?.["1"]?.LANEthernetInterfaceConfig;
  for (const idx of numericKeys(tr098Eth)) {
    const p = tr098Eth[idx];
    const status = String(val(p?.Status) || "Down");
    const rawSpeed = toNum(val(p?.MaxBitRate));
    ports.push({
      name: `LAN ${idx}`,
      status,
      speedMbps: rawSpeed != null && rawSpeed > 10_000 ? Math.round(rawSpeed / 1_000_000) : rawSpeed,
    });
  }
  if (!ports.length) {
    const tr181Eth = device?.Device?.Ethernet?.Interface;
    for (const idx of numericKeys(tr181Eth)) {
      const p = tr181Eth[idx];
      if (val(p?.Upstream) === true) continue;
      const status = String(val(p?.Status) || "Down");
      const rawSpeed = toNum(val(p?.CurrentBitRate) ?? val(p?.MaxBitRate));
      ports.push({
        name: String(val(p?.Name) || `LAN ${idx}`),
        status,
        speedMbps: rawSpeed != null && rawSpeed > 10_000 ? Math.round(rawSpeed / 1_000_000) : rawSpeed,
      });
    }
  }
  return ports;
}

export function extractGenieHosts(device: GenieObj): CpeConnectedHost[] {
  // Mapeia MAC -> { band, rssi } a partir de AssociatedDevice (TR-098)
  const wifiAssoc = new Map<string, { band: "wifi_2g" | "wifi_5g"; rssi: number | null }>();
  const wlans = device?.InternetGatewayDevice?.LANDevice?.["1"]?.WLANConfiguration;
  for (const idx of numericKeys(wlans)) {
    const w = wlans[idx];
    const std = String(val(w?.Standard) || val(w?.OperatingFrequencyBand) || "").toLowerCase();
    const ch = Number(val(w?.Channel));
    const band: "wifi_2g" | "wifi_5g" =
      std.includes("5") || std.includes("ac") || std.includes("ax") || (Number.isFinite(ch) && ch >= 36)
        ? "wifi_5g"
        : "wifi_2g";
    const assoc = w?.AssociatedDevice;
    for (const aIdx of numericKeys(assoc)) {
      const dev = assoc[aIdx];
      const mac = normalizeMac(val(dev?.AssociatedDeviceMACAddress) || "");
      if (!mac) continue;
      const rssi = toNum(val(dev?.X_HW_RSSI) ?? val(dev?.SignalStrength) ?? val(dev?.RSSI));
      wifiAssoc.set(mac, { band, rssi });
    }
  }

  const hosts: CpeConnectedHost[] = [];
  const rawHosts =
    device?.InternetGatewayDevice?.LANDevice?.["1"]?.Hosts?.Host ||
    device?.Device?.Hosts?.Host;

  for (const idx of numericKeys(rawHosts)) {
    const h = rawHosts[idx];
    const active = val(h?.Active) !== false && val(h?.Active) !== "false";
    if (!active) continue;
    const mac = normalizeMac(val(h?.MACAddress) || val(h?.PhysAddress) || "");
    const ip = String(val(h?.IPAddress) || "");
    const hostname = String(val(h?.HostName) || "").trim() || mac || ip || "Dispositivo";
    const ifaceRaw = String(val(h?.InterfaceType) || val(h?.Layer1Interface) || "").toLowerCase();
    const assocInfo = mac ? wifiAssoc.get(mac) : undefined;

    let interfaceType: CpeConnectedHost["interfaceType"] = "unknown";
    if (assocInfo) {
      interfaceType = assocInfo.band;
    } else if (ifaceRaw.includes("eth")) {
      interfaceType = "ethernet";
    } else if (ifaceRaw.includes("802.11") || ifaceRaw.includes("wifi") || ifaceRaw.includes("wlan")) {
      interfaceType = ifaceRaw.includes("5") ? "wifi_5g" : "wifi_2g";
    }

    const rssiDbm = assocInfo?.rssi ?? toNum(val(h?.X_HW_RSSI) ?? val(h?.SignalStrength));
    hosts.push({
      hostname,
      mac,
      ip,
      interfaceType,
      rssiDbm,
      signalQuality: classifySignalQuality(interfaceType, rssiDbm),
      active,
    });
  }
  return hosts;
}

export function buildGenieOverview(device: GenieObj, identity: CpeIdentity): CpeStatusOverview {
  const wifiNetworks = extractGenieWifiNetworks(device);
  const lanPorts = extractGenieLanPorts(device);
  const hosts = extractGenieHosts(device);
  const lastInformRaw = device?._lastInform;
  const lastInform = lastInformRaw ? new Date(lastInformRaw).toISOString() : null;
  const online = lastInform ? Date.now() - Date.parse(lastInform) < 15 * 60_000 : false;
  const wanIp = String(
    getPath(device, "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANPPPConnection.1.ExternalIPAddress") ||
    getPath(device, "InternetGatewayDevice.WANDevice.1.WANConnectionDevice.1.WANIPConnection.1.ExternalIPAddress") ||
    getPath(device, "Device.IP.Interface.1.IPv4Address.1.IPAddress") ||
    getPath(device, "VirtualParameters.wanIp") ||
    "",
  );
  const opticalRxDbm = toNum(
    getPath(device, "InternetGatewayDevice.WANDevice.1.X_GponInterafceConfig.RXPower") ??
    getPath(device, "InternetGatewayDevice.WANDevice.1.X_HW_GponInterfaceConfig.RXPower") ??
    getPath(device, "Device.Optical.Interface.1.OpticalSignalLevel") ??
    getPath(device, "VirtualParameters.rxPower"),
  );
  return {
    online,
    driver: "genieacs",
    deviceId: String(device?._id || ""),
    manufacturer: String(device?._deviceId?._Manufacturer || getPath(device, "InternetGatewayDevice.DeviceInfo.Manufacturer") || getPath(device, "Device.DeviceInfo.Manufacturer") || ""),
    model: String(device?._deviceId?._ProductClass || getPath(device, "InternetGatewayDevice.DeviceInfo.ModelName") || getPath(device, "Device.DeviceInfo.ModelName") || ""),
    serial: String(device?._deviceId?._SerialNumber || identity.serial || ""),
    mac: normalizeMac(
      getPath(device, "InternetGatewayDevice.LANDevice.1.LANEthernetInterfaceConfig.1.MACAddress") ||
      getPath(device, "Device.Ethernet.Interface.1.MACAddress") ||
      identity.mac ||
      "",
    ),
    firmware: String(getPath(device, "InternetGatewayDevice.DeviceInfo.SoftwareVersion") || getPath(device, "Device.DeviceInfo.SoftwareVersion") || ""),
    uptimeSeconds: toNum(getPath(device, "InternetGatewayDevice.DeviceInfo.UpTime") ?? getPath(device, "Device.DeviceInfo.UpTime")),
    wanIp,
    opticalRxDbm,
    lanPorts,
    lanBottleneck100Mbps: detectLanBottleneck100Mbps(lanPorts, identity.planDownloadMbps),
    planDownloadMbps: identity.planDownloadMbps,
    wifiNetworks,
    hostsCount: hosts.length,
    lastInform,
  };
}

export const genieacsDriver: Tr069Driver = {
  async testConnection(config) {
    const client = await createGenieClient(config);
    const res = await client.get<GenieObj[]>("/devices", { params: { projection: "_id", limit: 1 } });
    const count = Array.isArray(res.data) ? res.data.length : 0;
    return {
      ok: true,
      message: "Conexão com GenieACS NBI validada com sucesso.",
      devicesSample: count,
    };
  },

  async getOverview(config, identity) {
    const client = await createGenieClient(config);
    const device = await findGenieDevice(client, identity);
    return buildGenieOverview(device, identity);
  },

  async listHosts(config, identity) {
    const client = await createGenieClient(config);
    const device = await findGenieDevice(client, identity);
    return extractGenieHosts(device);
  },

  async updateWifi(config, identity, input: CpeWifiUpdateInput) {
    const client = await createGenieClient(config);
    const device = await findGenieDevice(client, identity);
    const deviceId = encodeURIComponent(String(device._id));
    const [modelType, idx] = input.wifiId.includes(":") ? input.wifiId.split(":") : ["tr098", input.wifiId];
    const params: Array<[string, string | boolean | number, string]> = [];

    if (modelType === "tr181") {
      if (input.ssid) params.push([`Device.WiFi.SSID.${idx}.SSID`, input.ssid.trim(), "xsd:string"]);
      if (typeof input.enabled === "boolean") params.push([`Device.WiFi.SSID.${idx}.Enable`, input.enabled, "xsd:boolean"]);
      if (input.password) params.push([`Device.WiFi.AccessPoint.${idx}.Security.KeyPassphrase`, input.password, "xsd:string"]);
      if (input.channel && /^\d+$/.test(input.channel)) params.push([`Device.WiFi.Radio.${idx}.Channel`, Number(input.channel), "xsd:unsignedInt"]);
    } else {
      const base = `InternetGatewayDevice.LANDevice.1.WLANConfiguration.${idx}`;
      if (input.ssid) params.push([`${base}.SSID`, input.ssid.trim(), "xsd:string"]);
      if (typeof input.enabled === "boolean") params.push([`${base}.Enable`, input.enabled, "xsd:boolean"]);
      if (input.password) {
        params.push([`${base}.PreSharedKey.1.KeyPassphrase`, input.password, "xsd:string"]);
        params.push([`${base}.KeyPassphrase`, input.password, "xsd:string"]);
      }
      if (input.channel && /^\d+$/.test(input.channel)) {
        params.push([`${base}.AutoChannelEnable`, false, "xsd:boolean"]);
        params.push([`${base}.Channel`, Number(input.channel), "xsd:unsignedInt"]);
      }
    }

    if (!params.length) {
      throw new ApiError(400, "Nenhum parâmetro de Wi-Fi informado para atualização.", "invalid-argument");
    }

    await client.post(`/devices/${deviceId}/tasks`, {
      name: "setParameterValues",
      parameterValues: params,
    }, { params: { connection_request: "" } });

    return { success: true, message: "Configuração Wi-Fi enviada ao roteador via GenieACS." };
  },

  async reboot(config, identity) {
    const client = await createGenieClient(config);
    const device = await findGenieDevice(client, identity);
    const deviceId = encodeURIComponent(String(device._id));
    await client.post(`/devices/${deviceId}/tasks`, { name: "reboot" }, { params: { connection_request: "" } });
    return { success: true, message: "Comando de reinicialização enviado ao roteador. Aguarde ~2 minutos." };
  },

  async optimizeWifi(config, identity) {
    const client = await createGenieClient(config);
    const device = await findGenieDevice(client, identity);
    const deviceId = encodeURIComponent(String(device._id));
    const wlans = extractGenieWifiNetworks(device);
    const parameterValues: Array<[string, boolean, string]> = [];

    for (const w of wlans) {
      if (w.isGuest) continue;
      const [modelType, idx] = w.id.split(":");
      if (modelType === "tr181") {
        parameterValues.push([`Device.WiFi.Radio.${idx}.AutoChannelEnable`, true, "xsd:boolean"]);
      } else {
        parameterValues.push([`InternetGatewayDevice.LANDevice.1.WLANConfiguration.${idx}.AutoChannelEnable`, true, "xsd:boolean"]);
      }
    }
    if (!parameterValues.length) {
      parameterValues.push(["InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.AutoChannelEnable", true, "xsd:boolean"]);
    }

    await client.post(`/devices/${deviceId}/tasks`, {
      name: "setParameterValues",
      parameterValues,
    }, { params: { connection_request: "" } });
    return { success: true, message: "Otimização automática de canal Wi-Fi solicitada ao roteador." };
  },

  async runDiagnostic(config, identity, target = "8.8.8.8"): Promise<CpeDiagnosticResult> {
    const client = await createGenieClient(config);
    const device = await findGenieDevice(client, identity);
    const deviceId = encodeURIComponent(String(device._id));
    const isTr181 = Boolean(device?.Device?.IP?.Diagnostics);
    const pingBase = isTr181 ? "Device.IP.Diagnostics.IPPing" : "InternetGatewayDevice.IPPingDiagnostics";

    await client.post(`/devices/${deviceId}/tasks`, {
      name: "setParameterValues",
      parameterValues: [
        [`${pingBase}.Host`, target, "xsd:string"],
        [`${pingBase}.NumberOfRepetitions`, 4, "xsd:unsignedInt"],
        [`${pingBase}.Timeout`, 3000, "xsd:unsignedInt"],
        [`${pingBase}.DiagnosticsState`, "Requested", "xsd:string"],
      ],
    }, { params: { connection_request: "" } });

    // Releitura breve do estado reportado pelo CPE
    const refreshed = await findGenieDevice(client, identity).catch(() => device);
    const avgPing = toNum(getPath(refreshed, `${pingBase}.AverageResponseTime`));
    const okCount = toNum(getPath(refreshed, `${pingBase}.SuccessCount`)) ?? 0;
    const failCount = toNum(getPath(refreshed, `${pingBase}.FailureCount`)) ?? 0;
    const total = okCount + failCount;
    const lossPercent = total > 0 ? Math.round((failCount / total) * 100) : null;

    const dlBytes = toNum(getPath(refreshed, "InternetGatewayDevice.DownloadDiagnostics.TotalBytesReceived"));
    const dlStart = getPath(refreshed, "InternetGatewayDevice.DownloadDiagnostics.BOMTime");
    const dlEnd = getPath(refreshed, "InternetGatewayDevice.DownloadDiagnostics.EOMTime");
    let downloadMbps: number | null = null;
    if (dlBytes && dlStart && dlEnd) {
      const secs = (Date.parse(String(dlEnd)) - Date.parse(String(dlStart))) / 1000;
      if (secs > 0) downloadMbps = Number(((dlBytes * 8) / (secs * 1_000_000)).toFixed(1));
    }

    const verdict: CpeDiagnosticResult["verdict"] =
      avgPing == null ? "unavailable" : (lossPercent != null && lossPercent > 5) || avgPing > 80 ? "attention" : "ok";

    return {
      origin: "cpe",
      driver: "genieacs",
      target,
      pingMs: avgPing,
      packetLossPercent: lossPercent,
      downloadMbps,
      uploadMbps: null,
      verdict,
      summary: avgPing != null
        ? `Roteador respondeu ping para ${target} em ${avgPing} ms (perda ${lossPercent ?? 0}%).`
        : "Diagnóstico TR-143 disparado no roteador; os valores serão atualizados no próximo inform.",
      measuredAt: new Date().toISOString(),
    };
  },
};
