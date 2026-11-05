import type { User } from 'firebase/auth';
import { resolvePublicApiBaseUrl } from '@/shared/config/publicApi';

let sample = { start: performance.now(), flow: 'restore', auth: 0, apiStart: 0, apiEnd: 0, sent: false };
export function startLoginTiming() { sample = { start: performance.now(), flow: 'login', auth: 0, apiStart: 0, apiEnd: 0, sent: false }; }
export function markPanelAuthReady() { if (!sample.auth) sample.auth = performance.now(); }
export function markDashboardRequest() { if (!sample.apiStart) sample.apiStart = performance.now(); }
export function markDashboardResponse() { if (!sample.apiEnd) sample.apiEnd = performance.now(); }

export function reportPanelReady(user: User) {
  if (sample.sent || !sample.auth || !sample.apiEnd) return;
  sample.sent = true;
  const data = { flow: sample.flow, totalMs: Math.round(performance.now() - sample.start),
    authMs: Math.round(sample.auth - sample.start), apiMs: Math.round(sample.apiEnd - sample.apiStart) };
  const base = resolvePublicApiBaseUrl(import.meta.env.VITE_API_URL, window.location);
  // First-party numeric timing only: no email, UID, URLs or subscriber data.
  // Reporting must never delay rendering or surface an error in the login flow.
  void user.getIdToken().then(token => fetch(`${base}/admin/performance`, {
    method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(data), keepalive: true,
  })).catch(() => undefined);
}
