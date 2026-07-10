"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteClient = exports.getClientDetails = exports.listProviderClients = void 0;
const errors_1 = require("../app/errors");
const firebase_1 = require("../app/firebase");
const permissions_1 = require("../app/permissions");
function sanitizeClient(id, data) {
    const output = Object.assign({ id }, data);
    const contracts = Array.isArray(data.contratos) ? data.contratos : [];
    output.contratos = contracts.map((contract) => {
        if (!contract || typeof contract !== "object")
            return contract;
        const sanitized = Object.assign({}, contract);
        for (const key of Object.keys(sanitized)) {
            if (["senha", "password", "token", "apitoken", "authorization", "secret", "contratocentralsenha"].includes(key.toLowerCase())) {
                delete sanitized[key];
            }
        }
        return sanitized;
    });
    return output;
}
const listProviderClients = async ({ requesterUid, payload }) => {
    await (0, permissions_1.requireProviderAccess)(requesterUid, payload.providerId);
    const snapshot = await firebase_1.db.collection("provedores").doc(payload.providerId).collection("clientes").orderBy("nome").get();
    return snapshot.docs.map((client) => sanitizeClient(client.id, client.data()));
};
exports.listProviderClients = listProviderClients;
const getClientDetails = async ({ requesterUid, payload }) => {
    await (0, permissions_1.requireProviderAccess)(requesterUid, payload.providerId);
    const collection = firebase_1.db.collection("provedores").doc(payload.providerId).collection("clientes");
    let client = await collection.doc(payload.clientId).get();
    if (!client.exists) {
        const bySgpId = await collection.where("id", "==", Number(payload.clientId)).limit(1).get();
        client = bySgpId.docs[0];
    }
    if (!(client === null || client === void 0 ? void 0 : client.exists))
        throw new errors_1.AppError("not-found", "Cliente não encontrado.");
    return sanitizeClient(client.id, client.data() || {});
};
exports.getClientDetails = getClientDetails;
const deleteClient = async ({ requesterUid, payload }) => {
    var _a;
    await (0, permissions_1.requireProviderAccess)(requesterUid, payload.providerId);
    const nestedRef = firebase_1.db.collection("provedores").doc(payload.providerId).collection("clientes").doc(payload.clientId);
    const globalRef = firebase_1.db.collection("clientes").doc(payload.clientId);
    const global = await globalRef.get();
    const batch = firebase_1.db.batch();
    batch.delete(nestedRef);
    if (global.exists && ((_a = global.data()) === null || _a === void 0 ? void 0 : _a.providerId) === payload.providerId)
        batch.delete(globalRef);
    await batch.commit();
    return { success: true, message: "Cliente removido do cache." };
};
exports.deleteClient = deleteClient;
//# sourceMappingURL=clients.js.map