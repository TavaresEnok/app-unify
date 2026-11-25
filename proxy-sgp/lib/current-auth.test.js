const { test } = require('node:test');
const assert = require('node:assert/strict');
const { persistSubscriber, authFailure } = require('./current-auth');
test('create race re-reads and never overwrites a conflicting user or hides lookup failure', async () => {
    let reads = 0, writes = 0;
    const identity = { uid: 'subscriber:a:12345678901', claims: { role: 'subscriber', providerId: 'a', cpfCnpj: '12345678901' } };
    const auth = { getUser: async () => { if (++reads === 1) throw { code: 'auth/user-not-found' }; return { customClaims: { superAdmin: true } }; }, createUser: async () => { throw { code: 'auth/uid-already-exists' }; }, setCustomUserClaims: async () => { writes++; } };
    await assert.rejects(persistSubscriber(auth, identity)); assert.equal(reads, 2); assert.equal(writes, 0);
    auth.getUser = async () => { throw Error('lookup outage'); };
    await assert.rejects(persistSubscriber(auth, identity)); assert.equal(writes, 0);
});
