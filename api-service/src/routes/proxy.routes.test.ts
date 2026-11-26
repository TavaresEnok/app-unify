import express from "express";
import request from "supertest";
import http from "node:http";
import type net from "node:net";
import { once } from "node:events";
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";

const tokens = new Map<string, Record<string, unknown>>();
vi.mock("../services/postgres", () => ({
  getPgPool: () => ({ query: async () => ({ rows: [] }) }),
  requirePgPool: () => ({ query: async () => ({ rows: [] }) }),
  ensureCoreSchema: async () => undefined,
}));
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

const PDF = Buffer.concat([Buffer.from("%PDF-1.7\n"), Buffer.alloc(40, 3), Buffer.from("\n%%EOF")]);
const CPF = "12345678909";
type Reply = { status: number; body: Buffer | object; type?: string };
let reply: Reply;
const received: Array<{ path: string; body: any; auth?: string }> = [];
const proxy = http.createServer(async (req, res) => {
  let raw = "";
  for await (const chunk of req) raw += chunk;
  received.push({ path: req.url || "", body: JSON.parse(raw || "{}"), auth: req.headers.authorization });
  const body = Buffer.isBuffer(reply.body) ? reply.body : Buffer.from(JSON.stringify(reply.body));
  res.writeHead(reply.status, { "Content-Type": reply.type || (Buffer.isBuffer(reply.body) ? "application/pdf" : "application/json") });
  res.end(body);
});

let app: express.Express;
beforeAll(async () => {
  proxy.listen(0, "127.0.0.1");
  await once(proxy, "listening");
  process.env.PROXY_SGP_INTERNAL_URL = `http://127.0.0.1:${(proxy.address() as net.AddressInfo).port}`;
  vi.resetModules();
  const { proxyRouter } = await import("./proxy.routes");
  const { errorHandler } = await import("../middlewares/errorHandler");
  app = express();
  app.use(express.json());
  app.use((req, _res, next) => { req.correlationId = "test"; next(); });
  app.use(proxyRouter);
  app.use(errorHandler);
});
afterAll(async () => { proxy.close(); delete process.env.PROXY_SGP_INTERNAL_URL; });
beforeEach(() => {
  received.length = 0;
  tokens.clear();
  tokens.set("sub", { uid: `subscriber:p2:${CPF}`, role: "subscriber", cpfCnpj: CPF, providerId: "p2" });
  reply = { status: 200, body: PDF };
});

const get = (path: string, token: string | null = "sub") => {
  const req = request(app).get(path).buffer(true).parse((res, done) => {
    const chunks: Buffer[] = [];
    res.on("data", (chunk: Buffer) => chunks.push(chunk));
    res.on("end", () => done(null, Buffer.concat(chunks)));
  });
  return token ? req.set("Authorization", `Bearer ${token}`) : req;
};

describe("GET /subscriber/invoices/:id/boleto", () => {
  it("entrega o PDF com o CPF e o provedor da sessão, sem cache compartilhado", async () => {
    const res = await get("/subscriber/invoices/901/boleto?contratoId=100&cpfCnpj=98765432100").expect(200);
    expect(res.headers["content-type"]).toBe("application/pdf");
    expect(res.headers["content-disposition"]).toBe('inline; filename="boleto-901.pdf"');
    expect(res.headers["cache-control"]).toBe("private, no-store");
    expect(Buffer.compare(res.body as Buffer, PDF)).toBe(0);
    expect(received).toEqual([{ path: "/invoice/boleto-pdf", auth: "Bearer sub",
      body: { cpfCnpj: CPF, providerId: "p2", faturaId: "901", contratoId: "100" } }]);
  });

  it("recusa sem sessão e ids inválidos antes de chamar o proxy", async () => {
    await get("/subscriber/invoices/901/boleto", null).expect(401);
    await get("/subscriber/invoices/9a1/boleto").expect(400);
    await get("/subscriber/invoices/901/boleto?contratoId=1;2").expect(400);
    expect(received).toHaveLength(0);
  });

  it("traduz as respostas do proxy em mensagens claras", async () => {
    reply = { status: 404, body: { error: { code: "boleto-unavailable", message: "Boleto não disponível para esta fatura." } } };
    let res = await get("/subscriber/invoices/901/boleto").expect(404);
    expect(JSON.parse(res.body.toString())).toMatchObject({ error: { code: "boleto-unavailable", message: "Boleto não disponível para esta fatura." } });

    reply = { status: 429, body: { error: { message: "Muitas requisições." } } };
    res = await get("/subscriber/invoices/901/boleto").expect(429);
    expect(JSON.parse(res.body.toString()).error.code).toBe("resource-exhausted");

    reply = { status: 503, body: { error: { message: "detalhe interno" } } };
    res = await get("/subscriber/invoices/901/boleto").expect(502);
    expect(JSON.parse(res.body.toString()).error).toMatchObject({ code: "boleto-failed", message: "Não foi possível gerar o boleto agora. Tente de novo ou use o PIX." });

    reply = { status: 200, body: Buffer.from("<html>não é pdf</html>"), type: "application/pdf" };
    res = await get("/subscriber/invoices/901/boleto").expect(502);
    expect(JSON.parse(res.body.toString()).error.code).toBe("boleto-failed");
  });
});
