import { Router } from "express";
import { verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { firestore } from "../services/firebaseAdmin";

export const dashboardRouter = Router();
dashboardRouter.use(verifyToken);

dashboardRouter.get("/", asyncRoute(async (req, res) => {
  if (req.user?.superAdmin === true) {
    const [providers, openTickets, tickets, users] = await Promise.all([
      firestore.collection("provedores").count().get(),
      firestore.collection("tickets").where("status", "in", ["Aberto", "Em Andamento"]).count().get(),
      firestore.collection("tickets").count().get(),
      firestore.collection("clientes").count().get(),
    ]);
    return res.json({ data: {
      totalProviders: providers.data().count,
      totalTickets: tickets.data().count,
      openTickets: openTickets.data().count,
      totalUsers: users.data().count,
    } });
  }
  const providerId = typeof req.user?.providerId === "string" ? req.user.providerId : "";
  if (!providerId) throw new ApiError(403, "Sem provedor associado.", "permission-denied");
  const [openTickets, tickets, clients] = await Promise.all([
    firestore.collection("tickets").where("providerId", "==", providerId).where("status", "in", ["Aberto", "Em Andamento"]).count().get(),
    firestore.collection("tickets").where("providerId", "==", providerId).count().get(),
    firestore.collection("clientes").where("providerId", "==", providerId).count().get(),
  ]);
  return res.json({ data: { totalProviders: 1, totalTickets: tickets.data().count, openTickets: openTickets.data().count, totalUsers: clients.data().count } });
}));
