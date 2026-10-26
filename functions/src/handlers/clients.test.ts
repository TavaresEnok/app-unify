type Doc = Record<string, unknown>;

// Firestore em memória: só o suficiente para os handlers de clientes e dashboard.
const store = new Map<string, Doc>();
const batchDeletes: string[] = [];
const users = new Map<string, { customClaims?: Record<string, unknown> }>();

function snapshot(path: string) {
  const data = store.get(path);
  return { id: path.split("/").pop() as string, exists: data !== undefined, data: () => data };
}

function query(path: string, filters: Array<(doc: Doc) => boolean> = [], max = Infinity): any {
  const run = () => [...store.entries()]
    .filter(([key]) => key.startsWith(`${path}/`) && !key.slice(path.length + 1).includes("/"))
    .filter(([, doc]) => filters.every((filter) => filter(doc)))
    .slice(0, max)
    .map(([key]) => snapshot(key));
  return {
    where: (field: string, op: string, value: unknown) => query(path, [...filters, (doc: Doc) =>
      op === "in" ? (value as unknown[]).includes(doc[field]) :
      op === ">=" ? (doc[field] as number) >= (value as number) :
      doc[field] === value], max),
    orderBy: () => query(path, filters, max),
    limit: (n: number) => query(path, filters, n),
    get: async () => { const docs = run(); return { docs, size: docs.length }; },
  };
}

function collection(path: string): any {
  return {
    ...query(path),
    doc: (id: string) => ({
      path: `${path}/${id}`,
      get: async () => snapshot(`${path}/${id}`),
      collection: (name: string) => collection(`${path}/${id}/${name}`),
    }),
  };
}

jest.mock("../app/firebase", () => ({
  db: {
    collection: (name: string) => collection(name),
    batch: () => ({
      delete: (ref: { path: string }) => batchDeletes.push(ref.path),
      commit: async () => batchDeletes.forEach((path) => store.delete(path)),
    }),
  },
  auth: {
    getUser: async (uid: string) => {
      const user = users.get(uid);
      if (!user) throw new Error("not found");
      return user;
    },
  },
}));
jest.mock("firebase-admin/firestore", () => ({
  Timestamp: { fromMillis: (ms: number) => ms },
}));

import { deleteClient, getClientDetails, listProviderClients } from "./clients";
import { getDashboardData, getProviderDashboardData } from "./dashboard";

const call = (handler: any, requesterUid: string, payload: Record<string, unknown> = {}) =>
  handler({ requesterUid, payload, requestId: "request-1" });

beforeEach(() => {
  store.clear();
  batchDeletes.length = 0;
  users.clear();
  users.set("admin-a", { customClaims: { providerId: "prov-a" } });
  users.set("admin-b", { customClaims: { providerId: "prov-b" } });
  users.set("super", { customClaims: { superAdmin: true } });
});

describe("client handlers", () => {
  it("lists provider clients with contract credentials stripped", async () => {
    store.set("provedores/prov-a/clientes/c1", {
      nome: "Ana",
      contratos: [{ id: 1, senha: "123", contratoCentralSenha: "456", Token: "t", plano: "100M" }, null],
    });

    const result = await call(listProviderClients, "admin-a", { providerId: "prov-a" });

    expect(result).toEqual([{ id: "c1", nome: "Ana", contratos: [{ id: 1, plano: "100M" }, null] }]);
  });

  it("denies access to another provider's clients", async () => {
    await expect(call(listProviderClients, "admin-b", { providerId: "prov-a" }))
      .rejects.toMatchObject({ code: "permission-denied" });
    await expect(call(listProviderClients, "unknown", { providerId: "prov-a" }))
      .rejects.toMatchObject({ code: "unauthenticated" });
  });

  // O campo `id` do SGP, quando existe no documento, prevalece sobre o id do doc.
  it("finds a client by document id or by SGP id", async () => {
    store.set("provedores/prov-a/clientes/doc-1", { id: 42, nome: "Bia" });

    await expect(call(getClientDetails, "admin-a", { providerId: "prov-a", clientId: "doc-1" }))
      .resolves.toMatchObject({ id: 42, nome: "Bia", contratos: [] });
    await expect(call(getClientDetails, "admin-a", { providerId: "prov-a", clientId: "42" }))
      .resolves.toMatchObject({ id: 42, nome: "Bia" });
    await expect(call(getClientDetails, "admin-a", { providerId: "prov-a", clientId: "99" }))
      .rejects.toMatchObject({ code: "not-found" });
  });

  it("deletes the global client only when it belongs to the same provider", async () => {
    store.set("provedores/prov-a/clientes/c1", { nome: "Ana" });
    store.set("clientes/c1", { providerId: "prov-a" });
    store.set("provedores/prov-a/clientes/c2", { nome: "Caio" });
    store.set("clientes/c2", { providerId: "prov-b" });

    await call(deleteClient, "admin-a", { providerId: "prov-a", clientId: "c1" });
    await call(deleteClient, "admin-a", { providerId: "prov-a", clientId: "c2" });

    expect(store.has("clientes/c1")).toBe(false);
    expect(store.has("provedores/prov-a/clientes/c2")).toBe(false);
    expect(store.get("clientes/c2")).toEqual({ providerId: "prov-b" });
  });
});

describe("dashboard handlers", () => {
  beforeEach(() => {
    store.set("provedores/prov-a", { name: "Provedor A" });
    store.set("provedores/prov-b", {});
    store.set("clientes/c1", { providerId: "prov-a", status: "Ativo" });
    store.set("clientes/c2", { providerId: "prov-a", status: "Inativo" });
    store.set("clientes/c3", { providerId: "prov-b", status: "Ativo" });
    store.set("tickets/t1", { providerId: "prov-a", status: "Aberto" });
    store.set("tickets/t2", { providerId: "prov-a", status: "Fechado" });
  });

  it("restricts the global dashboard to super admins", async () => {
    await expect(call(getDashboardData, "admin-a")).rejects.toMatchObject({ code: "permission-denied" });

    const result = await call(getDashboardData, "super");

    expect(result.stats).toMatchObject({ providerCount: 2, clientCount: 3, openTicketsCount: 1 });
    expect(result.chartData).toEqual([
      { name: "Provedor A", clientes: 2 },
      { name: "prov-b", clientes: 1 },
    ]);
  });

  it("counts only the provider's own data and active clients", async () => {
    const result = await call(getProviderDashboardData, "admin-a", { providerId: "prov-a" });

    expect(result.stats).toEqual({
      clientCount: 2,
      totalClients: 2,
      activeClientCount: 1,
      openTicketsCount: 1,
      notificationCount: 0,
    });
    expect(result.recentTickets.map((ticket: { id: string }) => ticket.id)).toEqual(["t1", "t2"]);
  });
});
