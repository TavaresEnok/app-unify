import { Router } from "express";
import { verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { firestore, serverTimestamp } from "../services/firebaseAdmin";
import { recordAdminAudit } from "../services/auditService";

export const ticketsRouter = Router();
ticketsRouter.use(verifyToken);

async function requireTicket(req: Express.Request, ticketId: string) {
  const ticket = await firestore.collection("tickets").doc(ticketId).get();
  if (!ticket.exists) throw new ApiError(404, "Ticket não encontrado.", "not-found");
  const data = ticket.data() || {};
  const allowed = req.user?.superAdmin === true || req.user?.providerId === data.providerId || req.user?.uid === data.createdByUid;
  if (!allowed) throw new ApiError(403, "Sem permissão para este ticket.", "permission-denied");
  return { ticket, data };
}

function serialize(id: string, input: FirebaseFirestore.DocumentData) {
  const data = { ...input };
  for (const key of ["createdAt", "updatedAt"]) if (data[key]?.toDate) data[key] = data[key].toDate().toISOString();
  return { id, ...data };
}

ticketsRouter.get("/", asyncRoute(async (req, res) => {
  let query: FirebaseFirestore.Query = firestore.collection("tickets");
  if (req.user?.superAdmin !== true) {
    const providerId = typeof req.user?.providerId === "string" ? req.user.providerId : "";
    if (!providerId) throw new ApiError(403, "Sem permissão para listar tickets.", "permission-denied");
    query = query.where("providerId", "==", providerId);
  }
  const snapshot = await query.orderBy("updatedAt", "desc").get();
  res.json({ data: snapshot.docs.map((ticket) => serialize(ticket.id, ticket.data())) });
}));

ticketsRouter.get("/:id/messages", asyncRoute(async (req, res) => {
  const { ticket } = await requireTicket(req, req.params.id);
  const snapshot = await ticket.ref.collection("messages").orderBy("createdAt", "asc").get();
  res.json({ data: snapshot.docs.map((message) => serialize(message.id, message.data())) });
}));

ticketsRouter.patch("/:id", asyncRoute(async (req, res) => {
  const { ticket, data } = await requireTicket(req, req.params.id);
  if (req.user?.superAdmin !== true && req.user?.providerId !== data.providerId) throw new ApiError(403, "Apenas administradores podem alterar o ticket.", "permission-denied");
  const allowed: Record<string, unknown> = {};
  if (req.body?.status !== undefined) {
    if (!["Aberto", "Em Andamento", "Fechado"].includes(req.body.status)) throw new ApiError(400, "Status inválido.", "invalid-argument");
    allowed.status = req.body.status;
  }
  if (typeof req.body?.subject === "string" && req.body.subject.trim()) allowed.subject = req.body.subject.trim();
  await ticket.ref.set({ ...allowed, updatedAt: serverTimestamp() }, { merge: true });
  await recordAdminAudit({ type: "UPDATE_TICKET", requesterUid: req.user!.uid, providerId: data.providerId, correlationId: req.correlationId, payload: { ticketId: req.params.id, ...allowed } });
  res.json({ success: true });
}));

ticketsRouter.post("/:id/reply", asyncRoute(async (req, res) => {
  const { ticket, data } = await requireTicket(req, req.params.id);
  const message = typeof req.body?.message === "string" ? req.body.message.trim() : "";
  if (!message) throw new ApiError(400, "Mensagem obrigatória.", "invalid-argument");
  await Promise.all([
    ticket.ref.collection("messages").add({
      message,
      senderUid: req.user?.uid,
      senderEmail: req.user?.email || "",
      senderRole: req.user?.superAdmin ? "superAdmin" : "providerAdmin",
      createdAt: serverTimestamp(),
      read: false,
    }),
    ticket.ref.set({ updatedAt: serverTimestamp(), status: "Em Andamento", lastMessage: message }, { merge: true }),
  ]);
  await recordAdminAudit({ type: "REPLY_TO_TICKET", requesterUid: req.user!.uid, providerId: data.providerId, correlationId: req.correlationId, payload: { ticketId: req.params.id } });
  res.json({ success: true });
}));
