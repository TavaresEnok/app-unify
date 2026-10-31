const { test } = require('node:test');
const assert = require('node:assert/strict');
const { migrateSubscriberProfile } = require('./subscriber-profile');
const { subscriberIdentity } = require('./client-access');
function database(store) {
    function collection(path) { return { doc: id => ({ path: `${path}/${id}`, collection: name => collection(`${path}/${id}/${name}`) }) }; }
    return { collection, runTransaction: async operation => operation({
        get: async ref => ({ exists: store.has(ref.path), data: () => store.get(ref.path) }),
        set: (ref, data) => store.set(ref.path, { ...store.get(ref.path), ...data }), delete: ref => store.delete(ref.path),
    }) };
}
test('profile migration backs up legacy data and never merges a different provider', async () => {
    const cpf = '12345678901';
    const store = new Map([[`clientes/${cpf}`, { providerId: 'alpha', fcmToken: 'device' }]]);
    const db = database(store);
    await migrateSubscriberProfile(db, subscriberIdentity('beta', cpf), { nome: 'Beta' }, () => 1);
    assert.equal(store.get(`clientes/${cpf}`).providerId, 'alpha');
    assert.equal(store.get(`clientes/subscriber:beta:${cpf}`).fcmToken, undefined);
    await migrateSubscriberProfile(db, subscriberIdentity('alpha', cpf), { nome: 'Alpha' }, () => 1);
    assert.equal(store.has(`clientes/${cpf}`), false);
    assert.equal(store.get(`clientes/subscriber:alpha:${cpf}`).fcmToken, 'device');
    assert.equal(store.get(`provedores/alpha/migration_backups/legacy-client-${cpf}`).migratedTo, `subscriber:alpha:${cpf}`);
});
