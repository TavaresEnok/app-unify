const { test } = require('node:test');
const assert = require('node:assert/strict');
const { wifiNetworks, assertWifiResponse, preservedWifiPassword } = require('./wifi-response');
test('normalizes direct and wrapped Wi-Fi lists without presenting API errors as empty networks', () => {
    const rows = [{ id: '2', ssid: 'Test' }];
    for (const response of [rows, { data: rows }, { wifis: rows }]) assert.deepEqual(wifiNetworks(response), rows);
    for (const response of [{ error: 'offline' }, { message: 'failed' }, { data: null }, null]) assert.throws(() => wifiNetworks(response), { status: 502 });
    assert.deepEqual(wifiNetworks([]), []);
});
test('preserves only the exact selected network password and rejects missing or masked values', () => {
    const rows = [{ id: '2', password: 'test-only-password' }, { id: '3', password: '********' }];
    assert.equal(preservedWifiPassword(rows, 2), 'test-only-password');
    assert.throws(() => preservedWifiPassword(rows, '3'), { status: 422 });
    assert.throws(() => preservedWifiPassword(rows, '4'), { status: 422 });
});
test('explicit SGP failures never become successful updates', () => {
    for (const response of [false, null, { success: false }, { status: false }, { error: 'offline' }]) assert.throws(() => assertWifiResponse(response), { status: 502 });
    assert.deepEqual(assertWifiResponse({ success: true }), { success: true });
});
