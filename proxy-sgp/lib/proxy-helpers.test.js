'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { publicError } = require('./proxy-errors');
const { localParts, localIsoDate } = require('./local-date');
const { parseOnuInfo } = require('./onu-details');
const { isSensitiveKeyForTests } = require('./secure-log');

test('erros do ERP viram mensagens claras', () => {
    assert.deepEqual(publicError(Object.assign(new Error('x'), { dnsFailure: true, status: 503 }), 'Erro interno.').status, 503);
    assert.deepEqual(publicError(Object.assign(new Error('x'), { status: 404 }), 'Erro interno.'), { status: 404, message: 'Contrato não encontrado para este CPF/CNPJ.' });
    assert.deepEqual(publicError(Object.assign(new Error('x'), { response: { status: 400 }, sgpMessage: 'Promessa já utilizada neste mês.' })), { status: 422, message: 'Promessa já utilizada neste mês.' });
    assert.equal(publicError(Object.assign(new Error('Erro de conexão'), { status: 503, connectionFailure: true })).message, 'Não conseguimos falar com o sistema do provedor agora. Tente novamente em instantes.');
    assert.deepEqual(publicError(new Error('boom'), 'Erro interno ao buscar faturas.'), { status: 502, message: 'Erro interno ao buscar faturas.' });
    assert.deepEqual(publicError(Object.assign(new Error('x'), { status: 422, publicMessage: 'Equipamento não encontrado.' })), { status: 422, message: 'Equipamento não encontrado.' });
});

test('mês e dia de negócio seguem o fuso de Fortaleza, não UTC', () => {
    const lateLastDay = new Date('2026-11-30T23:30:00-03:00'); // já é 01/12 em UTC
    assert.deepEqual(localParts(lateLastDay), { year: 2026, month: 11, day: 30 });
    assert.equal(localIsoDate(lateLastDay), '2026-11-30');
    assert.equal(localIsoDate(new Date('2026-12-01T03:00:00Z')), '2026-12-01');
});

test('leitura da OLT extrai só campos conhecidos', () => {
    const now = new Date('2026-11-26T12:00:00Z');
    const result = parseOnuInfo({ result: [
        '  Run state               : online',
        '  ONT online duration     : 0 day(s), 18 hour(s), 7 minute(s), 0 second(s)',
        '  Last down cause         : dying-gasp',
        '  Last down time          : 2026-11-25 14:53:00-03:00',
        '  Last dying gasp time    : 2026-11-25 14:52:58-03:00',
        '  ONT distance(m)         : 588',
        '  Rx optical power(dBm)   : -19.31',
        '  Tx optical power(dBm)   : 2.26',
        '  OLT Rx ONT optical power(dBm) : -22.84',
        '  Temperature(C)          : 49',
        '  SN                      : 4E565432AABBCCDD',
        '  Password                : secret',
    ].join('\n') }, now);
    assert.equal(result.online, true);
    assert.equal(result.onlineSince, new Date(now.getTime() - (18 * 3600 + 7 * 60) * 1000).toISOString());
    assert.equal(result.lastDownCause, 'Falta de energia no equipamento');
    assert.equal(result.lastDownAt, '2026-11-25T17:53:00.000Z');
    assert.equal(result.distanceMeters, 588);
    assert.equal(result.rxPowerDbm, -19.31);
    assert.equal(result.oltRxPowerDbm, -22.84);
    assert.equal(result.temperatureC, 49);
    assert.ok(!JSON.stringify(result).includes('4E565432'), 'serial nunca sai');
    assert.ok(!JSON.stringify(result).includes('secret'));
    assert.equal(parseOnuInfo('texto sem campos'), null);
    const offline = parseOnuInfo('Run state : offline\nLast down cause : LOS', now);
    assert.equal(offline.online, false); assert.equal(offline.onlineSince, null); assert.equal(offline.lastDownCause, 'Perda de sinal na fibra');
});

test('serial e endereço físico da ONU são mascarados no log', () => {
    assert.equal(isSensitiveKeyForTests('phy_addr'), true);
    assert.equal(isSensitiveKeyForTests('serial'), true);
    assert.equal(isSensitiveKeyForTests('serialNumber'), true);
});
