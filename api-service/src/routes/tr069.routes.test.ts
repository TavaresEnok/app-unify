import express from "express";
import request from "supertest";
import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  buildGenieOverview,
  extractGenieHosts,
  extractGenieWifiNetworks,
} from "../services/tr069/drivers/genieacsDriver";
import {
  buildFlashmanOverview,
  extractFlashmanHosts,
  extractFlashmanWifi,
} from "../services/tr069/drivers/flashmanDriver";
import { classifySignalQuality, inferPlanDownloadMbps } from "../services/tr069/types";

const tokens = new Map<string, Record<string, unknown>>();
const acsDocs = new Map<string, Record<string, unknown>>();
const mockQuery = vi.fn();

vi.mock("../services/self-auth", async (importOriginal) => {
  const actual = await importOriginal<typeof import("../services/self-auth")>();
  return {
    ...actual,
    verifyLiveSession: async (_pool: unknown, token: string) => {
      const user = tokens.get(token);
      if (!user) throw Object.assign(new Error("invalid"), { code: "auth/invalid-id-token" });
      return user;
    },
  };
});

vi.mock("../services/auditService", () => ({
  recordAdminAudit: vi.fn(async () => undefined),
}));

vi.mock("../services/providersStore", () => ({
  getProviderSecret: async (_pool: unknown, providerId: string, kind: string) => {
    return acsDocs.get(`${providerId}:${kind}`) || null;
  },
  saveProviderSecret: async (_pool: unknown, providerId: string, kind: string, val: Record<string, unknown>) => {
    acsDocs.set(`${providerId}:${kind}`, val);
  },
}));

vi.mock("../services/postgres", () => ({
  getPgPool: () => ({ query: mockQuery }),
  requirePgPool: () => ({ query: mockQuery }),
  ensureCoreSchema: vi.fn(async () => undefined),
}));

vi.mock("../services/sgp-outbound", () => ({
  default: {
    assertSafeSgpBaseUrl: async (url: string) => {
      if (/127\.0\.0\.1|localhost|10\.|192\.168\./i.test(url)) {
        throw new Error("Destino interno bloqueado");
      }
    },
  },
}));

const { tr069AdminRouter, tr069SubscriberRouter } = await import("./tr069.routes");
const { errorHandler } = await import("../middlewares/errorHandler");

const app = express();
app.use(express.json());
app.use((req, _res, next) => { req.correlationId = "test"; next(); });
app.use("/tr069", tr069SubscriberRouter);
app.use("/admin/tr069", tr069AdminRouter);
app.use(errorHandler);

describe("TR-069 / ACS drivers and routes", () => {
  beforeEach(() => {
    tokens.clear();
    acsDocs.clear();
    mockQuery.mockReset();
    tokens.set("sub-vibe", { uid: "10331142430", role: "subscriber", providerId: "vibe", cpfCnpj: "10331142430" });
    tokens.set("adm-vibe", { uid: "u1", role: "providerAdmin", providerId: "vibe" });
    tokens.set("adm-other", { uid: "u2", role: "providerAdmin", providerId: "other" });
    tokens.set("super", { uid: "s1", role: "superAdmin", superAdmin: true });
  });

  it("interpreta TR-098 no GenieACS, classifica sinal RSSI e detecta gargalo LAN 100 Mbps", () => {
    expect(inferPlanDownloadMbps("VIBE 500 MEGA")).toBe(500);
    expect(inferPlanDownloadMbps("FIBRA 1 GIGA")).toBe(1000);
    expect(classifySignalQuality("wifi_5g", -52)).toBe("excellent");
    expect(classifySignalQuality("wifi_2g", -79)).toBe("weak");

    const fakeGenie = {
      _id: "HW-EG8145V5-1234",
      _lastInform: new Date().toISOString(),
      _deviceId: { _Manufacturer: "Huawei", _ProductClass: "EG8145V5", _SerialNumber: "HWTC12345678" },
      InternetGatewayDevice: {
        DeviceInfo: { SoftwareVersion: { _value: "V5R019" }, UpTime: { _value: 7200 } },
        WANDevice: {
          "1": {
            X_HW_GponInterfaceConfig: { RXPower: { _value: -19.4 } },
            WANConnectionDevice: { "1": { WANPPPConnection: { "1": { ExternalIPAddress: { _value: "187.10.20.30" } } } } },
          },
        },
        LANDevice: {
          "1": {
            LANEthernetInterfaceConfig: {
              "1": { Status: { _value: "Up" }, MaxBitRate: { _value: "100" }, MACAddress: { _value: "aa:bb:cc:dd:ee:01" } },
            },
            WLANConfiguration: {
              "1": {
                SSID: { _value: "Casa_2G" },
                Channel: { _value: 6 },
                Enable: { _value: true },
                Standard: { _value: "n" },
                AssociatedDevice: {
                  "1": { AssociatedDeviceMACAddress: { _value: "11:22:33:44:55:66" }, X_HW_RSSI: { _value: -78 } },
                },
              },
              "5": {
                SSID: { _value: "Casa_5G" },
                Channel: { _value: 44 },
                Enable: { _value: true },
                Standard: { _value: "ac" },
              },
            },
            Hosts: {
              Host: {
                "1": { HostName: { _value: "Celular-Joao" }, MACAddress: { _value: "11:22:33:44:55:66" }, IPAddress: { _value: "192.168.1.15" }, Active: { _value: true }, InterfaceType: { _value: "802.11" } },
                "2": { HostName: { _value: "SmartTV" }, MACAddress: { _value: "AA:BB:CC:11:22:33" }, IPAddress: { _value: "192.168.1.20" }, Active: { _value: true }, InterfaceType: { _value: "Ethernet" } },
              },
            },
          },
        },
      },
    };

    const wifis = extractGenieWifiNetworks(fakeGenie);
    expect(wifis).toHaveLength(2);
    expect(wifis[0]).toMatchObject({ id: "tr098:1", ssid: "Casa_2G", band: "2.4GHz" });
    expect(wifis[1]).toMatchObject({ id: "tr098:5", ssid: "Casa_5G", band: "5GHz" });

    const hosts = extractGenieHosts(fakeGenie);
    expect(hosts).toHaveLength(2);
    expect(hosts[0]).toMatchObject({ hostname: "Celular-Joao", interfaceType: "wifi_2g", rssiDbm: -78, signalQuality: "weak" });
    expect(hosts[1]).toMatchObject({ hostname: "SmartTV", interfaceType: "ethernet", signalQuality: "wired" });

    const overview = buildGenieOverview(fakeGenie, {
      providerId: "vibe",
      cpfCnpj: "10331142430",
      contratoId: "86069",
      serial: "HWTC12345678",
      mac: "",
      pppoeLogin: "joao",
      planName: "VIBE 500 MEGA",
      planDownloadMbps: 500,
    });
    expect(overview.online).toBe(true);
    expect(overview.lanBottleneck100Mbps).toBe(true);
    expect(overview.opticalRxDbm).toBe(-19.4);
  });

  it("interpreta dispositivos do Anlix Flashman v2", () => {
    const dev = {
      _id: "AA:BB:CC:DD:EE:FF",
      vendor: "TP-Link",
      model: "EC220-G5",
      version: "1.12.0",
      last_contact: new Date().toISOString(),
      wifi_ssid: "MinhaFibra",
      wifi_ssid_5ghz: "MinhaFibra_5G",
      wifi_channel: "auto",
      wifi_channel_5ghz: "36",
      lan_devices: [
        { dhcp_name: "Notebook", mac: "00:11:22:33:44:55", ip: "192.168.0.10", conn_type: 1, wifi_freq: 5, wifi_signal: -58, is_online: true },
        { dhcp_name: "PC-Escritorio", mac: "00:11:22:33:44:66", ip: "192.168.0.11", conn_type: 0, conn_speed: 100, is_online: true },
      ],
    };
    expect(extractFlashmanWifi(dev)).toHaveLength(2);
    expect(extractFlashmanHosts(dev)[0]).toMatchObject({ interfaceType: "wifi_5g", signalQuality: "good" });
    const overview = buildFlashmanOverview(dev, {
      providerId: "vibe",
      cpfCnpj: "10331142430",
      contratoId: "86069",
      serial: "",
      mac: "AA:BB:CC:DD:EE:FF",
      pppoeLogin: "",
      planName: "VIBE 500 MEGA",
      planDownloadMbps: 500,
    });
    expect(overview.lanBottleneck100Mbps).toBe(true);
  });

  it("protege configuração ACS com RBAC, bloqueio SSRF e nunca devolve segredos", async () => {
    // Assinante e providerAdmin não podem salvar config ACS
    await request(app).put("/admin/tr069/config").set({ Authorization: "Bearer sub-vibe" }).send({ providerId: "vibe", driver: "genieacs" }).expect(403);
    await request(app).put("/admin/tr069/config").set({ Authorization: "Bearer adm-vibe" }).send({ providerId: "vibe", driver: "genieacs" }).expect(403);

    // SSRF bloqueado para URL interna
    await request(app)
      .put("/admin/tr069/config")
      .set({ Authorization: "Bearer super" })
      .send({ providerId: "vibe", driver: "genieacs", enabled: true, url: "http://127.0.0.1:7557" })
      .expect(400);

    // SuperAdmin salva config pública válida e segredo nunca vaza no GET
    const putRes = await request(app)
      .put("/admin/tr069/config")
      .set({ Authorization: "Bearer super" })
      .send({
        providerId: "vibe",
        driver: "genieacs",
        enabled: true,
        url: "https://acs.vibefibra.com.br:7557",
        username: "noc",
        password: "super-secret-password",
      })
      .expect(200);

    expect(putRes.body.data.hasPassword).toBe(true);
    expect(JSON.stringify(putRes.body)).not.toContain("super-secret-password");

    // Assinante consulta capabilities sem ver URL/credenciais
    const caps = await request(app)
      .get("/tr069/capabilities")
      .set({ Authorization: "Bearer sub-vibe" })
      .expect(200);
    expect(caps.body.data).toMatchObject({ enabled: true, driver: "genieacs" });
    expect(JSON.stringify(caps.body)).not.toContain("super-secret-password");
    expect(JSON.stringify(caps.body)).not.toContain("acs.vibefibra.com.br");

    // Isolamento de tenant no overview de cliente
    await request(app)
      .get("/admin/tr069/clients/10331142430/overview?providerId=vibe")
      .set({ Authorization: "Bearer adm-other" })
      .expect(403);
  });
});
