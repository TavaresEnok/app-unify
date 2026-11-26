import { auth, type SessionUser } from '@/shared/auth/session';
import { resolvePublicApiBaseUrl } from '@/shared/config/publicApi';
import { markDashboardRequest, markDashboardResponse } from './panelTiming';
import { fallbackErrorMessage, notifySessionExpired, PanelHttpError } from './panelHttp';

const pending = new Map<string, { expires: number; value: Promise<Record<string, unknown>> }>();

export function clearDashboardPrefetch() { pending.clear(); }

export function fetchDashboard(user: Pick<SessionUser, 'uid' | 'getIdToken'>, providerId?: string): Promise<Record<string, unknown>> {
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

async function requestDashboard(user: Pick<SessionUser, 'uid' | 'getIdToken'>, providerId?: string): Promise<Record<string, unknown>> {
  markDashboardRequest();
  const base = resolvePublicApiBaseUrl(import.meta.env.VITE_API_URL, window.location);
  const path = providerId ? `/admin/dashboard/panel/providers/${encodeURIComponent(providerId)}` : '/admin/dashboard/panel';
  const token = await user.getIdToken();
  const response = await fetch(`${base}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
    cache: 'no-store',
    signal: AbortSignal.timeout(15000),
  });
  const body = await response.json().catch(() => ({})) as { data?: Record<string, unknown>; error?: { message?: string } };
  if (!response.ok) {
    if (response.status === 401) {
      // Resposta atrasada de uma sessão anterior não derruba a sessão nova.
      const current = auth.currentUser;
      if (current && current.uid === user.uid && await current.getIdToken().catch(() => null) === token) notifySessionExpired();
      throw new PanelHttpError('Sua sessão expirou. Entre novamente.', 401);
    }
    throw new PanelHttpError(body.error?.message || fallbackErrorMessage(response.status), response.status);
  }
  markDashboardResponse();
  return body.data as Record<string, unknown>;
}
