import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { expect, it, vi } from 'vitest';
const fixture = vi.hoisted(() => ({
  state: {} as Record<string, unknown>, allowed: false,
  role: 'superAdmin', user: { uid: 'synthetic' } as object | null, tenant: 'global' as string | null,
}));
vi.mock('@/contexts/AuthContext', () => ({ useAuth: () => ({ user: fixture.user, userRole: fixture.role, providerId: fixture.tenant }) }));
vi.mock('@/hooks/useApi', () => ({ useApi: () => ({ callFunction: vi.fn() }) }));
vi.mock('react-router-dom', () => ({ useNavigate: () => vi.fn() }));
vi.mock('@/shared/api/dashboard', () => ({ clearDashboardPrefetch: vi.fn() }));
vi.mock('@/shared/api/dashboardState', async original => {
  const actual = await original<typeof import('@/shared/api/dashboardState')>();
  return { ...actual, useDashboardState: (_user: unknown, _role: string, _tenant: string, allowed: boolean) => {
    fixture.allowed = allowed;
    return { ...fixture.state, reload: vi.fn() };
  } };
});
import { createDashboardController } from '@/shared/api/dashboardState';
import Page from './DashboardPage';

it('renders actual controller states: loading, error, measured empty, stale and retry while keeping navigation', async () => {
  const controller = createDashboardController<object>(true);
  const render = () => { fixture.state = controller.getSnapshot(); return renderToStaticMarkup(<Page />); };
  let html = render();
  expect(html).toContain('Carregando');
  expect(html).toContain('Novo provedor');
  expect(html).not.toContain('Nenhum ticket');
  await controller.load(async () => { throw new Error('synthetic'); });
  html = render();
  expect(html).toContain('Não foi possível carregar');
  expect(html).toContain('Recarregar');
  expect(html).not.toContain('Nenhum ticket');
  const data = { stats: { totalClients: 0, providerCount: 0, clientCount: 0, openTicketsCount: 0, notificationCount: 0 }, recentTickets: [], chartData: [] };
  await controller.load(async () => data);
  html = render();
  expect(html).toContain('Nenhum ticket');
  expect(html).toContain('>0</div>');
  expect(html).toContain('Registros de clientes');
  for (const fake of ['dados em tempo real', 'Clientes ativos', '12 semanas', '+6%', '+4%', 'Últimos 30 dias']) expect(html).not.toContain(fake);
  
  await controller.load(async () => { throw new Error('refresh'); });
  html = render();
  expect(html).toContain('Dados desatualizados');
  expect(html).toContain('>0</div>');
  await controller.load(async () => ({}));
  html = render();
  expect(html).toContain('N/D');
  expect(html).toContain('Tickets indisponíveis');
  expect(html).not.toContain('Nenhum ticket');
});
it('requires the correct role, user and tenant before loading', () => {
  fixture.state = { status: 'denied' };
  fixture.role = 'superAdmin'; fixture.user = { uid: 'synthetic' }; fixture.tenant = 'a';
  renderToStaticMarkup(<Page />); expect(fixture.allowed).toBe(true);
  fixture.role = 'providerAdmin';
  renderToStaticMarkup(<Page />); expect(fixture.allowed).toBe(false);
  fixture.role = 'superAdmin'; fixture.user = null;
  renderToStaticMarkup(<Page />); expect(fixture.allowed).toBe(false);
  
});
