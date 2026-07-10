"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendSegmentedNotification = exports.sendScopedNotification = exports.sendPushNotification = void 0;
const firestore_1 = require("firebase-admin/firestore");
const errors_1 = require("../app/errors");
const firebase_1 = require("../app/firebase");
const permissions_1 = require("../app/permissions");
async function sendTokens(tokens, title, body, data) {
    let successCount = 0;
    let failureCount = 0;
    for (let index = 0; index < tokens.length; index += 500) {
        const response = await firebase_1.messaging.sendEachForMulticast({
            tokens: tokens.slice(index, index + 500),
            notification: { title, body },
            data,
            android: {
                priority: "high",
                notification: { channelId: "high_importance_channel", priority: "high" },
            },
        });
        successCount += response.successCount;
        failureCount += response.failureCount;
    }
    return { successCount, failureCount };
}
async function sendPush(requesterUid, payload) {
    var _a, _b;
    const requester = await (0, permissions_1.requireRequester)(requesterUid);
    const providerId = payload.providerId || (0, permissions_1.requesterProviderId)(requester);
    if (!providerId && !(0, permissions_1.isSuperAdmin)(requester))
        throw new errors_1.AppError("invalid-argument", "ProviderID obrigatório.");
    if (providerId)
        await (0, permissions_1.requireProviderAccess)(requesterUid, providerId);
    const title = payload.title.trim();
    const body = payload.body.trim();
    if (!title || !body)
        throw new errors_1.AppError("invalid-argument", "Título e mensagem são obrigatórios.");
    let counts = { successCount: 0, failureCount: 0 };
    const data = { route: payload.route || "", category: payload.category || "info" };
    if (payload.targetCpf) {
        let client = await firebase_1.db.collection("clientes").doc(payload.targetCpf).get();
        if (!client.exists) {
            const matches = await firebase_1.db.collection("clientes").where("cpfCnpj", "==", payload.targetCpf).limit(1).get();
            client = matches.docs[0];
        }
        if (!(client === null || client === void 0 ? void 0 : client.exists) || (providerId && ((_a = client.data()) === null || _a === void 0 ? void 0 : _a.providerId) !== providerId)) {
            throw new errors_1.AppError("not-found", "Cliente não encontrado.");
        }
        const token = (_b = client.data()) === null || _b === void 0 ? void 0 : _b.fcmToken;
        if (typeof token === "string" && token)
            counts = await sendTokens([token], title, body, data);
    }
    else if (payload.targetAll && providerId) {
        await firebase_1.messaging.send({
            topic: `provider_${providerId}`,
            notification: { title, body },
            data,
            android: { priority: "high", notification: { channelId: "high_importance_channel", priority: "high" } },
        });
        counts.successCount = 1;
    }
    else if (providerId) {
        const clients = await firebase_1.db.collection("clientes").where("providerId", "==", providerId).get();
        const tokens = clients.docs.map((client) => client.data().fcmToken).filter((token) => typeof token === "string" && !!token);
        counts = await sendTokens(tokens, title, body, data);
    }
    await firebase_1.db.collection("notifications").add(Object.assign(Object.assign({ providerId: providerId || null, title,
        body, category: payload.category || "info", targetAll: !!payload.targetAll, targetCpf: payload.targetCpf || null }, counts), { sentBy: requesterUid, createdAt: firestore_1.FieldValue.serverTimestamp() }));
    return { success: true, message: `Notificação enviada: ${counts.successCount} entrega(s), ${counts.failureCount} falha(s).` };
}
const sendPushNotification = async ({ requesterUid, payload }) => {
    return sendPush(requesterUid, payload);
};
exports.sendPushNotification = sendPushNotification;
const sendScopedNotification = async ({ requesterUid, payload }) => {
    return sendPush(requesterUid, payload);
};
exports.sendScopedNotification = sendScopedNotification;
const sendSegmentedNotification = async ({ requesterUid, payload }) => {
    if (!payload.providerId)
        throw new errors_1.AppError("invalid-argument", "ProviderID obrigatório.");
    await (0, permissions_1.requireProviderAccess)(requesterUid, payload.providerId);
    const title = payload.title.trim();
    const body = payload.body.trim();
    if (!title || !body)
        throw new errors_1.AppError("invalid-argument", "Título e mensagem são obrigatórios.");
    const clients = await firebase_1.db.collection("clientes").where("providerId", "==", payload.providerId).get();
    const tokens = clients.docs.flatMap((client) => {
        const data = client.data();
        const token = data.fcmToken;
        if (typeof token !== "string" || !token)
            return [];
        if (payload.statusFilter && payload.statusFilter !== "all" &&
            !String(data.status || "").toLowerCase().includes(payload.statusFilter.toLowerCase()))
            return [];
        if (payload.planFilter && payload.planFilter !== "all" &&
            !String(data.plano || data.plan || "").toLowerCase().includes(payload.planFilter.toLowerCase()))
            return [];
        return [token];
    });
    const counts = await sendTokens(tokens, title, body, { route: "/provedor/dashboard", category: "segmented" });
    await firebase_1.db.collection("notifications").add(Object.assign(Object.assign({ providerId: payload.providerId, title,
        body, category: "segmented", statusFilter: payload.statusFilter || "all", planFilter: payload.planFilter || "all" }, counts), { sentBy: requesterUid, createdAt: firestore_1.FieldValue.serverTimestamp() }));
    return { success: true, message: `Notificação enviada: ${counts.successCount} entrega(s), ${counts.failureCount} falha(s).` };
};
exports.sendSegmentedNotification = sendSegmentedNotification;
//# sourceMappingURL=notifications.js.map