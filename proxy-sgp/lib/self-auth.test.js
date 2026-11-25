'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  encryptSecret,
  decryptSecret,
  hashPassword,
  verifyPassword,
  signJwt,
  verifyJwt,
  verifyLiveSession,
  clearKeyCacheForTests,
} = require('./self-auth');

test('AES-256-GCM cifra e decifra segredos e rejeita adulteração', () => {
  process.env.NODE_ENV = 'test';
  clearKeyCacheForTests();
  const payload = { erp: 'ixc', apiToken: 'tok-123', sgpBaseUrl: 'https://erp.test' };
  const enc = encryptSecret(payload);
  assert.ok(enc.startsWith('v1:'));
  assert.ok(!enc.includes('tok-123'));
  assert.deepEqual(decryptSecret(enc), payload);

  const tampered = enc.slice(0, -2) + (enc.endsWith('AA') ? 'BB' : 'AA');
  assert.throws(() => decryptSecret(tampered));
  assert.throws(() => decryptSecret('invalid-format'));
});

test('scrypt gera hash com salt e valida senhas corretamente', () => {
  const h1 = hashPassword('SenhaForte!2026');
  const h2 = hashPassword('SenhaForte!2026');
  assert.notEqual(h1, h2);
  assert.ok(h1.startsWith('scrypt$16384$8$1$'));
  assert.equal(verifyPassword('SenhaForte!2026', h1), true);
  assert.equal(verifyPassword('SenhaErrada!2026', h1), false);
  assert.throws(() => hashPassword('123'));
});

test('JWT HS256 assina, valida, detecta adulteração e expiração', () => {
  process.env.NODE_ENV = 'test';
  clearKeyCacheForTests();
  const token = signJwt({ uid: 'u1', role: 'superAdmin', superAdmin: true, email: 'admin@test' }, { ttlSeconds: 300 });
  const payload = verifyJwt(token);
  assert.equal(payload.uid, 'u1');
  assert.equal(payload.superAdmin, true);
  assert.equal(payload.iss, 'painel-provedores');

  const parts = token.split('.');
  const forgedPayload = Buffer.from(JSON.stringify({ ...payload, role: 'providerAdmin' })).toString('base64url');
  assert.throws(() => verifyJwt(`${parts[0]}.${forgedPayload}.${parts[2]}`), { code: 'auth/invalid-id-token' });

  const expired = signJwt({ uid: 'u1', role: 'superAdmin', superAdmin: true }, { ttlSeconds: -10 });
  assert.throws(() => verifyJwt(expired), { code: 'auth/id-token-expired' });
});

test('verifyLiveSession valida estado vivo, revogação por token_version, desabilitação e escopo', async () => {
  process.env.NODE_ENV = 'test';
  clearKeyCacheForTests();
  const state = {
    admin: { uid: 'a1', email: 'a@t.com', role: 'providerAdmin', provider_id: 'vibe', disabled: false, token_version: 2 },
    sub: { uid: 'subscriber:vibe:12345678909', provider_id: 'vibe', cpfcnpj: '12345678909', email: 'c@t.com', disabled: false, token_version: 1 },
  };
  const pool = {
    query: async (sql, params) => {
      if (sql.includes('FROM admin_users')) return { rows: params[0] === state.admin.uid ? [state.admin] : [] };
      if (sql.includes('FROM subscribers')) return { rows: params[0] === state.sub.uid ? [state.sub] : [] };
      return { rows: [] };
    },
  };

  const adminToken = signJwt({ uid: 'a1', role: 'providerAdmin', providerId: 'vibe', tv: 2 });
  const adminSess = await verifyLiveSession(pool, adminToken);
  assert.equal(adminSess.role, 'providerAdmin');
  assert.equal(adminSess.providerId, 'vibe');

  const subToken = signJwt({ uid: 'subscriber:vibe:12345678909', role: 'subscriber', providerId: 'vibe', cpfCnpj: '12345678909', tv: 1 });
  const subSess = await verifyLiveSession(pool, subToken);
  assert.equal(subSess.cpfCnpj, '12345678909');

  state.admin.token_version = 3;
  await assert.rejects(() => verifyLiveSession(pool, adminToken), { code: 'auth/id-token-revoked' });

  state.admin.token_version = 2;
  state.admin.role = 'superAdmin';
  await assert.rejects(() => verifyLiveSession(pool, adminToken), { code: 'access/scope-changed' });

  state.sub.disabled = true;
  await assert.rejects(() => verifyLiveSession(pool, subToken), { code: 'auth/user-disabled' });
});
