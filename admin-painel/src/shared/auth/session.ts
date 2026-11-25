import { resolvePublicApiBaseUrl } from '@/shared/config/publicApi';

const TOKEN_STORAGE_KEY = 'unify_admin_token';

export interface SessionClaims {
  uid: string;
  email: string;
  role: 'superAdmin' | 'providerAdmin';
  superAdmin: boolean;
  providerId?: string;
  auth_time: number;
  iat: number;
  exp: number;
}

export interface SessionUser {
  uid: string;
  email: string;
  role: 'superAdmin' | 'providerAdmin';
  superAdmin: boolean;
  providerId: string | null;
  authTime: number;
  getIdToken: (forceRefresh?: boolean) => Promise<string>;
  getIdTokenResult: (forceRefresh?: boolean) => Promise<{
    token: string;
    claims: SessionClaims;
  }>;
}

type AuthListener = (user: SessionUser | null) => void;

const listeners = new Set<AuthListener>();
let currentToken: string | null = null;
let currentUser: SessionUser | null = null;
let initialized = false;
let restorePromise: Promise<SessionUser | null> | null = null;

function apiBase(): string {
  const loc = typeof window !== 'undefined' ? window.location : undefined;
  return resolvePublicApiBaseUrl(import.meta.env.VITE_API_URL, loc);
}

function readStoredToken(): string | null {
  try {
    if (typeof localStorage === 'undefined') return null;
    const raw = localStorage.getItem(TOKEN_STORAGE_KEY);
    return raw && raw.trim() ? raw.trim() : null;
  } catch {
    return null;
  }
}

function writeStoredToken(token: string | null): void {
  try {
    if (typeof localStorage === 'undefined') return;
    if (token) localStorage.setItem(TOKEN_STORAGE_KEY, token);
    else localStorage.removeItem(TOKEN_STORAGE_KEY);
  } catch {
    // Ignore storage errors in restricted contexts
  }
}

function decodeJwtPayload(token: string): SessionClaims | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4);
    const json = atob(padded);
    const parsed = JSON.parse(json) as Partial<SessionClaims>;
    if (!parsed || typeof parsed.uid !== 'string' || typeof parsed.exp !== 'number') {
      return null;
    }
    const nowSec = Math.floor(Date.now() / 1000);
    if (parsed.exp <= nowSec) return null;
    const role = parsed.role === 'superAdmin' || parsed.superAdmin === true ? 'superAdmin' : 'providerAdmin';
    return {
      uid: parsed.uid,
      email: typeof parsed.email === 'string' ? parsed.email : '',
      role,
      superAdmin: role === 'superAdmin',
      providerId: typeof parsed.providerId === 'string' ? parsed.providerId : undefined,
      auth_time: typeof parsed.auth_time === 'number' ? parsed.auth_time : nowSec,
      iat: typeof parsed.iat === 'number' ? parsed.iat : nowSec,
      exp: parsed.exp,
    };
  } catch {
    return null;
  }
}

function buildUserFromToken(
  token: string,
  override?: Partial<{ uid: string; email: string; role: 'superAdmin' | 'providerAdmin'; superAdmin: boolean; providerId: string | null; authTime: number }>,
): SessionUser | null {
  const claims = decodeJwtPayload(token);
  if (!claims) return null;
  const mergedClaims: SessionClaims = {
    ...claims,
    uid: override?.uid ?? claims.uid,
    email: override?.email ?? claims.email,
    role: override?.role ?? claims.role,
    superAdmin: override?.superAdmin ?? claims.superAdmin,
    providerId: override?.providerId !== undefined ? (override.providerId || undefined) : claims.providerId,
    auth_time: override?.authTime ?? claims.auth_time,
  };

  return {
    uid: mergedClaims.uid,
    email: mergedClaims.email,
    role: mergedClaims.role,
    superAdmin: mergedClaims.superAdmin,
    providerId: mergedClaims.providerId || null,
    authTime: mergedClaims.auth_time,
    getIdToken: async (forceRefresh?: boolean) => {
      if (forceRefresh) {
        await refreshCurrentUser();
      }
      if (!currentToken) throw new Error('Sessão expirada.');
      return currentToken;
    },
    getIdTokenResult: async (forceRefresh?: boolean) => {
      if (forceRefresh) {
        await refreshCurrentUser();
      }
      const liveToken = currentToken || token;
      const liveClaims = decodeJwtPayload(liveToken) || mergedClaims;
      return { token: liveToken, claims: liveClaims };
    },
  };
}

function emitSession(user: SessionUser | null): void {
  for (const listener of Array.from(listeners)) {
    try {
      listener(user);
    } catch {
      // Listener errors should not break auth updates
    }
  }
}

function setSession(token: string | null, userOverride?: Parameters<typeof buildUserFromToken>[1]): SessionUser | null {
  if (!token) {
    currentToken = null;
    currentUser = null;
    initialized = true;
    writeStoredToken(null);
    emitSession(null);
    return null;
  }
  const user = buildUserFromToken(token, userOverride);
  if (!user) {
    currentToken = null;
    currentUser = null;
    initialized = true;
    writeStoredToken(null);
    emitSession(null);
    return null;
  }
  currentToken = token;
  currentUser = user;
  initialized = true;
  writeStoredToken(token);
  emitSession(user);
  return user;
}

export async function refreshCurrentUser(): Promise<SessionUser | null> {
  const token = currentToken ?? readStoredToken();
  if (!token) {
    return setSession(null);
  }
  const decoded = decodeJwtPayload(token);
  if (!decoded) {
    return setSession(null);
  }
  try {
    const response = await fetch(`${apiBase()}/admin/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
      cache: 'no-store',
    });
    if (response.status === 401 || response.status === 403) {
      return setSession(null);
    }
    if (!response.ok) {
      return setSession(token);
    }
    const payload = await response.json().catch(() => ({})) as {
      user?: { uid?: string; email?: string; role?: 'superAdmin' | 'providerAdmin'; superAdmin?: boolean; providerId?: string | null; authTime?: number };
    };
    return setSession(token, payload.user);
  } catch {
    return setSession(token);
  }
}

export function restoreSession(): Promise<SessionUser | null> {
  if (!restorePromise) {
    restorePromise = refreshCurrentUser().finally(() => {
      restorePromise = null;
    });
  }
  return restorePromise;
}

export function getCurrentUser(): SessionUser | null {
  if (!initialized) {
    const stored = readStoredToken();
    if (stored) {
      const built = buildUserFromToken(stored);
      if (built) {
        currentToken = stored;
        currentUser = built;
      }
    }
  }
  return currentUser;
}

export async function getAccessToken(forceRefresh = false): Promise<string> {
  if (forceRefresh) {
    await refreshCurrentUser();
  }
  const user = getCurrentUser();
  if (!user || !currentToken) {
    throw new Error('Sessão não autenticada.');
  }
  return currentToken;
}

export function subscribeAuth(listener: AuthListener): () => void {
  listeners.add(listener);
  if (initialized) {
    listener(currentUser);
  } else {
    void restoreSession();
  }
  return () => {
    listeners.delete(listener);
  };
}

function authError(code: string, message: string): Error & { code: string } {
  return Object.assign(new Error(message), { code });
}

export async function loginWithEmailPassword(email: string, password: string): Promise<SessionUser> {
  let response: Response;
  try {
    response = await fetch(`${apiBase()}/admin/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
      cache: 'no-store',
    });
  } catch {
    throw authError('auth/network-request-failed', 'Não foi possível conectar ao servidor de autenticação.');
  }

  const body = await response.json().catch(() => ({})) as {
    token?: string;
    user?: { uid?: string; email?: string; role?: 'superAdmin' | 'providerAdmin'; superAdmin?: boolean; providerId?: string | null; authTime?: number };
    error?: { code?: string; message?: string };
  };

  if (!response.ok || !body.token) {
    if (response.status === 429) {
      throw authError('auth/too-many-requests', body.error?.message || 'Muitas tentativas. Aguarde alguns minutos.');
    }
    if (response.status === 403) {
      throw authError('auth/user-disabled', body.error?.message || 'Conta desativada.');
    }
    if (response.status === 401 || response.status === 400) {
      throw authError('auth/invalid-credential', body.error?.message || 'Credenciais inválidas.');
    }
    throw authError(body.error?.code || 'auth/internal-error', body.error?.message || 'Falha ao autenticar.');
  }

  const user = setSession(body.token, body.user);
  if (!user) {
    throw authError('auth/invalid-credential', 'Token inválido recebido do servidor.');
  }
  return user;
}

export async function reauthenticateWithPassword(password: string): Promise<SessionUser> {
  const token = currentToken ?? readStoredToken();
  if (!token) {
    throw authError('auth/unauthenticated', 'Sessão expirada.');
  }
  const response = await fetch(`${apiBase()}/admin/auth/reauthenticate`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ password }),
    cache: 'no-store',
  });
  const body = await response.json().catch(() => ({})) as {
    token?: string;
    user?: { uid?: string; email?: string; role?: 'superAdmin' | 'providerAdmin'; superAdmin?: boolean; providerId?: string | null; authTime?: number };
    error?: { code?: string; message?: string };
  };
  if (!response.ok || !body.token) {
    if (response.status === 403 || response.status === 401) {
      throw authError('auth/invalid-credential', body.error?.message || 'Senha atual incorreta.');
    }
    throw authError(body.error?.code || 'auth/internal-error', body.error?.message || 'Falha ao confirmar sessão.');
  }
  const user = setSession(body.token, body.user);
  if (!user) {
    throw authError('auth/internal-error', 'Token inválido ao confirmar sessão.');
  }
  return user;
}

export async function logoutSession(): Promise<void> {
  const token = currentToken ?? readStoredToken();
  if (token) {
    await fetch(`${apiBase()}/admin/auth/logout`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: '{}',
      cache: 'no-store',
    }).catch(() => undefined);
  }
  setSession(null);
}

export const auth = {
  get currentUser(): SessionUser | null {
    return getCurrentUser();
  },
};
