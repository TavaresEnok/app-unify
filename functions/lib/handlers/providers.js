"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteProvider = exports.updateProviderDetails = exports.updateProviderConfig = exports.createProvider = void 0;
const firestore_1 = require("firebase-admin/firestore");
const errors_1 = require("../app/errors");
const firebase_1 = require("../app/firebase");
const permissions_1 = require("../app/permissions");
const utils_1 = require("../utils");
const DEFAULT_PROVIDER_CONFIG = {
    layoutType: "layout_06",
    themeColor: "#673AB7",
    secondaryColor: "#9575CD",
    textColor: "#FFFFFF",
    invoiceColor: "#10B981",
    actionColor: "#E11D48",
    cardColor: "#F8F8F8",
    cardTextColor: "#333333",
    logoUrl: "",
    loginQuote: "Bem-vindo ao App do Assinante",
    features: { consumption: true, support: true, invoices: true },
    menuConfig: { order: ["invoices", "support", "contract"], items: {} },
};
function asRecord(value) {
    return value && typeof value === "object" && !Array.isArray(value)
        ? value
        : {};
}
const createProvider = async ({ requestId, requesterUid, payload }) => {
    var _a;
    await (0, permissions_1.requireSuperAdmin)(requesterUid);
    const providerId = payload.providerId.trim();
    const name = payload.name.trim();
    if (!providerId || !name || !(0, utils_1.isValidNewProviderId)(providerId)) {
        throw new errors_1.AppError("invalid-argument", "Nome ou ID de provedor inválido.");
    }
    const providerRef = firebase_1.db.collection("provedores").doc(providerId);
    const existing = await providerRef.get();
    if (existing.exists && ((_a = existing.data()) === null || _a === void 0 ? void 0 : _a.createdByRequestId) === requestId) {
        return { success: true, message: "Provedor criado com sucesso.", providerId };
    }
    if (existing.exists) {
        throw new errors_1.AppError("conflict", "Já existe um provedor com este ID.");
    }
    await providerRef.set(Object.assign(Object.assign({}, DEFAULT_PROVIDER_CONFIG), { name, active: true, createdByRequestId: requestId, createdAt: firestore_1.FieldValue.serverTimestamp(), updatedAt: firestore_1.FieldValue.serverTimestamp() }));
    return { success: true, message: "Provedor criado com sucesso.", providerId };
};
exports.createProvider = createProvider;
const updateProviderConfig = async ({ requesterUid, payload }) => {
    await (0, permissions_1.requireProviderAccess)(requesterUid, payload.providerId);
    const config = asRecord(payload.config);
    const publicConfig = Object.assign({}, config);
    delete publicConfig.config;
    const integrations = asRecord(publicConfig.integrations);
    delete publicConfig.integrations;
    const providerRef = firebase_1.db.collection("provedores").doc(payload.providerId);
    const provider = await providerRef.get();
    if (!provider.exists)
        return { success: true, message: "Provedor apagado com sucesso." };
    if (Object.keys(integrations).length) {
        await providerRef.collection("secrets").doc("sgp").set({ integrations }, { merge: true });
    }
    await providerRef.update(Object.assign(Object.assign({}, publicConfig), { integrations: firestore_1.FieldValue.delete(), "config.integrations": firestore_1.FieldValue.delete(), updatedAt: firestore_1.FieldValue.serverTimestamp() }));
    return { success: true, message: "Configurações atualizadas.", providerId: payload.providerId };
};
exports.updateProviderConfig = updateProviderConfig;
const updateProviderDetails = async ({ requesterUid, payload }) => {
    await (0, permissions_1.requireProviderAccess)(requesterUid, payload.providerId);
    const details = asRecord(payload.details);
    const publicDetails = Object.assign({}, details);
    delete publicDetails.apiToken;
    delete publicDetails.token;
    delete publicDetails.password;
    delete publicDetails.secret;
    delete publicDetails.name;
    const secretIntegrations = {};
    if ("appName" in details)
        secretIntegrations.appName = details.appName;
    if ("apiToken" in details)
        secretIntegrations.apiToken = details.apiToken;
    if ("systemUrl" in details)
        secretIntegrations.sgpBaseUrl = details.systemUrl;
    const providerRef = firebase_1.db.collection("provedores").doc(payload.providerId);
    await Promise.all([
        providerRef.set(Object.assign(Object.assign(Object.assign({}, (typeof details.name === "string" && details.name ? { name: details.name } : {})), (typeof details.apiUrl === "string" && details.apiUrl ? { apiUrl: details.apiUrl } : {})), { details: publicDetails, updatedAt: firestore_1.FieldValue.serverTimestamp() }), { merge: true }),
        Object.keys(secretIntegrations).length
            ? providerRef.collection("secrets").doc("sgp").set({ integrations: secretIntegrations }, { merge: true })
            : Promise.resolve(),
    ]);
    return { success: true, message: "Provedor atualizado com sucesso.", providerId: payload.providerId };
};
exports.updateProviderDetails = updateProviderDetails;
const deleteProvider = async ({ requesterUid, payload }) => {
    await (0, permissions_1.requireSuperAdmin)(requesterUid);
    const providerRef = firebase_1.db.collection("provedores").doc(payload.providerId);
    const provider = await providerRef.get();
    if (!provider.exists)
        throw new errors_1.AppError("not-found", "Provedor não encontrado.");
    const [users, tickets] = await Promise.all([
        firebase_1.db.collection("users").where("providerId", "==", payload.providerId).get(),
        firebase_1.db.collection("tickets").where("providerId", "==", payload.providerId).get(),
    ]);
    for (const userDoc of users.docs) {
        await firebase_1.auth.deleteUser(userDoc.id).catch(() => undefined);
        await userDoc.ref.delete();
    }
    for (const ticket of tickets.docs)
        await firebase_1.db.recursiveDelete(ticket.ref);
    await firebase_1.db.recursiveDelete(providerRef);
    return { success: true, message: "Provedor apagado com sucesso." };
};
exports.deleteProvider = deleteProvider;
//# sourceMappingURL=providers.js.map