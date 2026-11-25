import express from "express";
import request from "supertest";
import { beforeEach, describe, expect, it, vi } from "vitest";

const tokens = new Map<string, Record<string, unknown>>();
const mockQuery = vi.fn();
const mockIncidentsGet = vi.fn();

vi.mock("../services/self-auth", () => ({
  verifyLiveSession: async (_pool: unknown, token: string) => {
    const user = tokens.get(token);
    if (!user) throw Object.assign(new Error("invalid"), { code: "auth/invalid-id-token" });
    return user;
  },
}));

vi.mock("../services/postgres", () => ({
  getPgPool: () => ({
    query: (sql: string, params?: unknown[]) => {
      if (String(sql).includes("FROM incidents")) return mockIncidentsGet();
      return mockQuery(sql, params);
    },
  }),
  requirePgPool: () => ({ query: mockQuery }),
  ensureCoreSchema: vi.fn(async () => undefined),
  ensureNotificationSchema: vi.fn(async () => undefined),
}));

const { adminDiagnosticsRouter, diagnosticsRouter } = await import("./diagnostics.routes");
const { clearIncidentCacheForTests, subscriberRouter } = await import("./subscriber.routes");
const { errorHandler } = await import("../middlewares/errorHandler");

const app = express();
app.use(express.json());
app.use((req, _res, next) => { req.correlationId = "test"; next(); });
app.use("/diagnostic", diagnosticsRouter);
app.use("/admin/diagnostics", adminDiagnosticsRouter);
app.use(subscriberRouter);
app.use(errorHandler);

describe("diagnostics & subscriber incidents routes", () => {
  beforeEach(() => {
    tokens.clear();
    mockQuery.mockReset();
    mockIncidentsGet.mockReset();
    clearIncidentCacheForTests();
    tokens.set("sub-vibe", { uid: "10331142430", role: "subscriber", providerId: "vibe", cpfCnpj: "10331142430" });
    tokens.set("adm-vibe", { uid: "u1", role: "providerAdmin", providerId: "vibe" });
    tokens.set("adm-other", { uid: "u2", role: "providerAdmin", providerId: "other" });
  });

  it("salva diagnóstico do assinante enriquecido com OLT/Bairro do PostgreSQL", async () => {
    mockQuery
      .mockResolvedValueOnce({
        rows: [{
          contrato_id: "86069",
          client_name: "Maria Silva",
          plano: "VIBE 500 MEGA",
          olt_name: "OLT ZTE - PAU AMARELO",
          bairro: "PAU AMARELO",
          cidade: "PAULISTA",
        }],
      })
      .mockResolvedValueOnce({
        rows: [{ created_at: new Date("2026-11-23T12:00:00Z") }],
      });

    const res = await request(app)
      .post("/diagnostic/results")
      .set({ Authorization: "Bearer sub-vibe" })
      .send({
        mode: "complete",
        verdict: "degraded",
        verdictHeadline: "Sinal óptico atenuado",
        cause: "fiber_attenuation",
        summary: { downloadMbps: 185.4, pingMs: 14, onuRxDbm: -27.2, needsProviderSupport: true },
      })
      .expect(201);

    expect(res.body.success).toBe(true);
    expect(res.body.data).toMatchObject({
      providerId: "vibe",
      cpfCnpj: "10331142430",
      contratoId: "86069",
      oltName: "OLT ZTE - PAU AMARELO",
      bairro: "PAU AMARELO",
      verdict: "degraded",
    });

    // Admin não pode postar na rota de assinante
    await request(app)
      .post("/diagnostic/results")
      .set({ Authorization: "Bearer adm-vibe" })
      .send({ verdict: "healthy" })
      .expect(403);
  });

  it("isola diagnósticos por provedor no /admin/diagnostics e bloqueia assinantes", async () => {
    await request(app).get("/admin/diagnostics?providerId=vibe").set({ Authorization: "Bearer sub-vibe" }).expect(403);
    await request(app).get("/admin/diagnostics?providerId=vibe").set({ Authorization: "Bearer adm-other" }).expect(403);

    mockQuery.mockResolvedValueOnce({
      rows: [{
        id: "diag-1",
        provider_id: "vibe",
        cpfcnpj: "10331142430",
        contrato_id: "86069",
        client_name: "Maria Silva",
        plan_name: "VIBE 500 MEGA",
        mode: "complete",
        verdict: "critical",
        verdict_headline: "Sem sinal óptico",
        cause: "fiber_cut",
        summary: { downloadMbps: 0, pingMs: 0, needsProviderSupport: true },
        olt_name: "OLT ZTE - PAU AMARELO",
        bairro: "PAU AMARELO",
        cidade: "PAULISTA",
        created_at: new Date("2026-11-23T12:00:00Z"),
      }],
    });

    const listRes = await request(app)
      .get("/admin/diagnostics?providerId=vibe")
      .set({ Authorization: "Bearer adm-vibe" })
      .expect(200);
    expect(listRes.body.data).toHaveLength(1);
    expect(listRes.body.data[0].oltName).toBe("OLT ZTE - PAU AMARELO");

    mockQuery.mockResolvedValueOnce({ rowCount: 1 });
    await request(app)
      .delete("/admin/diagnostics/diag-1?providerId=vibe")
      .set({ Authorization: "Bearer adm-vibe" })
      .expect(200);
  });

  it("retorna incidentes ativos com cache de 30s e correspondência de área pelo PostgreSQL", async () => {
    mockIncidentsGet.mockResolvedValue({
      rows: [
        {
          id: "inc-1",
          title: "Manutenção na OLT Pau Amarelo",
          message: "Troca de placa programada até 16h.",
          severity: "warning",
          area: "Pau Amarelo",
          estimated_resolution: "16:00",
          created_at: new Date("2026-11-23T11:00:00Z"),
        },
        {
          id: "inc-2",
          title: "Instabilidade Centro",
          message: "Equipe em campo.",
          severity: "critical",
          area: "Centro",
          estimated_resolution: null,
          created_at: new Date("2026-11-23T11:30:00Z"),
        },
      ],
    });
    mockQuery.mockResolvedValue({
      rows: [{ olt_name: "OLT ZTE - PAU AMARELO", bairro: "PAU AMARELO", cidade: "PAULISTA" }],
    });

    const r1 = await request(app)
      .get("/subscriber/incidents")
      .set({ Authorization: "Bearer sub-vibe" })
      .expect(200);
    const r2 = await request(app)
      .get("/subscriber/incidents")
      .set({ Authorization: "Bearer sub-vibe" })
      .expect(200);

    expect(mockIncidentsGet).toHaveBeenCalledTimes(1); // cache de 30s ativo
    expect(r1.body.data[0].id).toBe("inc-1");
    expect(r1.body.data[0].matchesArea).toBe(true);
    expect(r1.body.data[1].matchesArea).toBe(false);
    expect(r2.body.data).toHaveLength(2);
  });

  it("detecta clusters de possível queda por OLT/Bairro no /admin/diagnostics/outage-radar", async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [{
        scope: "olt",
        area_name: "OLT ZTE - PAU AMARELO",
        cidade: "PAULISTA",
        distinct_subscribers: "4",
        critical_count: "3",
        degraded_count: "1",
        total_diagnostics: "5",
        last_seen_at: new Date("2026-11-23T15:00:00Z"),
      }],
    });

    const res = await request(app)
      .get("/admin/diagnostics/outage-radar?providerId=vibe&windowMinutes=45&minSubscribers=3")
      .set({ Authorization: "Bearer adm-vibe" })
      .expect(200);

    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0]).toMatchObject({
      scope: "olt",
      areaName: "OLT ZTE - PAU AMARELO",
      distinctSubscribers: 4,
      criticalCount: 3,
    });
  });
});

