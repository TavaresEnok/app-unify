'use strict';

// Autenticação, hash de senha, JWT HS256 e criptografia AES-256-GCM 100% locais.
// Fonte única de verdade sincronizada para `proxy-sgp/lib/` e `api-service/src/services/`.
const crypto = require('node:crypto');
const fs = require('node:fs');

const TEST_KEYS = {
  JWT_SECRET: 'test-only-jwt-secret-key-not-for-production-use-32b',
  APP_SECRETS_KEY: 'test-only-app-secrets-key-not-for-production-32b',
};

const keyCache = new Map();

function loadKey(envName, fileEnvName, fallbackPath) {
  const inline = typeof process.env[envName] === 'string' ? process.env[envName].trim() : '';
  if (inline) return inline;

  const filePath = (typeof process.env[fileEnvName] === 'string' ? process.env[fileEnvName].trim() : '') || fallbackPath;
  if (filePath) {
    const cached = keyCache.get(filePath);
    if (cached) return cached;
    try {
      if (fs.existsSync(filePath)) {
        const value = fs.readFileSync(filePath, 'utf8').trim();
        if (value) {
          keyCache.set(filePath, value);
          return value;
        }
      }
    } catch {
      // Fall through to fail-closed check below.
    }
  }

  if (process.env.NODE_ENV === 'test' && TEST_KEYS[envName]) {
    return TEST_KEYS[envName];
  }

  throw Object.assign(new Error(`Chave criptográfica ${envName} não configurada.`), {
    status: 503,
    code: 'service-unavailable',
  });
}

function getJwtSecret() {
  return loadKey('JWT_SECRET', 'JWT_SECRET_FILE', '/run/secrets/jwt-secret.key');
}

function getAppSecretsKeyBytes() {
  const raw = loadKey('APP_SECRETS_KEY', 'APP_SECRETS_KEY_FILE', '/run/secrets/app-secrets.key');
  return crypto.createHash('sha256').update(raw, 'utf8').digest();
}

function encryptSecret(obj) {
  const key = getAppSecretsKeyBytes();
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const plaintext = Buffer.from(JSON.stringify(obj ?? {}), 'utf8');
  const encrypted = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  const tag = cipher.getAuthTag();
  return `v1:${iv.toString('base64')}:${tag.toString('base64')}:${encrypted.toString('base64')}`;
}

function decryptSecret(ciphertext) {
  if (typeof ciphertext !== 'string' || !ciphertext.startsWith('v1:')) {
    throw Object.assign(new Error('Segredo armazenado em formato inválido.'), { status: 500 });
  }
  const parts = ciphertext.split(':');
  if (parts.length !== 4) {
    throw Object.assign(new Error('Segredo armazenado corrompido.'), { status: 500 });
  }
  const key = getAppSecretsKeyBytes();
  const iv = Buffer.from(parts[1], 'base64');
  const tag = Buffer.from(parts[2], 'base64');
  const data = Buffer.from(parts[3], 'base64');
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(tag);
  const plain = Buffer.concat([decipher.update(data), decipher.final()]).toString('utf8');
  return JSON.parse(plain);
}

function hashPassword(password) {
  if (typeof password !== 'string' || password.length < 6) {
    throw Object.assign(new Error('A senha deve ter pelo menos 6 caracteres.'), { status: 400 });
  }
  const salt = crypto.randomBytes(16).toString('hex');
  const derived = crypto.scryptSync(password, salt, 64, { N: 16384, r: 8, p: 1 });
  return `scrypt$16384$8$1$${salt}$${derived.toString('hex')}`;
}

function verifyPassword(password, stored) {
  if (typeof password !== 'string' || typeof stored !== 'string') return false;
  const parts = stored.split('$');
  if (parts.length !== 6 || parts[0] !== 'scrypt') return false;
  const N = Number(parts[1]);
  const r = Number(parts[2]);
  const p = Number(parts[3]);
  const salt = parts[4];
  const expectedHex = parts[5];
  if (!Number.isFinite(N) || !Number.isFinite(r) || !Number.isFinite(p) || !salt || !expectedHex) {
    return false;
  }
  try {
    const expected = Buffer.from(expectedHex, 'hex');
    const derived = crypto.scryptSync(password, salt, expected.length, { N, r, p });
    return derived.length === expected.length && crypto.timingSafeEqual(derived, expected);
  } catch {
    return false;
  }
}

function b64urlEncode(input) {
  const buf = Buffer.isBuffer(input) ? input : Buffer.from(String(input), 'utf8');
  return buf.toString('base64url');
}

function b64urlDecodeJson(segment) {
  const raw = Buffer.from(String(segment || ''), 'base64url').toString('utf8');
  return JSON.parse(raw);
}

function authError(code, message = 'Sessão inválida.') {
  return Object.assign(new Error(message), { code });
}

function signJwt(claims, { ttlSeconds = 12 * 3600 } = {}) {
  const nowSec = Math.floor(Date.now() / 1000);
  const uid = String(claims?.uid || claims?.sub || '');
  if (!uid) throw new Error('uid obrigatório para assinar token.');
  const payload = {
    iss: 'painel-provedores',
    sub: uid,
    uid,
    role: claims.role || '',
    superAdmin: claims.superAdmin === true,
    providerId: claims.providerId || undefined,
    cpfCnpj: claims.cpfCnpj || undefined,
    email: claims.email || undefined,
    tv: Number.isInteger(claims.tv) ? claims.tv : 1,
    auth_time: Number.isInteger(claims.auth_time) ? claims.auth_time : nowSec,
    iat: nowSec,
    exp: nowSec + ttlSeconds,
  };
  const headerSeg = b64urlEncode(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const payloadSeg = b64urlEncode(JSON.stringify(payload));
  const signingInput = `${headerSeg}.${payloadSeg}`;
  const sig = crypto.createHmac('sha256', getJwtSecret()).update(signingInput).digest();
  return `${signingInput}.${b64urlEncode(sig)}`;
}

function verifyJwt(token) {
  if (typeof token !== 'string' || !token.trim()) {
    throw authError('auth/invalid-id-token');
  }
  const parts = token.trim().split('.');
  if (parts.length !== 3) {
    throw authError('auth/invalid-id-token');
  }
  let header;
  let payload;
  try {
    header = b64urlDecodeJson(parts[0]);
    payload = b64urlDecodeJson(parts[1]);
  } catch {
    throw authError('auth/invalid-id-token');
  }
  if (!header || header.alg !== 'HS256') {
    throw authError('auth/invalid-id-token');
  }
  const signingInput = `${parts[0]}.${parts[1]}`;
  const expectedSig = crypto.createHmac('sha256', getJwtSecret()).update(signingInput).digest();
  let suppliedSig;
  try {
    suppliedSig = Buffer.from(parts[2], 'base64url');
  } catch {
    throw authError('auth/invalid-id-token');
  }
  if (suppliedSig.length !== expectedSig.length || !crypto.timingSafeEqual(suppliedSig, expectedSig)) {
    throw authError('auth/invalid-id-token');
  }
  if (!payload || payload.iss !== 'painel-provedores' || typeof payload.uid !== 'string' || !payload.uid) {
    throw authError('auth/invalid-id-token');
  }
  const nowSec = Math.floor(Date.now() / 1000);
  if (typeof payload.exp !== 'number' || payload.exp <= nowSec) {
    throw authError('auth/id-token-expired', 'Sessão expirada.');
  }
  if (typeof payload.iat !== 'number' || payload.iat > nowSec + 60) {
    throw authError('auth/invalid-id-token');
  }
  return payload;
}

async function verifyLiveSession(pool, token) {
  const payload = verifyJwt(token);
  if (!pool) {
    throw authError('authorization-unavailable', 'Banco de sessões indisponível.');
  }

  const role = String(payload.role || '');
  const tokenVersion = Number.isInteger(payload.tv) ? payload.tv : 1;

  if (role === 'superAdmin' || role === 'providerAdmin') {
    const res = await pool.query(
      `SELECT uid, email, role, provider_id, disabled, token_version
         FROM admin_users
        WHERE uid = $1
        LIMIT 1`,
      [payload.uid],
    );
    const row = res.rows[0];
    if (!row) throw authError('auth/user-not-found');
    if (row.disabled) throw authError('auth/user-disabled');
    if (Number(row.token_version || 1) !== tokenVersion) throw authError('auth/id-token-revoked');

    const isSuper = row.role === 'superAdmin';
    const providerId = row.provider_id || undefined;
    if ((payload.superAdmin === true) !== isSuper || payload.role !== row.role || (payload.providerId || '') !== (providerId || '')) {
      throw authError('access/scope-changed');
    }
    return {
      uid: row.uid,
      sub: row.uid,
      email: row.email || '',
      role: row.role,
      superAdmin: isSuper,
      providerId,
      auth_time: payload.auth_time,
      iat: payload.iat,
      exp: payload.exp,
    };
  }

  if (role === 'subscriber') {
    const res = await pool.query(
      `SELECT uid, provider_id, cpfcnpj, email, disabled, token_version
         FROM subscribers
        WHERE uid = $1
        LIMIT 1`,
      [payload.uid],
    );
    const row = res.rows[0];
    if (!row) throw authError('auth/user-not-found');
    if (row.disabled) throw authError('auth/user-disabled');
    if (Number(row.token_version || 1) !== tokenVersion) throw authError('auth/id-token-revoked');
    if ((payload.providerId || '') !== (row.provider_id || '') || (payload.cpfCnpj || '') !== (row.cpfcnpj || '')) {
      throw authError('access/scope-changed');
    }
    return {
      uid: row.uid,
      sub: row.uid,
      role: 'subscriber',
      superAdmin: false,
      providerId: row.provider_id,
      cpfCnpj: row.cpfcnpj,
      email: row.email || '',
      auth_time: payload.auth_time,
      iat: payload.iat,
      exp: payload.exp,
    };
  }

  throw authError('auth/invalid-id-token');
}

function clearKeyCacheForTests() {
  keyCache.clear();
}

module.exports = {
  loadKey,
  encryptSecret,
  decryptSecret,
  hashPassword,
  verifyPassword,
  signJwt,
  verifyJwt,
  verifyLiveSession,
  clearKeyCacheForTests,
};
