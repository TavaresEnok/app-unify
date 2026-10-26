const test = require('node:test');
const assert = require('node:assert/strict');
const { loadConfig, positiveInteger } = require('./config');

test('loadConfig normalizes environment values', () => {
    const config = loadConfig({
        PORT: '4000',
        ALLOWED_ORIGINS: 'https://one.example, https://two.example ',
        ENABLE_DEV_CPF_MOCK: 'true',
        DEV_MOCK_CPF: '123.456.789-00',
    });
    assert.equal(config.port, 4000);
    assert.deepEqual(config.allowedOrigins, ['https://one.example', 'https://two.example']);
    assert.equal(config.devCpf, '12345678900');
});

test('positiveInteger rejects invalid limits', () => {
    assert.equal(positiveInteger('-1', 60), 60);
    assert.equal(positiveInteger('invalid', 60), 60);
});
