'use strict';
const { createHash } = require('crypto');
function validateSyncPage(page, clients, previousHash, maxPages = 1000) {
    if (!Number.isInteger(page) || page < 1 || page > maxPages) throw new Error('Limite de páginas da sincronização excedido.');
    if (!Array.isArray(clients)) throw new Error('Resposta de sincronização inválida.');
    const hash = createHash('sha256').update(JSON.stringify(clients.map(client => [client.id ?? client.clienteId, client.cpfcnpj ?? client.cpfCnpj]))).digest('hex');
    if (clients.length && previousHash === hash) throw new Error('O SGP repetiu a página anterior. Sincronização interrompida para evitar loop.');
    return hash;
}
module.exports = { validateSyncPage };

function syncParameters(page) {
    if (!Number.isInteger(page) || page < 1 || page > 1000) throw new Error('Página inválida.');
    // SGP /api/ura/clientes/ documents offset, not pagina/page.
    return { limit: 100, offset: (page - 1) * 100, contrato_status: 1, omitir_titulos: 1 };
}
module.exports.syncParameters = syncParameters;

// Decide se há próxima página. `nextPage` já é a página seguinte (1-based).
// O SGP pode devolver menos de 100 itens numa página intermediária (filtro
// contrato_status), então `paginacao.total`/`total_paginas` têm prioridade;
// sem eles, página incompleta encerra. Página vazia sempre encerra.
function hasNextSyncPage(nextPage, pageLength, paginacao, pageSize = 100) {
    if (!pageLength) return false;
    const total = Number(paginacao?.total);
    const totalPages = Number(paginacao?.total_paginas);
    const byTotal = Number.isFinite(total) && total > 0 ? (nextPage - 1) * pageSize < total : null;
    const byPages = Number.isFinite(totalPages) && totalPages > 0 ? nextPage <= totalPages : null;
    if (byTotal === false || byPages === false) return false;
    if (byTotal === null && byPages === null) return pageLength >= pageSize;
    return true;
}
module.exports.hasNextSyncPage = hasNextSyncPage;
