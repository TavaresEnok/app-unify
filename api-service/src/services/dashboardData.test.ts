import { expect, it } from 'vitest';
import { loadGlobalDashboard, loadProviderDashboard } from './dashboardData';

it('does not fan out per-tenant counts for invisible chart rows at 100 providers', async () => {
  let tenantCounts = 0; const selected: string[][] = [];
  const db: any = { collection: (name: string) => {
    const query: any = {
      select: (...fields: string[]) => { selected.push(fields); return query; },
      where: (field: string) => { if (name === 'clientes' && field === 'providerId') tenantCounts++; return query; },
      orderBy: () => query, limit: () => query,
      count: () => ({ get: async () => ({ data: () => ({ count: name === 'clientes' ? 500000 : 0 }) }) }),
      get: async () => ({ size: name === 'provedores' ? 100 : 0, docs: name === 'provedores' ? Array.from({ length: 100 }, (_, i) => ({ id: `p${i}`, data: () => ({ name: `Provider ${i}` }) })) : [] }),
    }; return query;
  } };
  const result = await loadGlobalDashboard(db, null);
  expect(result.stats.providerCount).toBe(100); expect(result.stats.clientCount).toBe(500000);
  expect(result.chartData).toHaveLength(6); expect(tenantCounts).toBe(6); expect(selected).toEqual([['name']]);
});

it('reads client and campaign counters from PostgreSQL when pool is available', async () => {
  let firestoreClientQueries = 0;
  let firestoreNotifQueries = 0;
  const db: any = {
    collection: (name: string) => {
      if (name === 'clientes') firestoreClientQueries++;
      if (name === 'notifications') firestoreNotifQueries++;
      const query: any = {
        select: () => query,
        where: () => query,
        orderBy: () => query,
        limit: () => query,
        count: () => ({ get: async () => ({ data: () => ({ count: name === 'tickets' ? 2 : 0 }) }) }),
        get: async () => ({
          size: name === 'provedores' ? 2 : 0,
          docs: name === 'provedores'
            ? [
              { id: 'vibe', data: () => ({ name: 'Vibe Fibra' }) },
              { id: 'nova', data: () => ({ name: 'Nova Net' }) },
            ]
            : [],
        }),
      };
      return query;
    },
  };

  const pg: any = {
    query: async (sql: string) => {
      if (sql.includes('to_regclass')) {
        return { rows: [{ has_clients: true, has_segments: true, has_campaigns: true }] };
      }
      if (sql.includes('GROUP BY provider_id')) {
        return { rows: [{ provider_id: 'vibe', count: '492' }, { provider_id: 'nova', count: '120' }] };
      }
      if (sql.includes('FROM sgp_clients') && sql.includes('WHERE provider_id')) {
        return { rows: [{ count: '492' }] };
      }
      if (sql.includes('FROM sgp_clients')) {
        return { rows: [{ count: '612' }] };
      }
      if (sql.includes('FROM subscriber_segments')) {
        return { rows: [{ count: '460' }] };
      }
      if (sql.includes('FROM notification_campaigns')) {
        return { rows: [{ count: '7' }] };
      }
      return { rows: [] };
    },
  };

  const globalResult = await loadGlobalDashboard(db, pg);
  expect(globalResult.stats).toEqual({
    providerCount: 2,
    clientCount: 612,
    notificationCount: 7,
    openTicketsCount: 2,
  });
  expect(globalResult.chartData).toEqual([
    { name: 'Vibe Fibra', clientes: 492 },
    { name: 'Nova Net', clientes: 120 },
  ]);

  const providerResult = await loadProviderDashboard(db, 'vibe', pg);
  expect(providerResult.stats).toEqual({
    clientCount: 492,
    totalClients: 492,
    activeClientCount: 460,
    openTicketsCount: 2,
    notificationCount: 7,
  });
  expect(firestoreClientQueries).toBe(1); // reference created only, never queried
  expect(firestoreNotifQueries).toBe(0);
});
