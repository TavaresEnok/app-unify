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
