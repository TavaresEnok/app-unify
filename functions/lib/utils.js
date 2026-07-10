"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.logger = exports.TICKET_STATUSES = void 0;
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
function structuredLog(severity, message, context = {}) {
    const entry = Object.assign(Object.assign({ severity,
        message }, context), { timestamp: new Date().toISOString() });
    if (severity === "ERROR" || severity === "CRITICAL") {
        console.error(JSON.stringify(entry));
    }
    else if (severity === "WARNING") {
        console.warn(JSON.stringify(entry));
    }
    else {
        console.log(JSON.stringify(entry));
    }
}
exports.logger = {
    info: (message, context) => structuredLog("INFO", message, context),
    warn: (message, context) => structuredLog("WARNING", message, context),
    error: (message, context) => structuredLog("ERROR", message, context),
    critical: (message, context) => structuredLog("CRITICAL", message, context),
};
//# sourceMappingURL=utils.js.map