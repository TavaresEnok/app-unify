import { ensureCoreSchema, ensureNotificationSchema, type SqlQueryable } from "./postgres";

export async function loadGlobalDashboardPg(pg: SqlQueryable) {
  await ensureNotificationSchema(pg);

  const [providersRes, openTicketsRes, recentTicketsRes, clientCountRes, notifCountRes, appUsersRes, chartRes] =
    await Promise.all([
      pg.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM providers WHERE NOT (data ? 'deletedAt')`),
      pg.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM tickets WHERE status IN ('Aberto', 'Em Andamento')`),
      pg.query<{
        id: string;
        provider_id: string;
        provider_name: string;
        subject: string;
        status: string;
        created_by_email: string;
        updated_at: Date;
      }>(`SELECT id, provider_id, provider_name, subject, status, created_by_email, updated_at FROM tickets ORDER BY updated_at DESC LIMIT 5`),
      pg.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM sgp_clients`),
      pg.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM notification_campaigns WHERE COALESCE(status, 'sent') = 'sent' AND created_at >= NOW() - INTERVAL '24 hours'`),
      pg.query<{ count: string }>(`SELECT COUNT(DISTINCT (provider_id, cpfcnpj))::text AS count FROM subscriber_devices WHERE fcm_token <> ''`),
      pg.query<{ id: string; name: string; clientes: string }>(`
        SELECT p.id, COALESCE(NULLIF(p.name, ''), p.id) AS name, COUNT(c.client_id)::text AS clientes
          FROM providers p
          LEFT JOIN sgp_clients c ON c.provider_id = p.id
         WHERE NOT (p.data ? 'deletedAt')
         GROUP BY p.id, p.name
         ORDER BY p.name ASC, p.id ASC
         LIMIT 6
      `),
    ]);

  return {
    stats: {
      providerCount: Number(providersRes.rows[0]?.count || 0),
      clientCount: Number(clientCountRes.rows[0]?.count || 0),
      notificationCount: Number(notifCountRes.rows[0]?.count || 0),
      openTicketsCount: Number(openTicketsRes.rows[0]?.count || 0),
      appUsersCount: Number(appUsersRes.rows[0]?.count || 0),
    },
    chartData: chartRes.rows.map((r) => ({
      name: r.name,
      clientes: Number(r.clientes || 0),
    })),
    recentTickets: recentTicketsRes.rows.map((t) => ({
      id: t.id,
      providerId: t.provider_id,
      providerName: t.provider_name,
      subject: t.subject,
      status: t.status,
      userEmail: t.created_by_email,
      updatedAt: t.updated_at instanceof Date ? t.updated_at.toISOString() : t.updated_at,
    })),
  };
}

export async function loadProviderDashboardPg(pg: SqlQueryable, providerId: string) {
  await ensureCoreSchema(pg);
  await ensureNotificationSchema(pg);

  const [clientCountRes, activeCountRes, openTicketsRes, notifCountRes, appUsersRes, recentTicketsRes] =
    await Promise.all([
      pg.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM sgp_clients WHERE provider_id = $1`, [providerId]),
      pg.query<{ count: string }>(
        `SELECT COUNT(DISTINCT cpfcnpj)::text AS count
           FROM subscriber_segments
          WHERE provider_id = $1
            AND LOWER(TRIM(contract_status)) IN ('ativo', 'online', 'liberado', 'normal')`,
        [providerId],
      ),
      pg.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM tickets WHERE provider_id = $1 AND status IN ('Aberto', 'Em Andamento')`, [providerId]),
      pg.query<{ count: string }>(`SELECT COUNT(*)::text AS count FROM notification_campaigns WHERE provider_id = $1 AND COALESCE(status, 'sent') = 'sent'`, [providerId]),
      pg.query<{ count: string }>(`SELECT COUNT(DISTINCT cpfcnpj)::text AS count FROM subscriber_devices WHERE provider_id = $1 AND fcm_token <> ''`, [providerId]),
      pg.query<{
        id: string;
        provider_id: string;
        provider_name: string;
        subject: string;
        status: string;
        created_by_email: string;
        updated_at: Date;
      }>(`SELECT id, provider_id, provider_name, subject, status, created_by_email, updated_at FROM tickets WHERE provider_id = $1 ORDER BY updated_at DESC LIMIT 5`, [providerId]),
    ]);

  const clientCount = Number(clientCountRes.rows[0]?.count || 0);
  const activeClientCount = Number(activeCountRes.rows[0]?.count || 0) || clientCount;

  return {
    stats: {
      clientCount,
      totalClients: clientCount,
      activeClientCount,
      openTicketsCount: Number(openTicketsRes.rows[0]?.count || 0),
      notificationCount: Number(notifCountRes.rows[0]?.count || 0),
      appUsersCount: Number(appUsersRes.rows[0]?.count || 0),
    },
    recentTickets: recentTicketsRes.rows.map((t) => ({
      id: t.id,
      providerId: t.provider_id,
      providerName: t.provider_name,
      subject: t.subject,
      status: t.status,
      userEmail: t.created_by_email,
      updatedAt: t.updated_at instanceof Date ? t.updated_at.toISOString() : t.updated_at,
    })),
  };
}
