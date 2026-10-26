const test = require('node:test');
const assert = require('node:assert/strict');
const { maskCpfCnpj, sanitizeForLog } = require('./secure-log');

test('sanitizeForLog recursively masks credentials and personal identifiers', () => {
    assert.deepEqual(sanitizeForLog({ token: 'abcdef', nested: { cpf: '12345678900' }, ok: 'visible' }), {
        token: 'ab***ef',
        nested: { cpf: '12***00' },
        ok: 'visible',
    });
});

test('maskCpfCnpj does not expose the complete identifier', () => {
    assert.equal(maskCpfCnpj('123.456.789-00'), '12***00');
});
