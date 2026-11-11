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

test('subscriber identities are scoped to provider and cannot grant administrator roles', () => {
    const { subscriberIdentity, passwordMatches } = require('./client-access');
    const alpha = subscriberIdentity('alpha', '12345678901');
    const beta = subscriberIdentity('beta', '12345678901');
    assert.notEqual(alpha.uid, beta.uid);
    assert.equal(alpha.claims.role, 'subscriber');
    assert.equal(passwordMatches('correct', 'correct'), true);
    assert.equal(passwordMatches('', ''), false);
    assert.equal(passwordMatches('wrong', 'correct'), false);
    assert.throws(() => subscriberIdentity('../alpha', '12345678901'));
});
