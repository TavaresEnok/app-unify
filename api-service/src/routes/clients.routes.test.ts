import express from "express";
import request from "supertest";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { formatSgpAddress, normalizeSgpClientRow } from "./clients.routes";

const tokens = new Map<string, Record<string, unknown>>();
const mockQuery = vi.fn();

vi.mock("../services/firebaseAdmin", () => ({
  firestore: {
    collection: () => ({
      doc: () => ({ collection: () => ({ doc: () => ({ delete: async () => undefined }) }) }),
    }),
  },
  firebaseAuth: {
    getUser: async (uid: string) => ({
      uid,
      customClaims: [...tokens.values()].find((user) => user.uid === uid) || {},
    }),
    verifyIdToken: async (token: string) => {
      const user = tokens.get(token);
      if (!user) throw Object.assign(new Error("invalid"), { code: "auth/invalid-id-token" });
      return user;
    },
  },
}));

vi.mock("../services/postgres", () => ({
  getPgPool: () => ({ query: mockQuery }),
  ensureNotificationSchema: vi.fn(async () => undefined),
}));

const { clientsRouter } = await import("./clients.routes");
const { errorHandler } = await import("../middlewares/errorHandler");

const app = express();
app.use(express.json());
app.use((req, _res, next) => { req.correlationId = "test"; next(); });
app.use("/admin/clients", clientsRouter);
app.use(errorHandler);

describe("clients.routes", () => {
  beforeEach(() => {
    tokens.clear();
    mockQuery.mockReset();
    tokens.set("adm-vibe", { uid: "u1", role: "providerAdmin", providerId: "vibe" });
    tokens.set("adm-other", { uid: "u2", role: "providerAdmin", providerId: "other" });
  });

  it("normaliza endereço objeto, plano, OLT, PON e CTO do JSON real do SGP", () => {
    expect(formatSgpAddress({
      logradouro: "Rua A", numero: "123", bairro: "PAU AMARELO", cidade: "PAULISTA", uf: "PE",
    })).toBe("Rua A, 123 · PAU AMARELO - PAULISTA - PE");

    const row = normalizeSgpClientRow({
      client_id: "407",
      nome: "Maria Silva",
      cpfcnpj: "10331142430",
      contratos: [{
        id: 86069,
        status: "Ativo",
        vencimento: 10,
        endereco: { logradouro: "Rua A", numero: "123", bairro: "PAU AMARELO", cidade: "PAULISTA", uf: "PE" },
        servicos: [{
          login: "maria.fibra",
          plano: { id: 1463, descricao: "VIBE 500 MEGA" },
          onu: { olt_nome: "OLT ZTE - PAU AMARELO", slot: 1, pon: 11, splitter: { nome: "R21-01" } },
        }],
      }],
      has_app_device: true,
    });

    expect(row).toMatchObject({
      id: "407",
      nome: "Maria Silva",
      status: "Ativo",
      plano: "VIBE 500 MEGA",
      cidade: "PAULISTA",
      bairro: "PAU AMARELO",
      oltName: "OLT ZTE - PAU AMARELO",
      pon: "Slot 1 / PON 11",
      cto: "R21-01",
      login: "maria.fibra",
      vencimento: "Dia 10",
      contratoIds: ["86069"],
      hasAppDevice: true,
    });
  });

  it("isola provedor e busca cliente tanto por CPF quanto por ID SGP", async () => {
    await request(app).get("/admin/clients?providerId=vibe").set({ Authorization: "Bearer adm-other" }).expect(403);

    mockQuery.mockResolvedValueOnce({
      rows: [{
        client_id: "407",
        nome: "Maria Silva",
        cpfcnpj: "10331142430",
        contratos: [{ id: 86069, status: "Ativo" }],
        has_app_device: false,
      }],
    });

    const res = await request(app)
      .get("/admin/clients/10331142430?providerId=vibe")
      .set({ Authorization: "Bearer adm-vibe" })
      .expect(200);

    expect(res.body.data.id).toBe("407");
    expect(res.body.data.cpfcnpj).toBe("10331142430");
  });

  it("busca na listagem usa client_id exato (sem curinga %) quando pesquisa dígitos", async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ ok: true }] })
      .mockResolvedValueOnce({ rows: [{ client_id: "407", nome: "Maria", cpfcnpj: "10331142430", contratos: [] }] })
      .mockResolvedValueOnce({ rows: [{ count: "1" }] })
      .mockResolvedValueOnce({ rows: [{ last_synced: new Date("2026-11-22T12:00:00Z") }] });

    const res = await request(app)
      .get("/admin/clients?providerId=vibe&search=407")
      .set({ Authorization: "Bearer adm-vibe" })
      .expect(200);

    expect(res.body.data.total).toBe(1);
    const listQuery = mockQuery.mock.calls[1];
    expect(listQuery[0]).toContain("c.client_id = $4");
    expect(listQuery[1]).toContain("407");
  });
});

