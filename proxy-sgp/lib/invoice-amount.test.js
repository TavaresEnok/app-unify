'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { invoiceAmount } = require('./invoice-amount');

test('preserves the invoice amount for numeric and Brazilian SGP formats', () => {
    for (const amount of [1234.56, '1234.56', '1234,56', 'R$ 1.234,56']) {
        assert.equal(invoiceAmount(amount), 1234.56);
    }
    assert.equal(invoiceAmount('0,00'), 0);
    for (const missing of [undefined, null, false, '', ' ', '-', '99,90xx', Infinity]) {
        assert.equal(invoiceAmount(missing), null);
    }
});
