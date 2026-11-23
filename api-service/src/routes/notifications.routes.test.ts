import express from "express";
import request from "supertest";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { SqlQueryable } from "../services/postgres";
import {
  buildSegmentWhere,
  campaignMatchesSubscriber,
  normalizeFilters,
} from "../services/notificationCampaigns";
import { resetPgSchemaForTests as resetSchema } from "../services/postgres";

const tokens = new Map<string, Record<string, unknown>>();
const mockSend = vi.fn();
const mockMulticast = vi.fn();
const mockQuery = vi.fn();
const mockPool: SqlQueryable = { query: mockQuery };

vi.mock("../services/firebaseAdmin", () => ({
  firestore: { collection: () => ({}) },
  messaging: {
    send: (...args: unknown[]) => mockSend(...args),
    sendEachForMulticast: (...args: unknown[]) => mockMulticast(...args),
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

vi.mock("../services/postgres", async (importOriginal) => {
  const actual = await importOriginal<typeof import("../services/postgres")>();
  return {
    ...actual,
    getPgPool: () => mockPool,
    ensureNotificationSchema: vi.fn(async () => undefined),
  };
});

const { notificationsRouter } = await import("./notifications.routes");
const { errorHandler } = await import("../middlewares/errorHandler");

const app = express();
app.use(express.json());
app.use((req, _res, next) => { req.correlationId = "test"; next(); });
app.use("/admin/notifications", notificationsRouter);
app.use(errorHandler);

describe("notificationCampaigns SQL & matcher", () => {
  it("monta cláusula parametrizada para OLT, PON, CTO, cidade, bairro, status, plano e busca", () => {
    const filters = normalizeFilters({
      oltNames: ["OLT ZTE - PAU AMARELO"],
      ponKeys: ["Slot 1 / PON 11"],
      ctos: ["R21-01"],
      cidades: ["PAULISTA"],
      bairros: ["PAU AMARELO"],
      statuses: ["Ativo"],
      planos: ["VIBE 500 MEGA"],
      search: "ZTE",
    });
    const { whereSql, params } = buildSegmentWhere("vibe", filters);
    expect(whereSql).toContain("s.olt_name = ANY($2::text[])");
    expect(whereSql).toContain("(s.slot || '/' || s.pon) = ANY($3::text[])");
    expect(whereSql).toContain("s.cto = ANY($4::text[])");
    expect(whereSql).toContain("s.cidade = ANY($5::text[])");
    expect(whereSql).toContain("s.bairro = ANY($6::text[])");
    expect(whereSql).toContain("LOWER(s.contract_status) = ANY($7::text[])");
    expect(whereSql).toContain("s.plano = ANY($8::text[])");
    expect(params).toEqual([
      "vibe",
      ["OLT ZTE - PAU AMARELO"],
      ["1/11"],
      ["R21-01"],
      ["PAULISTA"],
      ["PAU AMARELO"],
      ["ativo"],
      ["VIBE 500 MEGA"],
      "%ZTE%",
    ]);
  });

  it("campaignMatchesSubscriber combina OLT, PON e bairro corretamente", () => {
    const seg = [{
      contract_status: "Ativo",
      plano: "VIBE 500 MEGA",
      cidade: "PAULISTA",
      bairro: "PAU AMARELO",
      pop_id: "3492",
      olt_name: "OLT ZTE - PAU AMARELO",
      slot: "1",
      pon: "11",
      cto: "R21-01",
      client_name: "Cliente",
    }];

    expect(campaignMatchesSubscriber(normalizeFilters({}), "10331142430", [])).toBe(true);
    expect(campaignMatchesSubscriber(normalizeFilters({ oltNames: ["OLT ZTE - PAU AMARELO"], ponKeys: ["1/11"] }), "10331142430", seg)).toBe(true);
    expect(campaignMatchesSubscriber(normalizeFilters({ oltNames: ["OLT HUAWEI - JANGA"] }), "10331142430", seg)).toBe(false);
    expect(campaignMatchesSubscriber(normalizeFilters({ bairros: ["PAU AMARELO"], statuses: ["Suspenso"] }), "10331142430", seg)).toBe(false);
  });
});

describe("rotas /admin/notifications", () => {
  beforeEach(() => {
    tokens.clear();
    mockSend.mockReset();
    mockMulticast.mockReset();
    mockQuery.mockReset();
    resetSchema();
    tokens.set("adm-vibe", { uid: "u-vibe", role: "providerAdmin", providerId: "vibe" });
    tokens.set("adm-other", { uid: "u-other", role: "providerAdmin", providerId: "outro" });
    tokens.set("sub", { uid: "sub1", role: "subscriber", providerId: "vibe", cpfCnpj: "10331142430" });
  });

  it("bloqueia assinante e isola provedor de outro tenant", async () => {
    await request(app).get("/admin/notifications/segments?providerId=vibe").set({ Authorization: "Bearer sub" }).expect(403);
    await request(app).get("/admin/notifications/segments?providerId=vibe").set({ Authorization: "Bearer adm-other" }).expect(403);
    await request(app).post("/admin/notifications/send").set({ Authorization: "Bearer adm-other" }).send({
      providerId: "vibe", title: "Teste", body: "Msg",
    }).expect(403);
  });

  it("retorna prévia de audiência filtrada por OLT/bairro", async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ count: "100" }] }) // ensureProviderSegments
      .mockResolvedValueOnce({ rows: [{ matched_subscribers: "34", reachable_devices: "19" }] });

    const res = await request(app)
      .post("/admin/notifications/preview")
      .set({ Authorization: "Bearer adm-vibe" })
      .send({ filters: { oltNames: ["OLT ZTE - PAU AMARELO"], bairros: ["PAU AMARELO"] } })
      .expect(200);

    expect(res.body.data).toMatchObject({
      matchedSubscribers: 34,
      reachableDevices: 19,
      hasFilters: true,
    });
  });

  it("envia campanha segmentada por multicast e limpa tokens inválidos no Postgres", async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ count: "100" }] }) // ensureProviderSegments
      .mockResolvedValueOnce({ rows: [{ matched_subscribers: "2" }] }) // countRes
      .mockResolvedValueOnce({ rows: [{ fcm_token: "tok-ok" }, { fcm_token: "tok-dead" }] }) // tokenRes
      .mockResolvedValueOnce({ rows: [] }) // DELETE invalid tokens
      .mockResolvedValueOnce({ rows: [{ created_at: new Date("2026-11-22T12:00:00Z") }] }); // INSERT campaign

    mockMulticast.mockResolvedValueOnce({
      successCount: 1,
      failureCount: 1,
      responses: [
        { success: true },
        { success: false, error: { code: "messaging/registration-token-not-registered" } },
      ],
    });

    const res = await request(app)
      .post("/admin/notifications/send")
      .set({ Authorization: "Bearer adm-vibe" })
      .send({
        title: "Manutenção OLT Pau Amarelo",
        body: "Previsão de retorno às 18h.",
        category: "urgent",
        filters: { oltNames: ["OLT ZTE - PAU AMARELO"] },
      })
      .expect(201);

    expect(res.body.success).toBe(true);
    expect(res.body.data).toMatchObject({
      deliveryMode: "multicast",
      matchedSubscribers: 2,
      targetedDevices: 2,
      successCount: 1,
      failureCount: 1,
    });
    expect(mockMulticast).toHaveBeenCalledTimes(1);
    const deleteCall = mockQuery.mock.calls.find(([sql]) => String(sql).includes("DELETE FROM subscriber_devices"));
    expect(deleteCall?.[1]).toEqual(["vibe", ["tok-dead"]]);
  });

  it("envia broadcast sem filtros usando tópico FCM (zero varredura de tokens)", async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ count: "100" }] }) // ensureProviderSegments (sendCampaign)
      .mockResolvedValueOnce({ rows: [{ count: "100" }] }) // ensureProviderSegments (previewAudience)
      .mockResolvedValueOnce({ rows: [{ matched_subscribers: "492", reachable_devices: "120" }] }) // preview
      .mockResolvedValueOnce({ rows: [{ created_at: new Date("2026-11-22T12:00:00Z") }] }); // INSERT

    mockSend.mockResolvedValueOnce("projects/x/messages/1");

    const res = await request(app)
      .post("/admin/notifications/send")
      .set({ Authorization: "Bearer adm-vibe" })
      .send({ title: "Aviso geral", body: "Novo horário de atendimento." })
      .expect(201);

    expect(res.body.data.deliveryMode).toBe("topic");
    expect(mockSend).toHaveBeenCalledWith(expect.objectContaining({ topic: "provider_vibe" }));
    expect(mockMulticast).not.toHaveBeenCalled();
  });
});
