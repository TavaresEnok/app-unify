import { Timestamp, type Firestore } from "firebase-admin/firestore";

export interface DashboardSqlQueryable {
  query<R = Record<string, unknown>>(text: string, values?: unknown[]): Promise<{ rows: R[] }>;
}

async function count(query: FirebaseFirestore.Query): Promise<number> {
  return (await query.count().get()).data().count;
}

interface PgTableFlags {
  has_clients: boolean;
  has_segments: boolean;
  has_campaigns: boolean;
  has_devices: boolean;
}

async function inspectPgTables(pg: DashboardSqlQueryable): Promise<PgTableFlags> {
  const res = await pg.query<PgTableFlags>(`
    SELECT
      to_regclass('public.sgp_clients') IS NOT NULL AS has_clients,
      to_regclass('public.subscriber_segments') IS NOT NULL AS has_segments,
      to_regclass('public.notification_campaigns') IS NOT NULL AS has_campaigns,
      to_regclass('public.subscriber_devices') IS NOT NULL AS has_devices
  `);
  return res.rows[0] || { has_clients: false, has_segments: false, has_campaigns: false, has_devices: false };
}

export async function loadGlobalDashboard(db: Firestore, pg: DashboardSqlQueryable | null = null) {
  const oneDayAgo = Timestamp.fromMillis(Date.now() - 24 * 60 * 60 * 1000);
  let flags: PgTableFlags | null = null;
  if (pg) {
    try {
      flags = await inspectPgTables(pg);
    } catch (error) {
      console.warn(JSON.stringify({ severity: "WARNING", message: "dashboard.pg.inspect_failed", error: (error as Error).message }));
    }
  }

  const [providers, openTicketsCount, recentTickets] = await Promise.all([
    db.collection("provedores").select("name").get(),
    count(db.collection("tickets").where("status", "in", ["Aberto", "Em Andamento"])),
    db.collection("tickets").orderBy("updatedAt", "desc").limit(5).get(),
  ]);

  const chartProviders = providers.docs.slice(0, 6);

  // Clientes e notificações preferem o PostgreSQL local (custo zero de Firestore);
  // caem para o Firestore automaticamente quando o banco local não está ativo.
  const [clientCount, notificationCount, appUsersCount] = await Promise.all([
    pg && flags?.has_clients
      ? pg.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM sgp_clients`)
        .then((r) => Number(r.rows[0]?.count || 0))
      : count(db.collection("clientes")),
    pg && flags?.has_campaigns
      ? pg.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM notification_campaigns WHERE COALESCE(status, 'sent') = 'sent' AND created_at >= NOW() - INTERVAL '24 hours'`)
        .then((r) => Number(r.rows[0]?.count || 0))
      : count(db.collection("notifications").where("createdAt", ">=", oneDayAgo)),
    pg && flags?.has_devices
      ? pg.query<{ count: string }>(`SELECT COUNT(DISTINCT (provider_id, cpfcnpj))::text AS count FROM subscriber_devices WHERE fcm_token <> ''`)
        .then((r) => Number(r.rows[0]?.count || 0))
      : Promise.resolve(undefined),
  ]);

  let chartData: Array<{ name: string; clientes: number }>;
  if (pg && flags?.has_clients && chartProviders.length > 0) {
    const providerIds = chartProviders.map((p) => p.id);
    const grouped = await pg.query<{ provider_id: string; count: string }>(
      `SELECT provider_id, COUNT(*)::text AS count
         FROM sgp_clients
        WHERE provider_id = ANY($1::text[])
        GROUP BY provider_id`,
      [providerIds],
    );
    const byId = new Map(grouped.rows.map((r) => [r.provider_id, Number(r.count || 0)]));
    chartData = chartProviders.map((provider) => ({
      name: provider.data().name || provider.id,
      clientes: byId.get(provider.id) ?? 0,
    }));
  } else {
    // The panel displays six providers. Do not issue 100+ count queries for
    // invisible chart rows when tenants grow; global totals are separate counts.
    chartData = new Array(chartProviders.length);
    let next = 0;
    await Promise.all(Array.from({ length: Math.min(4, chartProviders.length) }, async () => {
      while (next < chartProviders.length) {
        const index = next++, provider = chartProviders[index];
        chartData[index] = {
          name: provider.data().name || provider.id,
          clientes: await count(db.collection("clientes").where("providerId", "==", provider.id)),
        };
      }
    }));
  }

  return {
    stats: {
      providerCount: providers.size,
      clientCount,
      notificationCount,
      openTicketsCount,
      ...(typeof appUsersCount === "number" ? { appUsersCount } : {}),
    },
    chartData,
    recentTickets: recentTickets.docs.map((ticket) => ({ id: ticket.id, ...ticket.data() })),
  };
}

export async function loadProviderDashboard(db: Firestore, providerId: string, pg: DashboardSqlQueryable | null = null) {
  let flags: PgTableFlags | null = null;
  if (pg) {
    try {
      flags = await inspectPgTables(pg);
    } catch (error) {
      console.warn(JSON.stringify({ severity: "WARNING", message: "dashboard.pg.inspect_failed", error: (error as Error).message }));
    }
  }

  const clients = db.collection("clientes").where("providerId", "==", providerId);
  const tickets = db.collection("tickets").where("providerId", "==", providerId);

  const clientCountPromise = pg && flags?.has_clients
    ? pg.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM sgp_clients WHERE provider_id = $1`, [providerId])
      .then((r) => Number(r.rows[0]?.count || 0))
    : count(clients);

  const activeClientCountPromise = pg && flags?.has_segments
    ? pg.query<{ count: string }>(
      `SELECT COUNT(DISTINCT cpfcnpj)::text AS count
         FROM subscriber_segments
        WHERE provider_id = $1
          AND LOWER(TRIM(contract_status)) IN ('ativo', 'online', 'liberado', 'normal')`,
      [providerId],
    ).then((r) => Number(r.rows[0]?.count || 0))
    : pg && flags?.has_clients
      ? clientCountPromise
      : count(clients.where("status", "in", ["Ativo", "ativo", "ATIVO", "Online", "online"]));

  const notificationCountPromise = pg && flags?.has_campaigns
    ? pg.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM notification_campaigns WHERE provider_id = $1 AND COALESCE(status, 'sent') = 'sent'`, [providerId])
      .then((r) => Number(r.rows[0]?.count || 0))
    : count(db.collection("notifications").where("providerId", "==", providerId));

  const appUsersCountPromise = pg && flags?.has_devices
    ? pg.query<{ count: string }>(
      `SELECT COUNT(DISTINCT cpfcnpj)::text AS count
         FROM subscriber_devices
        WHERE provider_id = $1 AND fcm_token <> ''`,
      [providerId],
    ).then((r) => Number(r.rows[0]?.count || 0))
    : Promise.resolve(undefined);

  const [clientCount, activeClientCount, openTicketsCount, notificationCount, recentTickets, appUsersCount] = await Promise.all([
    clientCountPromise,
    activeClientCountPromise,
    count(tickets.where("status", "in", ["Aberto", "Em Andamento"])),
    notificationCountPromise,
    tickets.orderBy("updatedAt", "desc").limit(5).get(),
    appUsersCountPromise,
  ]);

  return {
    stats: {
      clientCount,
      totalClients: clientCount,
      activeClientCount,
      openTicketsCount,
      notificationCount,
      ...(typeof appUsersCount === "number" ? { appUsersCount } : {}),
    },
    recentTickets: recentTickets.docs.map((ticket) => ({ id: ticket.id, ...ticket.data() })),
  };
}
