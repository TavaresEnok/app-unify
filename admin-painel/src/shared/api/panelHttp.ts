import { auth } from '@/firebase/auth';
import { resolvePublicApiBaseUrl } from '@/shared/config/publicApi';

export class PanelHttpError extends Error {
  constructor(message: string, readonly status: number) { super(message); }
}
const reads = new Map<string, { user: unknown; expires: number; value: Promise<unknown> }>();
export function clearPanelReads() { reads.clear(); }
let sessionVersion = 0;
export function resetPanelSession() { sessionVersion++; clearPanelReads(); }

/** HTTP commands are never retried automatically. A timeout may follow a committed write. */
export async function panelRequest<T>(path: string, options: { method?: string; body?: unknown; signal?: AbortSignal } = {}): Promise<T> {
  const user = auth.currentUser;
  const version = sessionVersion;
  if (!user) throw new PanelHttpError('Sessão necessária.', 401);
  const base = resolvePublicApiBaseUrl(import.meta.env.VITE_API_URL, window.location);
  const token = await user.getIdToken();
  if (auth.currentUser !== user || version !== sessionVersion) throw new PanelHttpError('Sessão alterada.', 401);
  const response = await fetch(`${base}${path}`, {
    method: options.method || 'GET', cache: 'no-store',
    headers: { Authorization: `Bearer ${token}`, ...(options.body === undefined ? {} : { 'Content-Type': 'application/json' }) },
    ...(options.body === undefined ? {} : { body: JSON.stringify(options.body) }),
    signal: options.signal || AbortSignal.timeout(15_000),
  });
  const body = await response.json();
  if (auth.currentUser !== user || version !== sessionVersion) throw new PanelHttpError('Sessão alterada.', 401);
  if (!response.ok) throw new PanelHttpError(body.error?.message || 'Não foi possível concluir a operação.', response.status);
  return body;
}

/** Short, identity-scoped cache with in-flight coalescing. Cleared on session changes/writes. */
export function readPanel<T>(path: string, force = false): Promise<T> {
  const user = auth.currentUser;
  const cached = reads.get(path);
  if (user && cached?.user === user && (!force || cached.expires === Infinity) && cached.expires > Date.now()) return cached.value as Promise<T>;
  if (reads.size >= 64) reads.delete(reads.keys().next().value!);
  const value = panelRequest<T>(path);
  const entry = { user, expires: Infinity, value };
  reads.set(path, entry);
  void value.then(() => { entry.expires = Date.now() + 15_000; }, () => { if (reads.get(path) === entry) reads.delete(path); });
  return value;
}
