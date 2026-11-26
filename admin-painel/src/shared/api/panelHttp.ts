import { auth } from '@/shared/auth/session';
import { resolvePublicApiBaseUrl } from '@/shared/config/publicApi';

export class PanelHttpError extends Error {
  constructor(message: string, readonly status: number, readonly code?: string) { super(message); }
}

/** Ação sensível exige login recente: o servidor responde 401 com este código (não é sessão expirada). */
export const REAUTH_REQUIRED_CODE = 'reauth-required';
export function isReauthRequired(error: unknown): boolean {
  return error instanceof PanelHttpError && error.code === REAUTH_REQUIRED_CODE;
}
const reads = new Map<string, { user: unknown; expires: number; value: Promise<unknown> }>();
export function clearPanelReads() { reads.clear(); }
let sessionVersion = 0;
export function resetPanelSession() { sessionVersion++; clearPanelReads(); }

/** Evento global disparado quando o servidor recusa o token (expirado/revogado). */
export const SESSION_EXPIRED_EVENT = 'unify:session-expired';

/** Mensagem legível para respostas sem `error.message` (502 HTML do proxy, 413, 429...). */
export function fallbackErrorMessage(status: number): string {
  if (status === 401) return 'Sua sessão expirou. Entre novamente.';
  if (status === 413) return 'Arquivo ou conteúdo grande demais.';
  if (status === 429) return 'Muitas requisições. Aguarde um instante.';
  if (status === 502 || status === 503 || status === 504) return 'Servidor indisponível no momento. Tente novamente em instantes.';
  return 'Não foi possível concluir a operação.';
}

export function notifySessionExpired() {
  if (typeof window === 'undefined' || typeof window.dispatchEvent !== 'function') return;
  try { window.dispatchEvent(new CustomEvent(SESSION_EXPIRED_EVENT)); } catch { /* ambiente sem CustomEvent */ }
}

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
  const body = await response.json().catch(() => ({})) as { error?: { message?: unknown; code?: unknown } } & Record<string, unknown>;
  if (auth.currentUser !== user || version !== sessionVersion) throw new PanelHttpError('Sessão alterada.', 401);
  if (!response.ok) {
    const code = typeof body.error?.code === 'string' ? body.error.code : undefined;
    if (response.status === 401 && code === REAUTH_REQUIRED_CODE) {
      throw new PanelHttpError(typeof body.error?.message === 'string' ? body.error.message : 'Confirme sua senha para continuar.', 401, code);
    }
    // 401 do servidor = token expirado ou revogado (logout em outro aparelho, troca de senha).
    if (response.status === 401) {
      notifySessionExpired();
      throw new PanelHttpError('Sua sessão expirou. Entre novamente.', 401);
    }
    const message = typeof body.error?.message === 'string' && body.error.message ? body.error.message : fallbackErrorMessage(response.status);
    throw new PanelHttpError(message, response.status, code);
  }
  return body as T;
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
