"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getProviderDashboardData = exports.getDashboardData = void 0;
const firestore_1 = require("firebase-admin/firestore");
const firebase_1 = require("../app/firebase");
const permissions_1 = require("../app/permissions");
const getDashboardData = async ({ requesterUid }) => {
    await (0, permissions_1.requireSuperAdmin)(requesterUid);
    const oneDayAgo = firestore_1.Timestamp.fromMillis(Date.now() - 24 * 60 * 60 * 1000);
    const [providers, clients, tickets, notifications, recentTickets] = await Promise.all([
        firebase_1.db.collection("provedores").get(),
        firebase_1.db.collection("clientes").get(),
        firebase_1.db.collection("tickets").where("status", "in", ["Aberto", "Em Andamento"]).get(),
        firebase_1.db.collection("notifications").where("createdAt", ">=", oneDayAgo).get(),
        firebase_1.db.collection("tickets").orderBy("updatedAt", "desc").limit(5).get(),
    ]);
    const chartData = providers.docs.map((provider) => ({
        name: provider.data().name || provider.id,
        clientes: clients.docs.filter((client) => client.data().providerId === provider.id).length,
    }));
    return {
        stats: {
            providerCount: providers.size,
            clientCount: clients.size,
            notificationCount: notifications.size,
            openTicketsCount: tickets.size,
        },
        chartData,
        recentTickets: recentTickets.docs.map((ticket) => (Object.assign({ id: ticket.id }, ticket.data()))),
    };
};
exports.getDashboardData = getDashboardData;
const getProviderDashboardData = async ({ requesterUid, payload }) => {
    await (0, permissions_1.requireProviderAccess)(requesterUid, payload.providerId);
    const [clients, openTickets, notifications, recentTickets] = await Promise.all([
        firebase_1.db.collection("clientes").where("providerId", "==", payload.providerId).get(),
        firebase_1.db.collection("tickets").where("providerId", "==", payload.providerId).where("status", "in", ["Aberto", "Em Andamento"]).get(),
        firebase_1.db.collection("notifications").where("providerId", "==", payload.providerId).get(),
        firebase_1.db.collection("tickets").where("providerId", "==", payload.providerId).orderBy("updatedAt", "desc").limit(5).get(),
    ]);
    const activeClients = clients.docs.filter((client) => {
        const status = String(client.data().status || "").toLowerCase();
        return status.includes("ativo") && !status.includes("inativo");
    }).length;
    return {
        stats: {
            clientCount: clients.size,
            totalClients: clients.size,
            activeClientCount: activeClients,
            openTicketsCount: openTickets.size,
            notificationCount: notifications.size,
        },
        recentTickets: recentTickets.docs.map((ticket) => (Object.assign({ id: ticket.id }, ticket.data()))),
    };
};
exports.getProviderDashboardData = getProviderDashboardData;
//# sourceMappingURL=dashboard.js.map