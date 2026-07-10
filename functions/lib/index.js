"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupFunctionDocuments = exports.handleFunctionRequest = exports.generateApk = exports.uploadProviderLogo = void 0;
const firestore_1 = require("firebase-admin/firestore");
const firestore_2 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const requestRouter_1 = require("./app/requestRouter");
const config_1 = require("./app/config");
const firebase_1 = require("./app/firebase");
const handlers_1 = require("./handlers");
var uploadProviderLogo_1 = require("./callables/uploadProviderLogo");
Object.defineProperty(exports, "uploadProviderLogo", { enumerable: true, get: function () { return uploadProviderLogo_1.uploadProviderLogo; } });
var generateApk_1 = require("./callables/generateApk");
Object.defineProperty(exports, "generateApk", { enumerable: true, get: function () { return generateApk_1.generateApk; } });
const routeRequest = (0, requestRouter_1.createRequestRouter)(handlers_1.handlers);
exports.handleFunctionRequest = (0, firestore_2.onDocumentCreated)({
    document: "function_requests/{requestId}",
    region: "southamerica-east1",
    timeoutSeconds: 540,
    memory: "512MiB",
    secrets: [config_1.proxyUrlSecret, config_1.proxySecretParam],
}, async (event) => {
    var _a;
    await routeRequest(event.params.requestId, (_a = event.data) === null || _a === void 0 ? void 0 : _a.data());
});
exports.cleanupFunctionDocuments = (0, scheduler_1.onSchedule)({
    schedule: "every day 03:00",
    region: "southamerica-east1",
    timeZone: "America/Sao_Paulo",
}, async () => {
    const threshold = firestore_1.Timestamp.now();
    for (const collectionName of ["function_requests", "function_responses"]) {
        const field = collectionName === "function_requests" ? "createdAt" : "expiresAt";
        const cutoff = collectionName === "function_requests"
            ? firestore_1.Timestamp.fromMillis(Date.now() - 7 * 24 * 60 * 60 * 1000)
            : threshold;
        while (true) {
            const snapshot = await firebase_1.db.collection(collectionName).where(field, "<=", cutoff).limit(400).get();
            if (snapshot.empty)
                break;
            const batch = firebase_1.db.batch();
            snapshot.docs.forEach((document) => batch.delete(document.ref));
            await batch.commit();
            if (snapshot.size < 400)
                break;
        }
    }
    await firebase_1.db.collection("maintenance_logs").add({
        job: "cleanupFunctionDocuments",
        completedAt: firestore_1.FieldValue.serverTimestamp(),
    });
});
//# sourceMappingURL=index.js.map