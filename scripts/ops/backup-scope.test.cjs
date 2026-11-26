const { test } = require('node:test');
const assert = require('node:assert/strict');
const { firestoreScope } = require('./backup-scope.cjs');
test('daily export includes business data while weekly export includes everything', () => {
    const roots = ['provedores', 'users', 'providers', 'new-business-collection', 'function_requests', 'function_responses', 'function_locks', 'audit_logs'];
    const daily = firestoreScope(roots);
    for (const id of ['provedores', 'users', 'providers', 'new-business-collection', 'messages', 'migration_backups']) assert.ok(daily.includes(id));
    for (const id of ['function_requests', 'function_responses', 'function_locks', 'audit_logs']) assert.ok(!daily.includes(id));
    assert.deepEqual(firestoreScope(roots, { full: true }), []);
});
test('daily export leaves out legacy subscriber copies and integration secrets', () => {
    const daily = firestoreScope(['provedores', 'clientes', 'secrets']);
    assert.ok(!daily.includes('clientes'));
    assert.ok(!daily.includes('secrets'));
    assert.ok(daily.includes('provedores'));
});
