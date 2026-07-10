"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteProviderBackup = exports.restoreProviderConfig = exports.listProviderBackups = exports.backupProviderConfig = void 0;
const firestore_1 = require("firebase-admin/firestore");
const errors_1 = require("../app/errors");
const firebase_1 = require("../app/firebase");
const permissions_1 = require("../app/permissions");
const backupProviderConfig = async ({ requestId, requesterUid, payload }) => {
    var _a;
    await (0, permissions_1.requireProviderAccess)(requesterUid, payload.providerId);
    const providerRef = firebase_1.db.collection("provedores").doc(payload.providerId);
    const [provider, secrets] = await Promise.all([
        providerRef.get(),
        providerRef.collection("secrets").doc("sgp").get(),
    ]);
    if (!provider.exists)
        throw new errors_1.AppError("not-found", "Provedor não encontrado.");
    const backupRef = providerRef.collection("backups").doc(requestId);
    await backupRef.set({
        name: ((_a = payload.name) === null || _a === void 0 ? void 0 : _a.trim()) || `Backup ${new Date().toISOString()}`,
        providerData: provider.data(),
        secrets: secrets.exists ? secrets.data() : null,
        createdBy: requesterUid,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { success: true, message: "Backup criado.", backupId: backupRef.id };
};
exports.backupProviderConfig = backupProviderConfig;
const listProviderBackups = async ({ requesterUid, payload }) => {
    await (0, permissions_1.requireProviderAccess)(requesterUid, payload.providerId);
    const snapshot = await firebase_1.db.collection("provedores").doc(payload.providerId)
        .collection("backups").orderBy("createdAt", "desc").get();
    return snapshot.docs.map((backup) => {
        const data = backup.data();
        return { id: backup.id, name: data.name, createdAt: data.createdAt, createdBy: data.createdBy };
    });
};
exports.listProviderBackups = listProviderBackups;
const restoreProviderConfig = async ({ requesterUid, payload }) => {
    await (0, permissions_1.requireProviderAccess)(requesterUid, payload.providerId);
    const providerRef = firebase_1.db.collection("provedores").doc(payload.providerId);
    const backup = await providerRef.collection("backups").doc(payload.backupId).get();
    if (!backup.exists)
        throw new errors_1.AppError("not-found", "Backup não encontrado.");
    const data = backup.data() || {};
    if (!data.providerData || typeof data.providerData !== "object") {
        throw new errors_1.AppError("invalid-argument", "Backup inválido.");
    }
    const batch = firebase_1.db.batch();
    batch.set(providerRef, Object.assign(Object.assign({}, data.providerData), { updatedAt: firestore_1.FieldValue.serverTimestamp() }), { merge: true });
    if (data.secrets && typeof data.secrets === "object") {
        batch.set(providerRef.collection("secrets").doc("sgp"), data.secrets, { merge: true });
    }
    await batch.commit();
    return { success: true, message: "Backup restaurado." };
};
exports.restoreProviderConfig = restoreProviderConfig;
const deleteProviderBackup = async ({ requesterUid, payload }) => {
    await (0, permissions_1.requireProviderAccess)(requesterUid, payload.providerId);
    await firebase_1.db.collection("provedores").doc(payload.providerId).collection("backups").doc(payload.backupId).delete();
    return { success: true, message: "Backup apagado." };
};
exports.deleteProviderBackup = deleteProviderBackup;
//# sourceMappingURL=backups.js.map