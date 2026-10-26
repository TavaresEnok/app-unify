const test = require('node:test');
const assert = require('node:assert/strict');
const { createLogoPolicy } = require('./security');

const policy = createLogoPolicy(['storage.googleapis.com']);

test('logo policy accepts configured HTTPS hosts', () => {
    assert.equal(policy.validate('https://storage.googleapis.com/bucket/logo.png').hostname, 'storage.googleapis.com');
});

test('logo policy rejects HTTP and unknown hosts', () => {
    assert.throws(() => policy.validate('http://storage.googleapis.com/logo.png'));
    assert.throws(() => policy.validate('https://127.0.0.1/logo.png'));
});
