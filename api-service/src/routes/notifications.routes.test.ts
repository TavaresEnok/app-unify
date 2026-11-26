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

vi.mock("../services/auditService", () => ({ recordAdminAudit: async () => undefined }));
vi.mock("../services/firebaseAdmin", () => ({
  getMessaging: () => ({
    send: (...args: unknown[]) => mockSend(...args),
    sendEachForMulticast: (...args: unknown[]) => mockMulticast(...args),
  }),
  messaging: {
    send: (...args: unknown[]) => mockSend(...args),
    sendEachForMulticast: (...args: unknown[]) => mockMulticast(...args),
  },
}));

vi.mock("../services/self-auth", () => ({
  verifyLiveSession: async (_pool: unknown, token: string) => {
    const user = tokens.get(token);
    if (!user) throw Object.assign(new Error("invalid"), { code: "auth/invalid-id-token" });
    return user;
  },
}));

vi.mock("../services/postgres", async (importOriginal) => {
  const actual = await importOriginal<typeof import("../services/postgres")>();
  return {
    ...actual,
    getPgPool: () => mockPool,
    requirePgPool: () => mockPool,
    ensureCoreSchema: vi.fn(async () => undefined),
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

    const wild = buildSegmentWhere("vibe", normalizeFilters({ search: "100%_fibra\\x" }));
    expect(wild.whereSql).toContain("ESCAPE '\\'");
    expect(wild.params).toEqual(["vibe", "%100\\%\\_fibra\\\\x%"]);
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
      .mockResolvedValueOnce({ rows: [{ created_at: new Date("2026-11-22T12:00:00Z") }] }) // INSERT campaign (processing)
      .mockResolvedValueOnce({ rows: [{ matched_subscribers: "2" }] }) // countRes
      .mockResolvedValueOnce({ rows: [{ fcm_token: "tok-ok" }, { fcm_token: "tok-dead" }] }) // tokenRes
      .mockResolvedValueOnce({ rows: [] }) // DELETE invalid tokens
      .mockResolvedValueOnce({ rows: [] }); // UPDATE sent

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
    // Registro criado antes do envio e fechado com as contagens reais.
    const sqls = mockQuery.mock.calls.map(([sql]) => String(sql));
    const insertAt = sqls.findIndex((sql) => sql.includes("INSERT INTO notification_campaigns"));
    const sentAt = sqls.findIndex((sql) => sql.includes("SET status = 'sent'"));
    expect(insertAt).toBeGreaterThan(-1);
    expect(sqls[insertAt]).toContain("'processing'");
    expect(sentAt).toBeGreaterThan(insertAt);
    expect(mockQuery.mock.calls[sentAt][1]).toEqual([expect.any(String), 2, 2, 1, 1, "multicast"]);
  });

  it("uma falha no meio do envio fica registrada como falhou, com contagem parcial", async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ count: "100" }] })
      .mockResolvedValueOnce({ rows: [{ created_at: new Date("2026-11-22T12:00:00Z") }] })
      .mockResolvedValueOnce({ rows: [{ matched_subscribers: "2" }] })
      .mockResolvedValueOnce({ rows: [{ fcm_token: "tok-a" }, { fcm_token: "tok-b" }] });
    mockMulticast.mockRejectedValueOnce(Object.assign(new Error("network"), { code: "app/network-error" }));
    await request(app).post("/admin/notifications/send").set({ Authorization: "Bearer adm-vibe" })
      .send({ title: "T", body: "B", filters: { oltNames: ["OLT X"] } }).expect(500);
    const failed = mockQuery.mock.calls.find(([sql]) => String(sql).includes("SET status = 'failed'"));
    expect(failed?.[1]).toEqual([expect.any(String), 2, 2, 0, 0]);
  });

  it("Idempotency-Key repetido devolve a mesma campanha sem novo envio", async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ count: "100" }] })
      .mockResolvedValueOnce({ rows: [{ id: "c1", provider_id: "vibe", title: "T", body: "B", category: "info", route: "", filters: {}, matched_subscribers: 3, targeted_devices: 3, success_count: 3, failure_count: 0, delivery_mode: "multicast", sent_by: "u1", status: "sent", scheduled_for: null, created_at: new Date("2026-11-22T12:00:00Z") }] });
    const res = await request(app).post("/admin/notifications/send").set({ Authorization: "Bearer adm-vibe", "Idempotency-Key": "abc-123" })
      .send({ title: "T", body: "B", filters: { oltNames: ["OLT X"] } }).expect(201);
    expect(res.body.data).toMatchObject({ id: "c1", successCount: 3 });
    expect(mockMulticast).not.toHaveBeenCalled();
    expect(mockSend).not.toHaveBeenCalled();
  });

  it("envia broadcast sem filtros usando tópico FCM (zero varredura de tokens)", async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ count: "100" }] }) // ensureProviderSegments (sendCampaign)
      .mockResolvedValueOnce({ rows: [{ created_at: new Date("2026-11-22T12:00:00Z") }] }) // INSERT (processing)
      .mockResolvedValueOnce({ rows: [{ count: "100" }] }) // ensureProviderSegments (previewAudience)
      .mockResolvedValueOnce({ rows: [{ matched_subscribers: "492", reachable_devices: "120" }] }) // preview
      .mockResolvedValueOnce({ rows: [] }); // UPDATE sent

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

  it("agenda campanha futura sem disparar FCM de imediato e permite cancelar", async () => {
    const futureIso = new Date(Date.now() + 3_600_000).toISOString();
    mockQuery
      .mockResolvedValueOnce({ rows: [{ count: "100" }] }) // ensureProviderSegments (sendCampaign)
      .mockResolvedValueOnce({ rows: [{ count: "100" }] }) // ensureProviderSegments (previewAudience)
      .mockResolvedValueOnce({ rows: [{ matched_subscribers: "40", reachable_devices: "18" }] }) // preview
      .mockResolvedValueOnce({ rows: [{ created_at: new Date("2026-11-23T15:00:00Z") }] }); // INSERT scheduled

    const res = await request(app)
      .post("/admin/notifications/send")
      .set({ Authorization: "Bearer adm-vibe" })
      .send({
        title: "Manutenção programada",
        body: "Janela às 02h.",
        filters: { oltNames: ["OLT ZTE - PAU AMARELO"] },
        scheduledFor: futureIso,
      })
      .expect(201);

    expect(res.body.data.status).toBe("scheduled");
    expect(res.body.data.scheduledFor).toBe(futureIso);
    expect(mockSend).not.toHaveBeenCalled();
    expect(mockMulticast).not.toHaveBeenCalled();

    mockQuery.mockResolvedValueOnce({ rowCount: 1 });
    await request(app)
      .delete(`/admin/notifications/scheduled/${res.body.data.id}?providerId=vibe`)
      .set({ Authorization: "Bearer adm-vibe" })
      .expect(200);
  });

  it("salva e consulta a régua automática de cobrança por push", async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ updated_at: new Date("2026-11-23T15:00:00Z") }] });
    const putRes = await request(app)
      .put("/admin/notifications/billing-rules")
      .set({ Authorization: "Bearer adm-vibe" })
      .send({ providerId: "vibe", enabled: true, daysBefore: [3, 1, 0], daysAfter: [3] })
      .expect(200);

    expect(putRes.body.data).toMatchObject({
      providerId: "vibe",
      enabled: true,
      daysBefore: [3, 1, 0],
      daysAfter: [3],
    });

    mockQuery.mockResolvedValueOnce({
      rows: [{ enabled: true, days_before: [3, 1, 0], days_after: [3], updated_at: new Date("2026-11-23T15:00:00Z") }],
    });
    const getRes = await request(app)
      .get("/admin/notifications/billing-rules?providerId=vibe")
      .set({ Authorization: "Bearer adm-vibe" })
      .expect(200);
    expect(getRes.body.data.daysBefore).toEqual([3, 1, 0]);
  });
});
