const test = require('node:test');
const assert = require('node:assert/strict');
const { checkCoreCounts } = require('./backup-core-check.cjs');

test('aceita dump com as tabelas principais preenchidas', () => {
    assert.deepEqual(checkCoreCounts('{"providers":3,"admin_users":2,"provider_secrets":4,"sgp_clients":0}\n'),
        { providers: 3, admin_users: 2, provider_secrets: 4, sgp_clients: 0 });
});

test('recusa dump sem provedores, admins ou segredos', () => {
    assert.throws(() => checkCoreCounts('{"providers":0,"admin_users":2,"provider_secrets":4}'), /providers/);
    assert.throws(() => checkCoreCounts('{"providers":1,"provider_secrets":4}'), /admin_users/);
    assert.throws(() => checkCoreCounts(''), /ilegível/);
});
