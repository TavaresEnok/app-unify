import { Router } from "express";
import { verifyToken, verifyAdmin } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { ensureCoreSchema, getPgPool, requirePgPool } from "../services/postgres";
import { loadGlobalDashboardPg, loadProviderDashboardPg } from "../services/dashboardPg";

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
  const pool = getPgPool();
  if (!pool) return;
  await cachedDashboard("global", () => loadGlobalDashboardPg(pool));
}

function authorizePanel(claims: Express.Request["user"], providerId?: string) {
  if (!claims || (claims?.superAdmin !== true &&
      (!providerId || claims?.role !== "providerAdmin" || claims.providerId !== providerId))) {
    throw new ApiError(403, "Sem permissão para este dashboard.", "permission-denied");
  }
}

dashboardRouter.get("/panel", asyncRoute(async (req, res) => {
  authorizePanel(req.user);
  res.setHeader("Cache-Control", "private, no-store");
  res.json({ data: await cachedDashboard("global", () => loadGlobalDashboardPg(requirePgPool())) });
}));

dashboardRouter.get("/panel/providers/:providerId", asyncRoute(async (req, res) => {
  const providerId = String(req.params.providerId);
  authorizePanel(req.user, providerId);
  res.setHeader("Cache-Control", "private, no-store");
  res.json({ data: await cachedDashboard(`provider:${providerId}`, () => loadProviderDashboardPg(requirePgPool(), providerId)) });
}));

dashboardRouter.get("/", asyncRoute(async (req, res) => {
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  if (req.user?.superAdmin === true) {
    const [providers, openTickets, tickets, users] = await Promise.all([
      pool.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM providers`),
      pool.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM tickets WHERE status IN ('Aberto', 'Em Andamento')`),
      pool.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM tickets`),
      pool.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM sgp_clients`),
    ]);
    return res.json({ data: {
      totalProviders: Number(providers.rows[0]?.count || 0),
      totalTickets: Number(tickets.rows[0]?.count || 0),
      openTickets: Number(openTickets.rows[0]?.count || 0),
      totalUsers: Number(users.rows[0]?.count || 0),
    } });
  }
  const providerId = typeof req.user?.providerId === "string" ? req.user.providerId : "";
  if (!providerId) throw new ApiError(403, "Sem provedor associado.", "permission-denied");
  const [openTickets, tickets, clients] = await Promise.all([
    pool.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM tickets WHERE provider_id = $1 AND status IN ('Aberto', 'Em Andamento')`, [providerId]),
    pool.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM tickets WHERE provider_id = $1`, [providerId]),
    pool.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM sgp_clients WHERE provider_id = $1`, [providerId]),
  ]);
  return res.json({ data: {
    totalProviders: 1,
    totalTickets: Number(tickets.rows[0]?.count || 0),
    openTickets: Number(openTickets.rows[0]?.count || 0),
    totalUsers: Number(clients.rows[0]?.count || 0),
  } });
}));
