'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { canIssueClientToken } = require('./client-access');

test('allows active and payment-blocked contracts to access the app', () => {
    assert.equal(canIssueClientToken('Ativo'), true);
    assert.equal(canIssueClientToken('Bloqueado'), true);
    assert.equal(canIssueClientToken(''), true);
});

test('denies contracts that are no longer active accounts', () => {
    assert.equal(canIssueClientToken('Cancelado'), false);
    assert.equal(canIssueClientToken('INATIVO'), false);
    assert.equal(canIssueClientToken('Contrato encerrado'), false);
});
