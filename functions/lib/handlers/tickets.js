"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteTicket = exports.updateTicketStatus = exports.replyToTicket = exports.createTicket = exports.getProviderTickets = exports.getAllTickets = void 0;
const firestore_1 = require("firebase-admin/firestore");
const errors_1 = require("../app/errors");
const firebase_1 = require("../app/firebase");
const permissions_1 = require("../app/permissions");
const utils_1 = require("../utils");
function serialize(doc) {
    return Object.assign({ id: doc.id }, doc.data());
}
async function requireTicketAccess(requesterUid, ticketId) {
    const [user, ticket] = await Promise.all([
        (0, permissions_1.requireRequester)(requesterUid),
        firebase_1.db.collection("tickets").doc(ticketId).get(),
    ]);
    if (!ticket.exists)
        throw new errors_1.AppError("not-found", "Ticket não encontrado.");
    const data = ticket.data() || {};
    const allowed = (0, permissions_1.isSuperAdmin)(user) || (0, permissions_1.requesterProviderId)(user) === data.providerId || data.createdByUid === requesterUid;
    if (!allowed)
        throw new errors_1.AppError("permission-denied", "Permissão negada para este ticket.");
    return { user, ticket, data };
}
const getAllTickets = async ({ requesterUid }) => {
    await (0, permissions_1.requireSuperAdmin)(requesterUid);
    const snapshot = await firebase_1.db.collection("tickets").orderBy("updatedAt", "desc").get();
    return snapshot.docs.map(serialize);
};
exports.getAllTickets = getAllTickets;
const getProviderTickets = async ({ requesterUid, payload }) => {
    await (0, permissions_1.requireProviderAccess)(requesterUid, payload.providerId);
    const snapshot = await firebase_1.db.collection("tickets")
        .where("providerId", "==", payload.providerId)
        .orderBy("updatedAt", "desc")
        .get();
    return snapshot.docs.map(serialize);
};
exports.getProviderTickets = getProviderTickets;
const createTicket = async ({ requestId, requesterUid, payload }) => {
    var _a;
    const user = await (0, permissions_1.requireRequester)(requesterUid);
    const claimedProvider = (0, permissions_1.requesterProviderId)(user);
    if (!(0, permissions_1.isSuperAdmin)(user) && claimedProvider && claimedProvider !== payload.providerId) {
        throw new errors_1.AppError("permission-denied", "Permissão negada para este provedor.");
    }
    if (!(0, permissions_1.isSuperAdmin)(user) && !claimedProvider) {
        const client = await firebase_1.db.collection("clientes").doc(requesterUid).get();
        if (!client.exists || ((_a = client.data()) === null || _a === void 0 ? void 0 : _a.providerId) !== payload.providerId) {
            throw new errors_1.AppError("permission-denied", "Cliente não associado a este provedor.");
        }
    }
    if (!payload.subject.trim() || !payload.message.trim()) {
        throw new errors_1.AppError("invalid-argument", "Assunto e mensagem são obrigatórios.");
    }
    const ticketRef = firebase_1.db.collection("tickets").doc(requestId);
    const now = firestore_1.FieldValue.serverTimestamp();
    await ticketRef.set({
        subject: payload.subject.trim(),
        status: "Aberto",
        providerId: payload.providerId,
        providerName: payload.providerName || payload.providerId,
        userEmail: payload.userEmail || user.email || "",
        createdByUid: requesterUid,
        createdAt: now,
        updatedAt: now,
    });
    await ticketRef.collection("messages").doc("initial").set({
        message: payload.message.trim(),
        senderUid: requesterUid,
        senderEmail: payload.userEmail || user.email || "",
        senderRole: (0, permissions_1.isSuperAdmin)(user) ? "superAdmin" : (claimedProvider ? "providerAdmin" : "client"),
        imageUrl: payload.imageUrl || null,
        createdAt: now,
    });
    return { success: true, message: "Ticket criado com sucesso.", ticketId: ticketRef.id };
};
exports.createTicket = createTicket;
const replyToTicket = async ({ requesterUid, payload }) => {
    const { user, ticket } = await requireTicketAccess(requesterUid, payload.ticketId);
    if (!payload.message.trim())
        throw new errors_1.AppError("invalid-argument", "A mensagem é obrigatória.");
    const now = firestore_1.FieldValue.serverTimestamp();
    await Promise.all([
        ticket.ref.collection("messages").add({
            message: payload.message.trim(),
            senderUid: requesterUid,
            senderEmail: user.email || "",
            senderRole: (0, permissions_1.isSuperAdmin)(user) ? "superAdmin" : ((0, permissions_1.requesterProviderId)(user) ? "providerAdmin" : "client"),
            imageUrl: payload.imageUrl || null,
            createdAt: now,
        }),
        ticket.ref.set({ updatedAt: now }, { merge: true }),
    ]);
    return { success: true, message: "Resposta enviada." };
};
exports.replyToTicket = replyToTicket;
const updateTicketStatus = async ({ requesterUid, payload }) => {
    const { user, ticket, data } = await requireTicketAccess(requesterUid, payload.ticketId);
    if (!(0, permissions_1.isSuperAdmin)(user) && (0, permissions_1.requesterProviderId)(user) !== data.providerId) {
        throw new errors_1.AppError("permission-denied", "Apenas administradores podem alterar o status.");
    }
    if (!(0, utils_1.isValidTicketStatus)(payload.status))
        throw new errors_1.AppError("invalid-argument", "Status inválido.");
    await ticket.ref.set({ status: payload.status, updatedAt: firestore_1.FieldValue.serverTimestamp() }, { merge: true });
    return { success: true, message: "Status atualizado." };
};
exports.updateTicketStatus = updateTicketStatus;
const deleteTicket = async ({ requesterUid, payload }) => {
    await (0, permissions_1.requireSuperAdmin)(requesterUid);
    const ref = firebase_1.db.collection("tickets").doc(payload.ticketId);
    if (!(await ref.get()).exists)
        return { success: true, message: "Ticket apagado." };
    await firebase_1.db.recursiveDelete(ref);
    return { success: true, message: "Ticket apagado." };
};
exports.deleteTicket = deleteTicket;
//# sourceMappingURL=tickets.js.map