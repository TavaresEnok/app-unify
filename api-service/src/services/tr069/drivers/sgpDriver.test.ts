import { beforeEach, describe, expect, it, vi } from "vitest";

const proxyToSgp = vi.fn();
vi.mock("../../proxySgpClient", () => ({ proxyToSgp: (...args: unknown[]) => proxyToSgp(...args) }));
vi.mock("../../sgpClient", () => ({ createSgpSession: vi.fn(), resolveSgpCredentials: vi.fn() }));

const { sgpDriver } = await import("./sgpDriver");

const identity = {
  providerId: "insnet", cpfCnpj: "11122233344", contratoId: "3894", serial: "", mac: "",
  planDownloadMbps: 300, authHeader: "Bearer t",
} as any;
const config = { enabled: true } as any;

describe("sgpDriver", () => {
  beforeEach(() => {
    proxyToSgp.mockReset();
    proxyToSgp.mockResolvedValue({
      status: 200,
      data: {
        success: true,
        servicoId: "3585",
        data: [{ id: "1-1", ssid: "Casa-5G", frequency: "5GHz", enabled: true, channel: "44" }],
        device: {
          manager: "genieacs", manufacturer: "NV21", model: "NV21 - X1", firmware: "V7", wanIp: "10.0.0.2", wanUptimeSeconds: 120,
          hosts: [{ mac: "AA:BB", hostname: "celular", ip: "192.168.1.8", interfaceType: "wifi_5g", rssiDbm: -50 }],
        },
      },
    });
  });

  it("preenche o overview com os dados reais do aparelho", async () => {
    const overview = await sgpDriver.getOverview(config, identity);
    expect(overview).toMatchObject({ online: true, manufacturer: "NV21", firmware: "V7", wanIp: "10.0.0.2", uptimeSeconds: 120, hostsCount: 1 });
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
});

describe("capacidades do driver SGP", () => {
  it("nunca anuncia reinício, otimização ou diagnóstico, mesmo se o provedor marcou", async () => {
    const { effectiveFeatures } = await import("../index");
    const all = { wifi: true, reboot: true, hosts: true, guestWifi: true, channelOptimize: true, speedDiagnostic: true };
    expect(effectiveFeatures("sgp", all)).toEqual({ ...all, reboot: false, channelOptimize: false, speedDiagnostic: false });
    expect(effectiveFeatures("genieacs", all)).toEqual(all);
  });
});
