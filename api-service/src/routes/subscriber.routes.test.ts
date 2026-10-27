import axios from "axios";
import express from "express";
import request from "supertest";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

// Firestore em memória: { "provedores/p1": {...}, "provedores/p1/secrets/sgp": {...} }.
const docs = new Map<string, Record<string, unknown>>();
const tokens = new Map<string, Record<string, unknown>>();

function docRef(path: string): any {
  return {
    get: async () => ({ exists: docs.has(path), data: () => docs.get(path) }),
    collection: (name: string) => collectionRef(`${path}/${name}`),
  };
}

function collectionRef(path: string): any {
  return {
    doc: (id: string) => docRef(`${path}/${id}`),
    where: (field: string, _op: string, value: unknown) => ({
      limit: () => ({
        get: async () => ({
          docs: [...docs.entries()]
            .filter(([key, data]) => key.startsWith(`${path}/`) && data[field] === value)
            .map(([, data]) => ({ exists: true, data: () => data })),
        }),
      }),
    }),
  };
}

vi.mock("../services/firebaseAdmin", () => ({
  firestore: { collection: (name: string) => collectionRef(name) },
  firebaseAuth: {
    verifyIdToken: async (token: string) => {
      const user = tokens.get(token);
      if (!user) throw new Error("invalid");
      return user;
    },
  },
}));

const lookupMock = vi.hoisted(() => vi.fn());
vi.mock("node:dns/promises", () => ({ lookup: lookupMock }));

const { subscriberRouter } = await import("./subscriber.routes");
const { errorHandler } = await import("../middlewares/errorHandler");
const { assertSafeSgpBaseUrl } = await import("../services/sgpClient");

const app = express();
app.use(express.json());
app.use((req, _res, next) => { req.correlationId = "test"; next(); });
app.use(subscriberRouter);
app.use(errorHandler);

const CPF = "12345678901";
type Call = { url: string; body: any };
let calls: Call[];
let sgpResponses: Record<string, (body: any) => unknown>;

function contrato(id: number, valorAberto: number, extra: Record<string, unknown> = {}) {
  return { contratoId: id, contratoCentralSenha: `senha${id}`, contratoValorAberto: valorAberto, razaoSocial: "Fulano", servico_plano: `${id}00 MEGA`, ...extra };
}

function asSubscriber(token = "sub") {
  return { Authorization: `Bearer ${token}` };
}

beforeEach(() => {
  docs.clear();
  tokens.clear();
  calls = [];
  lookupMock.mockReset();
  lookupMock.mockResolvedValue([{ address: "200.160.2.3", family: 4 }]);
  docs.set("provedores/p1", { details: { systemUrl: "https://p1.sgp.net.br/" } });
  docs.set("provedores/p1/secrets/sgp", { integrations: { apiToken: "tok-p1", appName: "app-p1" } });
  docs.set("provedores/p2", {});
  docs.set("provedores/p2/secrets/sgp", { integrations: { apiToken: "tok-p2", appName: "app-p2", sgpBaseUrl: "https://p2.sgp.net.br" } });
  docs.set(`clientes/${CPF}`, { providerId: "p2" });
  tokens.set("sub", { uid: CPF });
  sgpResponses = {
    "/ws/ura/consultacliente/": () => ({ contratos: [contrato(1, 0), contrato(2, 99.9)] }),
  };
  vi.spyOn(axios, "create").mockReturnValue({
    post: async (url: string, body: any) => {
      calls.push({ url, body });
      const path = new URL(url).pathname;
      const handler = sgpResponses[path];
      if (!handler) throw new Error(`rota SGP inesperada: ${path}`);
      return { data: handler(body) };
    },
  } as any);
});

afterEach(() => vi.restoreAllMocks());

describe("credenciais SGP por provedor", () => {
  it("usa o SGP e o token do provedor dono do CPF", async () => {
    await request(app).post("/getClientData").set(asSubscriber()).send({ cpfCnpj: CPF }).expect(200);
    expect(calls[0].url).toBe("https://p2.sgp.net.br/ws/ura/consultacliente/");
    expect(calls[0].body).toMatchObject({ token: "tok-p2", app: "app-p2", cpfcnpj: CPF });
  });

  it("prefere o providerId do token do assinante", async () => {
    tokens.set("sub", { uid: CPF, providerId: "p1" });
    await request(app).post("/getClientData").set(asSubscriber()).send({ cpfCnpj: CPF }).expect(200);
    expect(calls[0].url).toBe("https://p1.sgp.net.br/ws/ura/consultacliente/");
    expect(calls[0].body.token).toBe("tok-p1");
  });

  it("não cai no SGP global quando o provedor não tem integração", async () => {
    docs.delete("provedores/p2/secrets/sgp");
    const response = await request(app).post("/getInvoices").set(asSubscriber()).send({ cpfCnpj: CPF }).expect(503);
    expect(response.body.error.code).toBe("service-unavailable");
    expect(calls).toHaveLength(0);
  });

  it("bloqueia admin de outro provedor e libera o do provedor dono", async () => {
    tokens.set("adm-p1", { uid: "a1", providerId: "p1" });
    tokens.set("adm-p2", { uid: "a2", providerId: "p2" });
    await request(app).post("/getClientData").set(asSubscriber("adm-p1")).send({ cpfCnpj: CPF }).expect(403);
    await request(app).post("/getClientData").set(asSubscriber("adm-p2")).send({ cpfCnpj: CPF }).expect(200);
    expect(calls[0].body.token).toBe("tok-p2");
  });

  it("superAdmin pode escolher o provedor pelo corpo", async () => {
    tokens.set("root", { uid: "root", superAdmin: true });
    await request(app).post("/getClientData").set(asSubscriber("root")).send({ cpfCnpj: CPF, providerId: "p1" }).expect(200);
    expect(calls[0].body.token).toBe("tok-p1");
  });

  it("impede assinante de consultar outro CPF", async () => {
    await request(app).post("/getInvoices").set(asSubscriber()).send({ cpfCnpj: "99999999999" }).expect(403);
  });
});

describe("todos os contratos", () => {
  it("getClientData lista todos e soma o valor em aberto", async () => {
    sgpResponses["/api/central/verificaacesso/"] = () => ({ online: true });
    const response = await request(app).post("/getClientData").set(asSubscriber()).send({ cpfCnpj: CPF }).expect(200);
    expect(response.body.data.contratoId).toBe("1");
    expect(response.body.data.totalAberto).toBe("R$ 99,90");
    expect(response.body.data.contratos.map((item: any) => item.contratoId)).toEqual(["1", "2"]);
  });

  it("getClientData respeita o contratoId pedido e rejeita contrato alheio", async () => {
    sgpResponses["/api/central/verificaacesso/"] = () => ({ online: false });
    const response = await request(app).post("/getClientData").set(asSubscriber()).send({ cpfCnpj: CPF, contratoId: 2 }).expect(200);
    expect(response.body.data.contratoId).toBe("2");
    expect(response.body.data.billValue).toBe("R$ 99,90");
    await request(app).post("/getClientData").set(asSubscriber()).send({ cpfCnpj: CPF, contratoId: 777 }).expect(404);
  });

  it("getConsumptionData soma o consumo de todos os contratos", async () => {
    sgpResponses["/api/central/extratouso/"] = () => ({ total: 2 * 1024 ** 3, plano: "300 GB" });
    const response = await request(app).post("/getConsumptionData").set(asSubscriber()).send({ cpfCnpj: CPF }).expect(200);
    expect(response.body.data.usedGb).toBe(4);
    expect(response.body.data.totalGb).toBe(600);
    expect(response.body.data.contratos).toHaveLength(2);
  });

  it("makePaymentPromise libera todos os contratos com débito", async () => {
    sgpResponses["/ws/ura/consultacliente/"] = () => ({ contratos: [contrato(1, 0), contrato(2, 10), contrato(3, 20)] });
    sgpResponses["/api/ura/liberacaopromessa/"] = () => ({ status: true, msg: "ok" });
    const response = await request(app).post("/makePaymentPromise").set(asSubscriber()).send({ cpfCnpj: CPF }).expect(200);
    const promised = calls.filter((call) => call.url.endsWith("/liberacaopromessa/")).map((call) => call.body.contrato);
    expect(promised).toEqual(["2", "3"]);
    expect(response.body.resultados).toHaveLength(2);
  });

  it("makePaymentPromise devolve 409 quando o SGP rejeita todos", async () => {
    sgpResponses["/api/ura/liberacaopromessa/"] = () => ({ status: false, msg: "Já existe promessa" });
    const response = await request(app).post("/makePaymentPromise").set(asSubscriber()).send({ cpfCnpj: CPF, contratoId: "1" }).expect(409);
    expect(response.body.error.message).toBe("Já existe promessa");
  });

  it("getInvoices filtra por contrato quando pedido", async () => {
    sgpResponses["/api/ura/titulos/"] = (body) => ({ titulos: [{ id: body.status, valor: 10, contrato: 2 }] });
    const response = await request(app).post("/getInvoices").set(asSubscriber()).send({ cpfCnpj: CPF, contratoId: "2" }).expect(200);
    const titulos = calls.filter((call) => call.url.endsWith("/titulos/"));
    expect(titulos.every((call) => call.body.contrato === "2" && call.body.token === "tok-p2")).toBe(true);
    expect(response.body.data).toHaveLength(2);
    expect(response.body.data[0].contratoId).toBe(2);
  });
});

describe("assertSafeSgpBaseUrl", () => {
  it.each([
    "http://[::1]:3002",
    "http://127.0.0.1",
    "http://[::ffff:10.0.0.1]",
    "ftp://p1.sgp.net.br",
  ])("rejeita %s", async (url) => {
    await expect(assertSafeSgpBaseUrl(url)).rejects.toThrow();
  });

  it("rejeita nome que resolve para loopback (ex.: 127.0.0.1.nip.io)", async () => {
    lookupMock.mockResolvedValue([{ address: "127.0.0.1", family: 4 }]);
    await expect(assertSafeSgpBaseUrl("http://127.0.0.1.nip.io")).rejects.toThrow(/interno/);
  });

  it("rejeita quando algum endereço IPv6 resolvido é interno", async () => {
    lookupMock.mockResolvedValue([{ address: "200.160.2.3", family: 4 }, { address: "fd00::1", family: 6 }]);
    await expect(assertSafeSgpBaseUrl("https://misto.example")).rejects.toThrow(/interno/);
  });

  it("aceita host público e remove a barra final", async () => {
    await expect(assertSafeSgpBaseUrl("https://p1.sgp.net.br/")).resolves.toBe("https://p1.sgp.net.br");
  });
});
