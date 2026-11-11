const { test } = require('node:test');
const assert = require('node:assert/strict');
const { secretMatches } = require('./internal-secret');
test('normalizes service-secret line endings without accepting empty or different tokens', () => {
    assert.equal(secretMatches('service-key\n', 'service-key'), true);
    assert.equal(secretMatches('service-key', 'service-key\r\n'), true);
    assert.equal(secretMatches('', ''), false);
    assert.equal(secretMatches(' \n', ' \n'), false);
    assert.equal(secretMatches('wrong-key', 'service-key'), false);
    assert.equal(secretMatches(undefined, 'service-key'), false);
});
