import type { User } from 'firebase/auth';
import { resolvePublicApiBaseUrl } from '@/shared/config/publicApi';
import { markDashboardRequest, markDashboardResponse } from './panelTiming';

const pending = new Map<string, { expires: number; value: Promise<Record<string, unknown>> }>();

export function clearDashboardPrefetch() { pending.clear(); }

export function fetchDashboard(user: User, providerId?: string): Promise<Record<string, unknown>> {
  const key = `${user.uid}:${providerId || 'global'}`;
  const current = pending.get(key);
  if (current && current.expires > Date.now()) return current.value;
  if (pending.size >= 16) pending.delete(pending.keys().next().value!);
  const value = requestDashboard(user, providerId);
  const entry = { expires: Date.now() + 15000, value };
  pending.set(key, entry);
  void value.then(() => { entry.expires = Date.now() + 2000; }, () => {
    if (pending.get(key) === entry) pending.delete(key);
  });
  return value;
}

async function requestDashboard(user: User, providerId?: string): Promise<Record<string, unknown>> {
  markDashboardRequest();
  const base = resolvePublicApiBaseUrl(import.meta.env.VITE_API_URL, window.location);
  const path = providerId ? `/admin/dashboard/panel/providers/${encodeURIComponent(providerId)}` : '/admin/dashboard/panel';
  const response = await fetch(`${base}${path}`, {
    headers: { Authorization: `Bearer ${await user.getIdToken()}` },
    cache: 'no-store',
    signal: AbortSignal.timeout(15000),
  });
  const body = await response.json();
  if (!response.ok) throw new Error(body.error?.message || 'Falha ao carregar o dashboard.');
  markDashboardResponse();
  return body.data;
}
