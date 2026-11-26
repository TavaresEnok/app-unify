'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { shouldPrune, withPageRetry, nextDelay, syncFailureLog, MAX_DELAYS } = require('./sync-guard');

test('prune só roda com sincronização completa', () => {
    assert.equal(shouldPrune({ count: 3400, fetched: 3500, erpTotal: 3500, previousCount: 196 }).prune, true);
    assert.equal(shouldPrune({ count: 196, fetched: 199, erpTotal: 3500, previousCount: 619 }).prune, false, 'paginação quebrada');
    assert.equal(shouldPrune({ count: 196, fetched: 199, erpTotal: undefined, previousCount: 3400 }).prune, false, 'muito abaixo da última contagem');
    assert.equal(shouldPrune({ count: 0, fetched: 0, erpTotal: 0, previousCount: 0 }).prune, false);
    assert.equal(shouldPrune({ count: 50, fetched: 50, erpTotal: undefined, previousCount: undefined }).prune, true, 'primeira sincronização');
});

test('página com falha transitória é repetida; erro 4xx não', async () => {
    let calls = 0;
    const sleep = async () => undefined;
    assert.equal(await withPageRetry(async () => { if (++calls < 3) throw Object.assign(new Error('dns'), { status: 503, dnsFailure: true }); return 'ok'; }, { sleep }), 'ok');
    assert.equal(calls, 3);
    calls = 0;
    await assert.rejects(withPageRetry(async () => { calls++; throw Object.assign(new Error('bad'), { response: { status: 400 } }); }, { sleep }));
    assert.equal(calls, 1);
    calls = 0;
    await assert.rejects(withPageRetry(async () => { calls++; throw Object.assign(new Error('down'), { status: 503 }); }, { sleep }), { status: 503 });
    assert.equal(calls, 3);
});

test('reagendamento em 503 cresce e tem limite', () => {
    const fixed = () => 0;
    assert.equal(nextDelay(0, fixed), 1500);
    assert.equal(nextDelay(3, fixed), 12000);
    assert.equal(nextDelay(20, fixed), 90000);
    assert.equal(nextDelay(MAX_DELAYS, fixed), null);
});

test('falha de sync registra só job, provedor e status HTTP', () => {
    const error = Object.assign(new Error('SGP retornou erro HTTP 401 token=synthetic'), { response: { status: 401, data: { cliente: 'synthetic-name' } } });
    const line = syncFailureLog({ id: 'sync:upconnect', data: { providerId: 'upconnect', cpf: '00000000000' } }, error);
    assert.deepEqual(JSON.parse(line), { event: 'sync.failed', id: 'sync:upconnect', providerId: 'upconnect', status: 401 });
    assert.doesNotMatch(line, /synthetic|00000000000/);
    assert.equal(JSON.parse(syncFailureLog({ id: 'x', data: { providerId: 'p' } }, new Error('rede'))).status, null);
});
