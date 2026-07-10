"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.recordAudit = recordAudit;
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("./firebase");
const REDACTED_KEYS = new Set(["password", "senha", "token", "apitoken", "authorization", "secret", "privatekey", "credential"]);
function isSensitiveKey(key) {
    const normalized = key.toLowerCase().replace(/[^a-z0-9]/g, "");
    return REDACTED_KEYS.has(normalized) || normalized.endsWith("token") || normalized.endsWith("secret");
}
function redact(value) {
    if (Array.isArray(value))
        return value.map(redact);
    if (!value || typeof value !== "object")
        return value;
    return Object.fromEntries(Object.entries(value).map(([key, next]) => [
        key,
        isSensitiveKey(key) ? "[REDACTED]" : redact(next),
    ]));
}
async function recordAudit(entry) {
    await firebase_1.db.collection("audit_logs").add(Object.assign(Object.assign({}, entry), { payload: redact(entry.payload), createdAt: firestore_1.FieldValue.serverTimestamp() }));
}
//# sourceMappingURL=audit.js.map