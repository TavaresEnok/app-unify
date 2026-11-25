const test = require('node:test');
const assert = require('node:assert/strict');
const {
  legacyFirebaseAuthEnabled, looksLikeFirebaseIdToken, verifySessionWithLegacy, issueLegacyCustomToken,
} = require('./legacy-firebase-auth');

const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const firebaseToken = `${b64({ alg: 'RS256', kid: 'k1' })}.${b64({ uid: 'x' })}.sig`;
const ownToken = `${b64({ alg: 'HS256' })}.${b64({ uid: 'x' })}.sig`;
const before = new Date('2027-01-30T12:00:00-03:00');
const after = new Date('2027-01-31T00:00:01-03:00');
const invalid = () => Promise.reject(Object.assign(new Error('x'), { code: 'auth/invalid-id-token' }));

function pool({ admin = false, rows = [] } = {}) {
  return { query: async (sql) => ({ rows: sql.includes('admin_users') ? (admin ? [{}] : []) : rows }) };
}
function auth(claims) {
  return { verifyIdToken: async (_t, checkRevoked) => { assert.equal(checkRevoked, true); return { uid: 'subscriber:vibe:123', ...claims }; } };
}
const subscriberClaims = { role: 'subscriber', providerId: 'vibe', cpfCnpj: '123' };

test('janela de transição respeita a data e falha fechada sem configuração', () => {
  process.env.LEGACY_FIREBASE_AUTH_UNTIL = '2027-01-31';
  assert.equal(legacyFirebaseAuthEnabled(before), true);
  assert.equal(legacyFirebaseAuthEnabled(after), false);
  assert.equal(legacyFirebaseAuthEnabled(before, ''), false);
  assert.equal(legacyFirebaseAuthEnabled(before, 'amanhã'), false);
});

test('distingue ID token do Firebase do JWT próprio', () => {
  assert.equal(looksLikeFirebaseIdToken(firebaseToken), true);
  assert.equal(looksLikeFirebaseIdToken(ownToken), false);
  assert.equal(looksLikeFirebaseIdToken('lixo'), false);
});

test('JWT próprio válido nunca passa pelo Firebase', async () => {
  const identity = await verifySessionWithLegacy(pool(), ownToken, async () => ({ uid: 'novo' }), {
    now: before, auth: { verifyIdToken: () => assert.fail('não deveria chamar Firebase') },
  });
  assert.equal(identity.uid, 'novo');
});

test('aceita assinante com ID token do Firebase dentro da janela', async () => {
  const identity = await verifySessionWithLegacy(pool(), firebaseToken, invalid, { now: before, auth: auth(subscriberClaims) });
  assert.deepEqual([identity.role, identity.providerId, identity.cpfCnpj, identity.legacyFirebase], ['subscriber', 'vibe', '123', true]);
});

test('recusa token do Firebase depois da data', async () => {
  await assert.rejects(verifySessionWithLegacy(pool(), firebaseToken, invalid, { now: after, auth: auth(subscriberClaims) }), { code: 'auth/invalid-id-token' });
});

test('recusa admin, claims incompletos, assinante desativado e conflito de escopo', async () => {
  for (const claims of [{ role: 'providerAdmin', providerId: 'vibe', cpfCnpj: '1' }, { role: 'subscriber', providerId: 'vibe' }, { ...subscriberClaims, superAdmin: true }]) {
    await assert.rejects(verifySessionWithLegacy(pool(), firebaseToken, invalid, { now: before, auth: auth(claims) }), { code: 'auth/invalid-id-token' });
  }
  await assert.rejects(verifySessionWithLegacy(pool({ admin: true }), firebaseToken, invalid, { now: before, auth: auth(subscriberClaims) }), { code: 'access/identity-conflict' });
  await assert.rejects(verifySessionWithLegacy(pool({ rows: [{ disabled: true, provider_id: 'vibe', cpfcnpj: '123' }] }), firebaseToken, invalid, { now: before, auth: auth(subscriberClaims) }), { code: 'auth/user-disabled' });
  await assert.rejects(verifySessionWithLegacy(pool({ rows: [{ disabled: false, provider_id: 'outro', cpfcnpj: '123' }] }), firebaseToken, invalid, { now: before, auth: auth(subscriberClaims) }), { code: 'access/scope-changed' });
});

test('erros que não são de formato passam direto (ex.: sessão revogada)', async () => {
  const revoked = () => Promise.reject(Object.assign(new Error('x'), { code: 'auth/id-token-revoked' }));
  await assert.rejects(verifySessionWithLegacy(pool(), firebaseToken, revoked, { now: before, auth: auth(subscriberClaims) }), { code: 'auth/id-token-revoked' });
});

test('custom token legado nunca derruba o login novo', async () => {
  const identity = { uid: 'subscriber:vibe:123', claims: subscriberClaims };
  assert.equal(await issueLegacyCustomToken(identity, { now: before, auth: {}, persistSubscriber: async () => 'firebase-custom' }), 'firebase-custom');
  assert.equal(await issueLegacyCustomToken(identity, { now: before, auth: {}, persistSubscriber: async () => { throw Object.assign(new Error(), { code: 'auth/x' }); } }), null);
  assert.equal(await issueLegacyCustomToken(identity, { now: after, auth: {}, persistSubscriber: async () => 'x' }), null);
});
