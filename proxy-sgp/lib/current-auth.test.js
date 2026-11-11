const { test } = require('node:test');
const assert = require('node:assert/strict');
const { currentIdentity, persistSubscriber, authFailure } = require('./current-auth');
test('current identity ignores old admin scope, changed tenant, disabled and unavailable authority', async () => {
    const identity = { uid: 'u', role: 'providerAdmin', providerId: 'a' };
    const auth = { verifyIdToken: async (_token, revoked) => { assert.equal(revoked, true); return identity; }, getUser: async () => ({ customClaims: { role: 'providerAdmin', providerId: 'a' } }) };
    assert.equal((await currentIdentity(auth, 'synthetic')).providerId, 'a');
    for (const claims of [{ role: 'providerAdmin', providerId: 'b' }, {}, { role: 'subscriber', providerId: 'a' }]) {
        auth.getUser = async () => ({ customClaims: claims });
        await assert.rejects(currentIdentity(auth, 'synthetic'));
    }
    auth.getUser = async () => ({ disabled: true }); await assert.rejects(currentIdentity(auth, 'synthetic'));
    assert.equal(authFailure({ code: 'auth/id-token-revoked' }).status, 401);
    assert.deepEqual(authFailure(Error('private')), { status: 503, code: 'authorization-unavailable' });
});
test('create race re-reads and never overwrites a conflicting user or hides lookup failure', async () => {
    let reads = 0, writes = 0;
    const identity = { uid: 'subscriber:a:12345678901', claims: { role: 'subscriber', providerId: 'a', cpfCnpj: '12345678901' } };
    const auth = { getUser: async () => { if (++reads === 1) throw { code: 'auth/user-not-found' }; return { customClaims: { superAdmin: true } }; }, createUser: async () => { throw { code: 'auth/uid-already-exists' }; }, setCustomUserClaims: async () => { writes++; } };
    await assert.rejects(persistSubscriber(auth, identity)); assert.equal(reads, 2); assert.equal(writes, 0);
    auth.getUser = async () => { throw Error('lookup outage'); };
    await assert.rejects(persistSubscriber(auth, identity)); assert.equal(writes, 0);
});
