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
