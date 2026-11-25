import { ApiError } from "../../../middlewares/errorHandler";
import { proxyToSgp } from "../../proxySgpClient";
import { createSgpSession, resolveSgpCredentials } from "../../sgpClient";
import {
  classifySignalQuality,
  type CpeConnectedHost,
  type CpeDiagnosticResult,
  type CpeIdentity,
  type CpeStatusOverview,
  type CpeWifiNetwork,
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
};
type ProxyCpeList = { networks: CpeWifiNetwork[]; device: ProxyCpeDevice | null; servicoId: string };

function mapSgpWifi(rawList: unknown): CpeWifiNetwork[] {
  if (!Array.isArray(rawList)) return [];
  return rawList.map((item: any, idx) => {
    const freq = String(item?.frequency || item?.band || item?.frequencia || "").toLowerCase();
    const band: CpeWifiNetwork["band"] = freq.includes("5") ? "5GHz" : "2.4GHz";
    const ssid = String(item?.ssid || item?.name || `Wi-Fi ${idx + 1}`);
    return {
      id: String(item?.id ?? item?.wifi_id ?? idx + 1),
      ssid,
      band,
      channel: String(item?.channel || item?.canal || "Auto"),
      enabled: item?.enabled !== false && item?.active !== false,
      isGuest: /guest|visitante/i.test(ssid),
    };
  });
}

function mapHost(h: ProxyCpeHost): CpeConnectedHost {
  const interfaceType: CpeConnectedHost["interfaceType"] =
    h?.interfaceType === "wifi_2g" || h?.interfaceType === "wifi_5g" || h?.interfaceType === "ethernet" ? h.interfaceType : "unknown";
  const rssiDbm = typeof h?.rssiDbm === "number" && Number.isFinite(h.rssiDbm) ? h.rssiDbm : null;
  return {
    hostname: String(h?.hostname || h?.mac || "Dispositivo"),
    mac: String(h?.mac || "").toUpperCase(),
    ip: String(h?.ip || ""),
    interfaceType,
    rssiDbm,
    signalQuality: classifySignalQuality(interfaceType, rssiDbm),
    active: true,
  };
}

// O proxy resolve o ID do serviço (o CPE Manager do SGP não aceita o ID do
// contrato), confirma a posse do contrato e normaliza a resposta real.
async function fetchCpeList(identity: CpeIdentity): Promise<ProxyCpeList> {
  if (!identity.contratoId) {
    throw new ApiError(404, "Contrato não localizado para consulta no SGP CPE Manager.", "not-found");
  }
  const res = await proxyToSgp("/cpe/wifi/list", {
    cpfCnpj: identity.cpfCnpj,
    contrato: identity.contratoId,
    providerId: identity.providerId,
  }, identity.authHeader);
  const body = (res.data ?? {}) as Record<string, any>;
  if (res.status >= 400) {
    throw new ApiError(res.status, body?.error?.message || "SGP CPE Manager indisponível para este contrato.", "upstream-error");
  }
  return {
    networks: mapSgpWifi(body?.data ?? body),
    device: body?.device && typeof body.device === "object" ? body.device as ProxyCpeDevice : null,
    servicoId: typeof body?.servicoId === "string" ? body.servicoId : "",
  };
}

export const sgpDriver: Tr069Driver = {
  async testConnection(config) {
    return {
      ok: config.enabled,
      message: "Driver SGP CPE Manager ativo — utiliza a integração SGP já cadastrada do provedor.",
    };
  },

  async getOverview(_config, identity): Promise<CpeStatusOverview> {
    const { networks, device } = await fetchCpeList(identity);
    const hosts = (device?.hosts ?? []).map(mapHost);
    return {
      online: Boolean(device) || networks.length > 0,
      driver: "sgp",
      deviceId: identity.serial || identity.contratoId,
      manufacturer: device?.manufacturer || "",
      model: device?.model || "CPE gerenciada via SGP",
      serial: identity.serial,
      mac: identity.mac,
      firmware: device?.firmware || "",
      uptimeSeconds: device?.wanUptimeSeconds ?? null,
      wanIp: device?.wanIp || "",
      opticalRxDbm: null,
      lanPorts: [],
      lanBottleneck100Mbps: false,
      planDownloadMbps: identity.planDownloadMbps,
      wifiNetworks: networks,
      hostsCount: hosts.length,
      lastInform: new Date().toISOString(),
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
    const res = await proxyToSgp("/cpe/wifi/update", {
      cpfCnpj: identity.cpfCnpj,
      contrato: identity.contratoId,
      providerId: identity.providerId,
      wifiId: input.wifiId,
      ssid: input.ssid || "",
      password: input.password || "",
    }, identity.authHeader);
    const body = (res.data ?? {}) as Record<string, any>;
    if (res.status >= 400) {
      throw new ApiError(res.status, body?.error?.message || "Não foi possível atualizar o Wi-Fi via SGP.", "upstream-error");
    }
    return { success: true, message: "Configuração Wi-Fi enviada via SGP CPE Manager." };
  },

  async reboot(_config, identity) {
    if (!identity.contratoId) {
      throw new ApiError(400, "Contrato obrigatório para reiniciar CPE via SGP.", "invalid-argument");
    }
    const { servicoId } = await fetchCpeList(identity);
    if (!servicoId) {
      throw new ApiError(404, "Serviço de internet não localizado no SGP para este contrato.", "not-found");
    }
    const creds = await resolveSgpCredentials(identity.providerId);
    const session = createSgpSession(creds.providerId, creds.baseUrl, creds);
    try {
      await session.post(`${creds.baseUrl}/api/cpemanager/servico/${servicoId}/reboot/`, {
        token: creds.token,
        app: creds.app,
      });
      return { success: true, message: "Comando de reinicialização enviado via SGP CPE Manager." };
    } catch {
      throw new ApiError(501, "Esta versão do SGP CPE Manager não expõe reinicialização remota; configure GenieACS ou Flashman para reboot completo.", "not-implemented");
    }
  },

  async optimizeWifi() {
    throw new ApiError(501, "Otimização automática de canal requer integração direta com GenieACS ou Anlix Flashman.", "not-implemented");
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
