import { Timestamp, type Firestore } from "firebase-admin/firestore";

async function count(query: FirebaseFirestore.Query): Promise<number> {
  return (await query.count().get()).data().count;
}

export async function loadGlobalDashboard(db: Firestore) {
  const oneDayAgo = Timestamp.fromMillis(Date.now() - 24 * 60 * 60 * 1000);
  const [providers, clientCount, openTicketsCount, notificationCount, recentTickets] = await Promise.all([
    db.collection("provedores").get(),
    count(db.collection("clientes")),
    count(db.collection("tickets").where("status", "in", ["Aberto", "Em Andamento"])),
    count(db.collection("notifications").where("createdAt", ">=", oneDayAgo)),
    db.collection("tickets").orderBy("updatedAt", "desc").limit(5).get(),
  ]);
  const chartData: Array<{ name: string; clientes: number }> = new Array(providers.docs.length);
  let next = 0;
  // Bounded parallelism avoids a serial network round trip for each provider.
  await Promise.all(Array.from({ length: Math.min(4, providers.docs.length) }, async () => {
    while (next < providers.docs.length) {
      const index = next++, provider = providers.docs[index];
      chartData[index] = { name: provider.data().name || provider.id,
        clientes: await count(db.collection("clientes").where("providerId", "==", provider.id)) };
    }
  }));
  return {
    stats: { providerCount: providers.size, clientCount, notificationCount, openTicketsCount },
    chartData,
    recentTickets: recentTickets.docs.map((ticket) => ({ id: ticket.id, ...ticket.data() })),
  };
}

export async function loadProviderDashboard(db: Firestore, providerId: string) {
  const clients = db.collection("clientes").where("providerId", "==", providerId);
  const tickets = db.collection("tickets").where("providerId", "==", providerId);
  const [clientCount, activeClientCount, openTicketsCount, notificationCount, recentTickets] = await Promise.all([
    count(clients),
    count(clients.where("status", "in", ["Ativo", "ativo", "ATIVO", "Online", "online"])),
    count(tickets.where("status", "in", ["Aberto", "Em Andamento"])),
    count(db.collection("notifications").where("providerId", "==", providerId)),
    tickets.orderBy("updatedAt", "desc").limit(5).get(),
  ]);
  return {
    stats: { clientCount, totalClients: clientCount, activeClientCount, openTicketsCount, notificationCount },
    recentTickets: recentTickets.docs.map((ticket) => ({ id: ticket.id, ...ticket.data() })),
  };
}
