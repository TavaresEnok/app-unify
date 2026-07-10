"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.writeSuccess = writeSuccess;
exports.writeFailure = writeFailure;
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("./firebase");
const RESPONSE_TTL_DAYS = 7;
function expirationDate() {
    const expires = new Date();
    expires.setUTCDate(expires.getUTCDate() + RESPONSE_TTL_DAYS);
    return firestore_1.Timestamp.fromDate(expires);
}
function writeSuccess(requestId, requesterUid, result) {
    return firebase_1.db.collection("function_responses").doc(requestId).set({
        result,
        requesterUid,
        completedAt: firestore_1.FieldValue.serverTimestamp(),
        expiresAt: expirationDate(),
    });
}
function writeFailure(requestId, requesterUid, error, code) {
    return firebase_1.db.collection("function_responses").doc(requestId).set({
        error,
        code,
        requesterUid,
        completedAt: firestore_1.FieldValue.serverTimestamp(),
        expiresAt: expirationDate(),
    });
}
//# sourceMappingURL=writeResponse.js.map