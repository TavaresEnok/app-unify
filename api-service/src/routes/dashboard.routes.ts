import { Router } from "express";
import { verifyToken, verifyAdmin } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { firestore } from "../services/firebaseAdmin";
import { loadGlobalDashboard, loadProviderDashboard } from "../services/dashboardData";

export const dashboardRouter = Router();
dashboardRouter.use(verifyToken, verifyAdmin);

const cache = new Map<string, { expires: number; value: Promise<unknown> }>();
async function cachedDashboard(key: string, load: () => Promise<unknown>) {
  const current = cache.get(key);
  if (current && current.expires > Date.now()) return current.value;
  if (cache.size >= 128) cache.delete(cache.keys().next().value!);
  const value = load();
  cache.set(key, { expires: Date.now() + 10000, value });
  try { return await value; } catch (error) { cache.delete(key); throw error; }
}

export async function warmDashboardData() {
  // Establish Firestore connections and prepare the first read at process start,
  // rather than charging this initialization to the first administrator.
  await cachedDashboard("global", () => loadGlobalDashboard(firestore));
}

// Keep the fresh account/role check used by the queue handlers: a revoked role
// must not regain access through an older, still cryptographically valid token.
function authorizePanel(claims: Express.Request["user"], providerId?: string) {
  if (!claims || (claims?.superAdmin !== true &&
      (!providerId || claims?.role !== "providerAdmin" || claims.providerId !== providerId))) {
    throw new ApiError(403, "Sem permissão para este dashboard.", "permission-denied");
  }
}

dashboardRouter.get("/panel", asyncRoute(async (req, res) => {
  authorizePanel(req.user);
  res.setHeader("Cache-Control", "private, no-store");
  res.json({ data: await cachedDashboard("global", () => loadGlobalDashboard(firestore)) });
}));

dashboardRouter.get("/panel/providers/:providerId", asyncRoute(async (req, res) => {
  const providerId = String(req.params.providerId);
  authorizePanel(req.user, providerId);
  res.setHeader("Cache-Control", "private, no-store");
  res.json({ data: await cachedDashboard(`provider:${providerId}`, () => loadProviderDashboard(firestore, providerId)) });
}));

dashboardRouter.get("/", asyncRoute(async (req, res) => {
  if (req.user?.superAdmin === true) {
    const [providers, openTickets, tickets, users] = await Promise.all([
      firestore.collection("provedores").count().get(),
      firestore.collection("tickets").where("status", "in", ["Aberto", "Em Andamento"]).count().get(),
      firestore.collection("tickets").count().get(),
      firestore.collection("clientes").count().get(),
    ]);
    return res.json({ data: {
      totalProviders: providers.data().count,
      totalTickets: tickets.data().count,
      openTickets: openTickets.data().count,
      totalUsers: users.data().count,
    } });
  }
  const providerId = typeof req.user?.providerId === "string" ? req.user.providerId : "";
  if (!providerId) throw new ApiError(403, "Sem provedor associado.", "permission-denied");
  const [openTickets, tickets, clients] = await Promise.all([
    firestore.collection("tickets").where("providerId", "==", providerId).where("status", "in", ["Aberto", "Em Andamento"]).count().get(),
    firestore.collection("tickets").where("providerId", "==", providerId).count().get(),
    firestore.collection("clientes").where("providerId", "==", providerId).count().get(),
  ]);
  return res.json({ data: { totalProviders: 1, totalTickets: tickets.data().count, openTickets: openTickets.data().count, totalUsers: clients.data().count } });
}));
