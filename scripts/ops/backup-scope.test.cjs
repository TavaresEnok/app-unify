const { test } = require('node:test');
const assert = require('node:assert/strict');
const { firestoreScope } = require('./backup-scope.cjs');
test('daily export includes business data and nested secrets while weekly export includes everything', () => {
    const roots = ['provedores', 'users', 'providers', 'new-business-collection', 'function_requests', 'function_responses', 'function_locks', 'audit_logs'];
    const daily = firestoreScope(roots);
    for (const id of ['provedores', 'users', 'providers', 'new-business-collection', 'secrets', 'clientes', 'messages']) assert.ok(daily.includes(id));
    for (const id of ['function_requests', 'function_responses', 'function_locks', 'audit_logs']) assert.ok(!daily.includes(id));
    assert.deepEqual(firestoreScope(roots, { full: true }), []);
});
