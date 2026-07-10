"use strict";
// Generated from shared/contracts/index.ts. Do not edit directly.
/**
 * Canonical contracts shared by the admin panel, Functions and REST API.
 * Run `npm run contracts:sync` after changing this file.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.FUNCTION_REQUEST_TYPES = void 0;
exports.isFunctionRequestType = isFunctionRequestType;
exports.isRecord = isRecord;
exports.requireString = requireString;
exports.validateFunctionPayload = validateFunctionPayload;
exports.assertFunctionRequest = assertFunctionRequest;
exports.FUNCTION_REQUEST_TYPES = [
    "UPDATE_PROVIDER_CONFIG",
    "UPDATE_PROVIDER_DETAILS",
    "CREATE_PROVIDER",
    "DELETE_PROVIDER",
    "GET_DASHBOARD_DATA",
    "GET_PROVIDER_DASHBOARD_DATA",
    "SEND_PUSH_NOTIFICATION",
    "SEND_SCOPED_NOTIFICATION",
    "SEND_SCOPED_NOTIFICATION_SEGMENTED",
    "SGP_API_PROXY",
    "GET_ALL_TICKETS",
    "GET_PROVIDER_TICKETS",
    "CREATE_TICKET",
    "REPLY_TO_TICKET",
    "UPDATE_TICKET_STATUS",
    "DELETE_TICKET",
    "LIST_ADMIN_USERS",
    "CREATE_ADMIN_USER",
    "DELETE_ADMIN_USER",
    "SET_SUPER_ADMIN_BY_EMAIL",
    "LIST_PROVIDER_CLIENTS",
    "GET_CLIENT_DETAILS",
    "DELETE_CLIENT",
    "BACKUP_PROVIDER_CONFIG",
    "LIST_PROVIDER_BACKUPS",
    "RESTORE_PROVIDER_CONFIG",
    "DELETE_PROVIDER_BACKUP",
];
function isFunctionRequestType(value) {
    return typeof value === "string" &&
        exports.FUNCTION_REQUEST_TYPES.includes(value);
}
function isRecord(value) {
    return typeof value === "object" && value !== null && !Array.isArray(value);
}
function requireString(value, field, options = {}) {
    var _a, _b;
    if (typeof value !== "string") {
        throw new Error(`${field} deve ser uma string.`);
    }
    const normalized = value.trim();
    const min = (_a = options.min) !== null && _a !== void 0 ? _a : 1;
    const max = (_b = options.max) !== null && _b !== void 0 ? _b : 10000;
    if (normalized.length < min || normalized.length > max) {
        throw new Error(`${field} deve ter entre ${min} e ${max} caracteres.`);
    }
    return normalized;
}
const REQUIRED_STRING_FIELDS = {
    UPDATE_PROVIDER_CONFIG: ["providerId"],
    UPDATE_PROVIDER_DETAILS: ["providerId"],
    CREATE_PROVIDER: ["providerId", "name"],
    DELETE_PROVIDER: ["providerId"],
    GET_PROVIDER_DASHBOARD_DATA: ["providerId"],
    SEND_PUSH_NOTIFICATION: ["title", "body"],
    SEND_SCOPED_NOTIFICATION: ["title", "body"],
    SEND_SCOPED_NOTIFICATION_SEGMENTED: ["providerId", "title", "body"],
    SGP_API_PROXY: ["providerId", "action"],
    GET_PROVIDER_TICKETS: ["providerId"],
    CREATE_TICKET: ["subject", "message", "providerId"],
    REPLY_TO_TICKET: ["ticketId", "message"],
    UPDATE_TICKET_STATUS: ["ticketId", "status"],
    DELETE_TICKET: ["ticketId"],
    CREATE_ADMIN_USER: ["email", "password", "role"],
    DELETE_ADMIN_USER: ["uid"],
    SET_SUPER_ADMIN_BY_EMAIL: ["email"],
    LIST_PROVIDER_CLIENTS: ["providerId"],
    GET_CLIENT_DETAILS: ["providerId", "clientId"],
    DELETE_CLIENT: ["providerId", "clientId"],
    BACKUP_PROVIDER_CONFIG: ["providerId"],
    LIST_PROVIDER_BACKUPS: ["providerId"],
    RESTORE_PROVIDER_CONFIG: ["providerId", "backupId"],
    DELETE_PROVIDER_BACKUP: ["providerId", "backupId"],
};
function validateFunctionPayload(type, payload) {
    if (!isRecord(payload))
        throw new Error("payload deve ser um objeto.");
    for (const field of REQUIRED_STRING_FIELDS[type] || []) {
        requireString(payload[field], `payload.${field}`);
    }
    if (type === "UPDATE_PROVIDER_CONFIG" && !isRecord(payload.config)) {
        throw new Error("payload.config deve ser um objeto.");
    }
    if (type === "UPDATE_PROVIDER_DETAILS" && !isRecord(payload.details)) {
        throw new Error("payload.details deve ser um objeto.");
    }
    if (type === "CREATE_ADMIN_USER" && !["superAdmin", "providerAdmin"].includes(String(payload.role))) {
        throw new Error("payload.role invalido.");
    }
    if (type === "UPDATE_TICKET_STATUS" && !["Aberto", "Em Andamento", "Fechado"].includes(String(payload.status))) {
        throw new Error("payload.status invalido.");
    }
    if (type === "SGP_API_PROXY" && !["sync", "get", "get_single"].includes(String(payload.action))) {
        throw new Error("payload.action invalido.");
    }
}
function assertFunctionRequest(value) {
    if (!isRecord(value))
        throw new Error("Requisicao invalida.");
    if (!isFunctionRequestType(value.type))
        throw new Error("Tipo de requisicao invalido.");
    requireString(value.requesterUid, "requesterUid", { max: 128 });
    validateFunctionPayload(value.type, value.payload);
}
//# sourceMappingURL=index.js.map