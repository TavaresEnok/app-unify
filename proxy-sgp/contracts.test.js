const { readFileSync } = require('node:fs');
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { endpointContracts } = require('./contracts');

test('endpoint contracts are unique and classified', () => {
  const keys = endpointContracts.map(({ method, path }) => `${method} ${path}`);
  assert.equal(new Set(keys).size, keys.length);
  assert.ok(endpointContracts.every(({ owner, access, decision }) => owner && access && decision));
});

test('every documented endpoint still exists in the proxy source', () => {
  const source = readFileSync(require.resolve('./index'), 'utf8');
  for (const endpoint of endpointContracts) {
    assert.match(source, new RegExp(`app\\.${endpoint.method.toLowerCase()}\\(['\"]${endpoint.path.replaceAll('/', '\\/')}['\"]`));
  }
});
