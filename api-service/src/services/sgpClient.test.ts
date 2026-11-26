import { beforeEach, expect, it, vi } from "vitest";

const state = vi.hoisted(() => ({
  options: [] as Array<Record<string, unknown>>,
  inputs: [] as Array<Record<string, unknown>>,
  failure: null as null | Record<string, unknown>,
}));

vi.mock("./upstream-runtime", () => ({
  createUpstream: (options: Record<string, unknown>) => {
    state.options.push(options);
    return {
      execute: async (input: Record<string, unknown>, operation: () => Promise<unknown>) => {
        state.inputs.push(input);
        if (state.failure) throw Object.assign(new Error("busy"), state.failure);
        return operation();
      },
    };
  },
  readTtl: () => 0,
}));

import { createSgpSession, ERP_BUSY_MESSAGE } from "./sgpClient";
import runtime from "./sgp-outbound";

beforeEach(() => {
  state.inputs.length = 0;
  state.failure = null;
  vi.restoreAllMocks();
});

it("pedidos do app esperam uma vaga (~8 s) em vez de 503 imediato", () => {
  expect(state.options[0]).toMatchObject({ slotWaitMs: 8000 });
});

it("IXC usa teto maior por provedor; SGP mantém o padrão", async () => {
  vi.spyOn(runtime as any, "request").mockResolvedValue({ status: 200, data: { total: "0", registros: [] } });
  const ixc = createSgpSession("upconnect", "https://ixc.example.com", { erp: "ixc", token: "synthetic" });
  await ixc.post("https://ixc.example.com/api/ura/consultacliente/", { cpfcnpj: "12345678909" });
  expect(state.inputs[0].limits).toEqual({ maxPerProvider: 12, maxPerHost: 12 });
  const sgp = createSgpSession("vibe", "https://sgp.example.com", { erp: "sgp", token: "synthetic" });
  await sgp.post("https://sgp.example.com/api/ura/titulos/", { cpfcnpj: "12345678909" });
  expect(state.inputs[1].limits).toBeUndefined();
});

it("503 de vagas esgotadas chega ao app com mensagem amigável", async () => {
  const session = createSgpSession("vibe", "https://sgp.example.com", { erp: "sgp", token: "synthetic" });
  state.failure = { status: 503, busy: true };
  await expect(session.post("https://sgp.example.com/api/ura/titulos/", {})).rejects.toMatchObject({ status: 503, message: ERP_BUSY_MESSAGE });
  state.failure = { status: 503 };
  await expect(session.post("https://sgp.example.com/api/ura/titulos/", {})).rejects.toMatchObject({ status: 503, message: "SGP ocupado ou indisponível. Tente novamente." });
});
