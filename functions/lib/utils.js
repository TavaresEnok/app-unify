"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TICKET_STATUSES = void 0;
exports.parseJsonSafely = parseJsonSafely;
exports.isValidTicketStatus = isValidTicketStatus;
exports.isValidNewProviderId = isValidNewProviderId;
/** Parse JSON seguro para respostas de texto de APIs externas. */
function parseJsonSafely(value) {
    try {
        return value ? JSON.parse(value) : null;
    }
    catch (_a) {
        return null;
    }
}
exports.TICKET_STATUSES = new Set(["Aberto", "Em Andamento", "Fechado"]);
function isValidTicketStatus(status) {
    return exports.TICKET_STATUSES.has(status);
}
/** ID de provedor para criação: apenas minúsculas, números, _ e -. */
function isValidNewProviderId(id) {
    return /^[a-z0-9_-]+$/.test(id);
}
//# sourceMappingURL=utils.js.map