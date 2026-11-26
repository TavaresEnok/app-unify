import { beforeEach, describe, expect, it, vi } from "vitest";

const proxyToSgp = vi.fn();
vi.mock("../../proxySgpClient", () => ({ proxyToSgp: (...args: unknown[]) => proxyToSgp(...args) }));
vi.mock("../../sgpClient", () => ({ createSgpSession: vi.fn(), resolveSgpCredentials: vi.fn() }));

const { sgpDriver, clearSgpDriverCacheForTests } = await import("./sgpDriver");

const identity = {
  providerId: "insnet", cpfCnpj: "11122233344", contratoId: "3894", serial: "", mac: "",
  planDownloadMbps: 300, authHeader: "Bearer t",
} as any;
const config = { enabled: true } as any;

describe("sgpDriver", () => {
  const cpeList = {
      status: 200,
      data: {
        success: true,
        servicoId: "3585",
        data: [{ id: "1-1", ssid: "Casa-5G", frequency: "5GHz", enabled: true, channel: "44" }],
        device: {
          manager: "genieacs", manufacturer: "NV21", model: "NV21 - X1", firmware: "V7", wanIp: "10.0.0.2", wanUptimeSeconds: 120,
          hosts: [{ mac: "AA:BB", hostname: "celular", ip: "192.168.1.8", interfaceType: "wifi_5g", rssiDbm: -50 }],
        },
        passwordReadable: false,
      },
    };
  const onu = { status: 200, data: { data: { signalRx: -19.35, signalTx: 2.26, connectionStatus: "Online", lastUpdate: "2026-11-26 09:00:00" } } };
  beforeEach(() => {
    clearSgpDriverCacheForTests();
    proxyToSgp.mockReset();
    proxyToSgp.mockImplementation(async (path: string) => (path === "/cpe/wifi/list" ? cpeList : path === "/diagnostic/onu-signal-base" ? onu : { status: 404, data: {} }));
  });

  it("preenche o overview com os dados reais do aparelho", async () => {
    const overview = await sgpDriver.getOverview(config, identity);
    expect(overview).toMatchObject({ manufacturer: "NV21", firmware: "V7", wanIp: "10.0.0.2", uptimeSeconds: 120, hostsCount: 1, deviceManaged: true, passwordReadable: false });
    // O registro do SGP não diz se o roteador está ligado agora.
    expect(overview.online).toBeNull();
    expect(overview.lastInform).toBeNull();
    expect(overview.opticalRxDbm).toBe(-19.35);
    expect(overview.fiber).toMatchObject({ online: true, rxPowerDbm: -19.35, txPowerDbm: 2.26, source: "snapshot", onlineSince: null });
    expect(overview.hosts).toHaveLength(1);
    expect(overview.wifiNetworks[0]).toMatchObject({ id: "1-1", band: "5GHz" });
    expect(proxyToSgp).toHaveBeenCalledWith("/cpe/wifi/list", expect.objectContaining({ contrato: "3894" }), "Bearer t");
  });

  it("lista hosts a partir de lan_devices, com qualidade de sinal", async () => {
    expect(await sgpDriver.listHosts(config, identity)).toEqual([
      { hostname: "celular", mac: "AA:BB", ip: "192.168.1.8", interfaceType: "wifi_5g", rssiDbm: -50, signalQuality: "excellent", active: true },
    ]);
  });

  it("propaga a mensagem do SGP quando o equipamento não existe", async () => {
    proxyToSgp.mockResolvedValue({ status: 422, data: { error: { message: "Equipamento não encontrado." } } });
    await expect(sgpDriver.getOverview(config, identity)).rejects.toMatchObject({ status: 422, message: "Equipamento não encontrado." });
  });

  it("sem roteador gerenciado, devolve só a fibra (e a fibra fora do ar marca o roteador offline)", async () => {
    proxyToSgp.mockImplementation(async (path: string) => (path === "/cpe/wifi/list"
      ? { status: 422, data: { error: { message: "Gerenciador CPE não definido para este serviço." } } }
      : { status: 200, data: { data: { signalRx: null, signalTx: null, connectionStatus: "Offline" } } }));
    const overview = await sgpDriver.getOverview(config, identity);
    expect(overview).toMatchObject({ deviceManaged: false, wifiNetworks: [], hostsCount: 0, online: false });
    expect(overview.fiber).toMatchObject({ online: false, source: "snapshot" });
  });

  it("divide a mesma leitura entre status, hosts e painel (sem repetir chamadas ao ERP)", async () => {
    await Promise.all([sgpDriver.getOverview(config, identity), sgpDriver.listHosts(config, identity), sgpDriver.getOverview(config, identity)]);
    await sgpDriver.listHosts(config, identity);
    expect(proxyToSgp.mock.calls.filter(([path]) => path === "/cpe/wifi/list")).toHaveLength(1);
    expect(proxyToSgp.mock.calls.filter(([path]) => path === "/diagnostic/onu-signal-base")).toHaveLength(1);
  });

  it("detalhes da OLT só quando pedidos, e mesclados à fibra", async () => {
    proxyToSgp.mockImplementation(async (path: string) => (path === "/cpe/wifi/list" ? cpeList : path === "/diagnostic/onu-signal-base" ? onu
      : { status: 200, data: { data: { online: true, onlineSince: "2026-11-25T15:00:00.000Z", lastDownCause: "Falta de energia no equipamento", distanceMeters: 588, rxPowerDbm: -19.3, fetchedAt: "2026-11-26T09:10:00.000Z" } } }));
    expect((await sgpDriver.getOverview(config, identity)).fiber?.source).toBe("snapshot");
    expect(proxyToSgp.mock.calls.some(([path]) => path === "/diagnostic/onu-details")).toBe(false);
    const live = await sgpDriver.getOverview(config, identity, { fiberDetails: true });
    expect(live.fiber).toMatchObject({ source: "olt", onlineSince: "2026-11-25T15:00:00.000Z", lastDownCause: "Falta de energia no equipamento", distanceMeters: 588, txPowerDbm: 2.26 });
  });

  it("aparelho sem nome não mostra o MAC como nome", async () => {
    proxyToSgp.mockImplementation(async (path: string) => (path === "/cpe/wifi/list"
      ? { status: 200, data: { ...cpeList.data, device: { ...cpeList.data.device, hosts: [{ mac: "aa:bb:cc:00:00:02", hostname: "", ip: "192.168.1.3", interfaceType: "wifi_2g", rssiDbm: null }] } } }
      : onu));
    const [host] = await sgpDriver.listHosts(config, identity);
    expect(host).toMatchObject({ hostname: "Aparelho sem nome", mac: "AA:BB:CC:00:00:02", signalQuality: "unknown" });
  });

  it("reiniciar e otimizar respondem 409 sem chamar o ERP", async () => {
    await expect(sgpDriver.reboot(config, identity)).rejects.toMatchObject({ status: 409, message: "Recurso não suportado por este gerenciador." });
    await expect(sgpDriver.optimizeWifi(config, identity)).rejects.toMatchObject({ status: 409 });
    expect(proxyToSgp).not.toHaveBeenCalled();
  });

  it("repassa modo do rádio e usa timeout maior para gravar Wi-Fi", async () => {
    proxyToSgp.mockImplementation(async (path: string) => (path === "/cpe/wifi/list"
      ? { status: 200, data: { ...cpeList.data, data: [{ id: "1-1", ssid: "Casa-5G", frequency: "5GHz", enabled: true, channel: "44", mode: "ac" }] } }
      : path === "/cpe/wifi/update" ? { status: 200, data: { success: true } } : onu));
    expect((await sgpDriver.getOverview(config, identity)).wifiNetworks[0]).toMatchObject({ mode: "ac" });
    await sgpDriver.updateWifi(config, identity, { wifiId: "1-1", ssid: "Novo", password: "segura123" });
    const update = proxyToSgp.mock.calls.find(([path]) => path === "/cpe/wifi/update");
    expect(update?.[4]).toEqual({ timeoutMs: 40000 });
  });
});

describe("capacidades do driver SGP", () => {
  it("nunca anuncia reinício, otimização ou diagnóstico, mesmo se o provedor marcou", async () => {
    const { effectiveFeatures } = await import("../index");
    const all = { wifi: true, reboot: true, hosts: true, guestWifi: true, channelOptimize: true, speedDiagnostic: true };
    expect(effectiveFeatures("sgp", all)).toEqual({ ...all, reboot: false, channelOptimize: false, speedDiagnostic: false });
    expect(effectiveFeatures("genieacs", all)).toEqual(all);
  });
});

describe("sgpDriver: senha obrigatória quando o roteador não informa a atual", () => {
  it("recusa renomear sem senha antes de chamar o ERP", async () => {
    clearSgpDriverCacheForTests();
    proxyToSgp.mockReset();
    proxyToSgp.mockImplementation(async (path: string) => (path === "/cpe/wifi/list"
      ? { status: 200, data: { success: true, servicoId: "1", data: [{ id: "1-1", ssid: "Casa", frequency: "5GHz", enabled: true }], device: { hosts: [] }, passwordReadable: false } }
      : { status: 404, data: {} }));
    await sgpDriver.listHosts(config, identity);
    await expect(sgpDriver.updateWifi(config, identity, { wifiId: "1-1", ssid: "Novo nome" })).rejects.toMatchObject({ status: 400 });
    expect(proxyToSgp.mock.calls.some(([path]) => path === "/cpe/wifi/update")).toBe(false);
  });
});
