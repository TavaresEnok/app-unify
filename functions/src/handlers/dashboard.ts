import { Timestamp } from "firebase-admin/firestore";
import type { RequestHandler } from "../app/request";
import { db } from "../app/firebase";
import { requireProviderAccess, requireSuperAdmin } from "../app/permissions";

export const getDashboardData: RequestHandler<"GET_DASHBOARD_DATA"> = async ({ requesterUid }) => {
  await requireSuperAdmin(requesterUid);
  const oneDayAgo = Timestamp.fromMillis(Date.now() - 24 * 60 * 60 * 1000);
  const [providers, clients, tickets, notifications, recentTickets] = await Promise.all([
    db.collection("provedores").get(),
    db.collection("clientes").get(),
    db.collection("tickets").where("status", "in", ["Aberto", "Em Andamento"]).get(),
    db.collection("notifications").where("createdAt", ">=", oneDayAgo).get(),
    db.collection("tickets").orderBy("updatedAt", "desc").limit(5).get(),
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
    recentTickets: recentTickets.docs.map((ticket) => ({ id: ticket.id, ...ticket.data() })),
  };
};

export const getProviderDashboardData: RequestHandler<"GET_PROVIDER_DASHBOARD_DATA"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  const [clients, openTickets, notifications, recentTickets] = await Promise.all([
    db.collection("clientes").where("providerId", "==", payload.providerId).get(),
    db.collection("tickets").where("providerId", "==", payload.providerId).where("status", "in", ["Aberto", "Em Andamento"]).get(),
    db.collection("notifications").where("providerId", "==", payload.providerId).get(),
    db.collection("tickets").where("providerId", "==", payload.providerId).orderBy("updatedAt", "desc").limit(5).get(),
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
    recentTickets: recentTickets.docs.map((ticket) => ({ id: ticket.id, ...ticket.data() })),
  };
};
