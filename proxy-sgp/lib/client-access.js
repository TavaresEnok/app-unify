'use strict';

const DENIED_CONTRACT_STATUS_PARTS = [
    'cancelad',
    'desativ',
    'encerrad',
    'inativ',
];

function canIssueClientToken(contractStatus) {
    const normalized = String(contractStatus || '').trim().toLocaleLowerCase('pt-BR');
    return !DENIED_CONTRACT_STATUS_PARTS.some((status) => normalized.includes(status));
}

module.exports = { canIssueClientToken };

function subscriberIdentity(providerId, cpf) {
    if (typeof providerId !== 'string' || !/^[a-z0-9_-]{1,64}$/i.test(providerId) || !/^\d{11}(\d{3})?$/.test(cpf)) {
        throw new Error('Provedor e CPF/CNPJ válidos são obrigatórios.');
    }
    return { uid: `subscriber:${providerId}:${cpf}`, claims: { role: 'subscriber', providerId, cpfCnpj: cpf } };
}

function passwordMatches(provided, expected) {
    if (typeof provided !== 'string' || typeof expected !== 'string' || !provided || !expected || provided.length > 512) return false;
    const { timingSafeEqual } = require('crypto');
    const a = Buffer.from(provided), b = Buffer.from(expected);
    return a.length === b.length && timingSafeEqual(a, b);
}

module.exports.subscriberIdentity = subscriberIdentity;
module.exports.passwordMatches = passwordMatches;
