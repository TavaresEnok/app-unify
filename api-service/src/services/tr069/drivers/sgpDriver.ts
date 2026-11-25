import { ApiError } from "../../../middlewares/errorHandler";
import { proxyToSgp } from "../../proxySgpClient";
import { createSgpSession, resolveSgpCredentials } from "../../sgpClient";
import type {
  CpeConnectedHost,
  CpeDiagnosticResult,
  CpeStatusOverview,
  CpeWifiNetwork,
  Tr069Driver,
} from "../types";

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

export const sgpDriver: Tr069Driver = {
  async testConnection(config) {
    return {
      ok: config.enabled,
      message: "Driver SGP CPE Manager ativo — utiliza a integração SGP já cadastrada do provedor.",
    };
  },

  async getOverview(_config, identity): Promise<CpeStatusOverview> {
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
    const wifiNetworks = mapSgpWifi(body?.data ?? body);
    return {
      online: wifiNetworks.length > 0,
      driver: "sgp",
      deviceId: identity.serial || identity.contratoId,
      manufacturer: "",
      model: "CPE gerenciada via SGP",
      serial: identity.serial,
      mac: identity.mac,
      firmware: "",
      uptimeSeconds: null,
      wanIp: "",
      opticalRxDbm: null,
      lanPorts: [],
      lanBottleneck100Mbps: false,
      planDownloadMbps: identity.planDownloadMbps,
      wifiNetworks,
      hostsCount: 0,
      lastInform: new Date().toISOString(),
    };
  },

  async listHosts(_config, identity): Promise<CpeConnectedHost[]> {
    if (!identity.contratoId) return [];
    const creds = await resolveSgpCredentials(identity.providerId);
    const session = createSgpSession(creds.providerId, creds.baseUrl, creds);
    try {
      const resp = await session.post(`${creds.baseUrl}/api/cpemanager/servico/${identity.contratoId}/hosts/`, {
        token: creds.token,
        app: creds.app,
      });
      const list = Array.isArray(resp.data?.hosts) ? resp.data.hosts : Array.isArray(resp.data) ? resp.data : [];
      return list.map((h: any) => ({
        hostname: String(h?.hostname || h?.name || h?.mac || "Dispositivo"),
        mac: String(h?.mac || "").toUpperCase(),
        ip: String(h?.ip || ""),
        interfaceType: String(h?.interface || "").toLowerCase().includes("eth") ? "ethernet" : "wifi_2g",
        rssiDbm: h?.rssi != null ? Number(h.rssi) : null,
        signalQuality: "unknown" as const,
        active: h?.active !== false,
      }));
    } catch {
      return [];
    }
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
    const creds = await resolveSgpCredentials(identity.providerId);
    const session = createSgpSession(creds.providerId, creds.baseUrl, creds);
    try {
      await session.post(`${creds.baseUrl}/api/cpemanager/servico/${identity.contratoId}/reboot/`, {
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
