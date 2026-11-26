'use strict';

// Período de transição Firebase Auth → JWT próprio.
// Fonte única sincronizada para `proxy-sgp/lib/` e `api-service/src/services/`.
//
// Apps publicados antes da migração fazem login com `signInWithCustomToken`
// e enviam o ID token do Firebase em `Authorization: Bearer`. Até a data em
// LEGACY_FIREBASE_AUTH_UNTIL (AAAA-MM-DD, exclusiva) o servidor:
//   - devolve um custom token real do Firebase em `customToken` no /check-cpf
//     (o app novo lê `accessToken`, que continua sendo o JWT próprio);
//   - aceita ID tokens do Firebase, apenas de ASSINANTES, com revogação checada.
// Sem a variável, ou depois da data, tudo isso fica desligado (fail-closed).

//   - só vale para os provedores em LEGACY_FIREBASE_AUTH_PROVIDERS (lista
//     separada por vírgula; padrão "vibe", o único com app da era Firebase).
//     Assim o CPF de assinantes dos outros provedores não é copiado ao Google.

const { createHash } = require('node:crypto');

function authError(code) {
  return Object.assign(new Error(code), { code });
}

function legacyProviderAllowed(providerId, raw = process.env.LEGACY_FIREBASE_AUTH_PROVIDERS) {
  if (typeof providerId !== 'string' || !providerId) return false;
  const list = (typeof raw === 'string' ? raw : 'vibe').split(',').map((item) => item.trim()).filter(Boolean);
  return list.includes('*') || list.includes(providerId);
}

// verifyIdToken sem checagem de revogação: assinatura e validade são locais
// (chaves públicas em cache no firebase-admin). Revogação e desativação são
// decididas no PostgreSQL logo abaixo. O resultado decodificado fica em cache
// curto para não repetir a verificação a cada requisição do app antigo.
const DECODED_CACHE_MAX = 2000;
let decodedCaches = new WeakMap();
async function decodeLegacyToken(auth, token, nowMs) {
  let decodedCache = decodedCaches.get(auth);
  if (!decodedCache) { decodedCache = new Map(); decodedCaches.set(auth, decodedCache); }
  const key = createHash('sha256').update(token).digest('hex');
  const hit = decodedCache.get(key);
  if (hit && hit.expiresAt > nowMs) return hit.decoded;
  if (hit) decodedCache.delete(key);
  const decoded = await auth.verifyIdToken(token, false);
  const expMs = Number(decoded?.exp) * 1000;
  const expiresAt = Math.min(Number.isFinite(expMs) ? expMs : nowMs, nowMs + 5 * 60 * 1000);
  if (expiresAt > nowMs) {
    if (decodedCache.size >= DECODED_CACHE_MAX) decodedCache.delete(decodedCache.keys().next().value);
    decodedCache.set(key, { decoded, expiresAt });
  }
  return decoded;
}

function legacyFirebaseAuthEnabled(now = new Date(), until = process.env.LEGACY_FIREBASE_AUTH_UNTIL) {
  const raw = typeof until === 'string' ? until.trim() : '';
  if (!/^\d{4}-\d{2}-\d{2}$/.test(raw)) return false;
  const limit = Date.parse(`${raw}T00:00:00-03:00`);
  return Number.isFinite(limit) && now.getTime() < limit;
}

// ID tokens do Firebase são RS256 com `kid`; o JWT próprio é HS256.
function looksLikeFirebaseIdToken(token) {
  if (typeof token !== 'string') return false;
  const parts = token.trim().split('.');
  if (parts.length !== 3) return false;
  try {
    const header = JSON.parse(Buffer.from(parts[0], 'base64url').toString('utf8'));
    return header?.alg === 'RS256' && typeof header.kid === 'string' && header.kid.length > 0;
  } catch {
    return false;
  }
}

let cachedAuth;
function defaultFirebaseAuth() {
  if (cachedAuth !== undefined) return cachedAuth;
  cachedAuth = null;
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS && !process.env.GOOGLE_CLOUD_PROJECT) return cachedAuth;
  try {
    const admin = require('firebase-admin');
    if (!admin.apps.length) admin.initializeApp({ projectId: process.env.GOOGLE_CLOUD_PROJECT || undefined });
    cachedAuth = admin.auth();
  } catch (error) {
    console.warn('[legacy-auth] Firebase Auth indisponível:', error && error.message);
  }
  return cachedAuth;
}

function legacyAuthAvailable(options = {}) {
  if (!legacyFirebaseAuthEnabled(options.now)) return null;
  return options.auth || defaultFirebaseAuth();
}

async function verifyLegacyFirebaseSession(pool, token, options = {}) {
  const auth = legacyAuthAvailable(options);
  if (!auth || !looksLikeFirebaseIdToken(token)) throw authError('auth/invalid-id-token');

  const nowMs = (options.now instanceof Date ? options.now : new Date()).getTime();
  const decoded = await decodeLegacyToken(auth, token, nowMs);
  const providerId = typeof decoded.providerId === 'string' ? decoded.providerId : '';
  const cpfCnpj = typeof decoded.cpfCnpj === 'string' ? decoded.cpfCnpj.replace(/\D/g, '') : '';
  // Somente assinantes: o painel web já usa o login novo.
  if (decoded.role !== 'subscriber' || decoded.superAdmin === true || !providerId || !cpfCnpj ||
      !legacyProviderAllowed(providerId, options.providers)) {
    throw authError('auth/invalid-id-token');
  }

  if (!pool) throw authError('authorization-unavailable');
  const admin = await pool.query('SELECT 1 FROM admin_users WHERE uid = $1 LIMIT 1', [decoded.uid]);
  if (admin.rows.length) throw authError('access/identity-conflict');
  const res = await pool.query(
    `SELECT disabled, provider_id, cpfcnpj FROM subscribers
      WHERE uid = $1 OR (provider_id = $2 AND cpfcnpj = $3)`,
    [decoded.uid, providerId, cpfCnpj],
  );
  for (const row of res.rows) {
    if (row.disabled) throw authError('auth/user-disabled');
    if (row.provider_id !== providerId || row.cpfcnpj !== cpfCnpj) throw authError('access/scope-changed');
  }

  return {
    uid: decoded.uid,
    sub: decoded.uid,
    role: 'subscriber',
    superAdmin: false,
    providerId,
    cpfCnpj,
    email: decoded.email || '',
    auth_time: decoded.auth_time,
    iat: decoded.iat,
    exp: decoded.exp,
    legacyFirebase: true,
  };
}

// Tenta o JWT próprio; se falhar e o token for do Firebase dentro da janela de
// transição, valida pelo caminho legado. Qualquer outro erro é repassado.
async function verifySessionWithLegacy(pool, token, verifyLiveSession, options = {}) {
  try {
    return await verifyLiveSession(pool, token);
  } catch (error) {
    if (error?.code !== 'auth/invalid-id-token' || !looksLikeFirebaseIdToken(token) || !legacyAuthAvailable(options)) throw error;
    return verifyLegacyFirebaseSession(pool, token, options);
  }
}

// Custom token para apps antigos. Nunca derruba o login novo: em qualquer falha
// devolve null e o /check-cpf mantém o JWT próprio em `customToken`.
// createCustomToken assina localmente com a conta de serviço (sem rede); os
// claims vão dentro do token. A gravação dos claims no usuário do Firebase
// (persistSubscriber, várias idas ao Google) roda em segundo plano e não
// atrasa nem derruba o login.
async function issueLegacyCustomToken(identity, options = {}) {
  const auth = legacyAuthAvailable(options);
  if (!auth || !identity || !legacyProviderAllowed(identity.claims && identity.claims.providerId, options.providers)) return null;
  const warn = (error) => console.warn('[legacy-auth] custom token não emitido:', error && error.code ? error.code : 'erro');
  if (typeof auth.createCustomToken !== 'function') {
    if (typeof options.persistSubscriber !== 'function') return null;
    try { return await options.persistSubscriber(auth, identity); } catch (error) { warn(error); return null; }
  }
  if (typeof options.persistSubscriber === 'function') {
    Promise.resolve().then(() => options.persistSubscriber(auth, identity)).catch((error) => {
      console.warn('[legacy-auth] claims do usuário não gravados:', error && error.code ? error.code : 'erro');
    });
  }
  let timer;
  try {
    return await Promise.race([
      Promise.resolve().then(() => auth.createCustomToken(identity.uid, identity.claims)),
      new Promise((_, reject) => { timer = setTimeout(() => reject(Object.assign(new Error('timeout'), { code: 'legacy/timeout' })), options.timeoutMs || 3000); }),
    ]);
  } catch (error) {
    warn(error);
    return null;
  } finally {
    clearTimeout(timer);
  }
}

function resetLegacyAuthForTests() {
  cachedAuth = undefined;
  decodedCaches = new WeakMap();
}

module.exports = {
  legacyFirebaseAuthEnabled,
  legacyProviderAllowed,
  looksLikeFirebaseIdToken,
  verifyLegacyFirebaseSession,
  verifySessionWithLegacy,
  issueLegacyCustomToken,
  resetLegacyAuthForTests,
};
