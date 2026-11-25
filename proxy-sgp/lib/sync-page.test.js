const { test } = require('node:test');
const assert = require('node:assert/strict');
const { validateSyncPage } = require('./sync-page');
test('stops invalid, repeated, and unbounded SGP pagination', () => {
    const first = validateSyncPage(1, [{ id: 1, cpfcnpj: '12345678901' }]);
    assert.throws(() => validateSyncPage(2, [{ id: 1, cpfcnpj: '12345678901' }], first), /repetiu/);
    assert.doesNotThrow(() => validateSyncPage(2, [{ id: 2, cpfcnpj: '98765432101' }], first));
    assert.doesNotThrow(() => validateSyncPage(2, [], first));
    assert.throws(() => validateSyncPage(1001, []), /Limite/);
});

test('uses the SGP offset contract and preserves the active-client filter', () => {
    const { syncParameters } = require('./sync-page');
    assert.deepEqual(syncParameters(1), { limit: 100, offset: 0, contrato_status: 1, omitir_titulos: 1 });
    assert.equal(syncParameters(2).offset, 100);
    assert.equal(syncParameters(33).offset, 3200);
    assert.equal('pagina' in syncParameters(2), false);
});

test('paginação segue o total do SGP mesmo com página incompleta e para em página vazia', () => {
    const { hasNextSyncPage } = require('./sync-page');
    assert.equal(hasNextSyncPage(2, 99, { total: 1430 }), true, 'página com 99 não encerra se o total diz que há mais');
    assert.equal(hasNextSyncPage(15, 30, { total: 1430 }), true);
    assert.equal(hasNextSyncPage(16, 30, { total: 1430 }), false);
    assert.equal(hasNextSyncPage(3, 100, { total_paginas: 2 }), false);
    assert.equal(hasNextSyncPage(2, 0, { total: 1430 }), false, 'página vazia encerra');
    assert.equal(hasNextSyncPage(2, 100, undefined), true);
    assert.equal(hasNextSyncPage(2, 99, {}), false, 'sem metadados, página incompleta encerra (IXC)');
});
