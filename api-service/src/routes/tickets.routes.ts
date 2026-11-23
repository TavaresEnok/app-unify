import { Router } from "express";
import { verifyToken, verifyAdmin } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { firestore, messaging, serverTimestamp } from "../services/firebaseAdmin";
import { recordAdminAudit } from "../services/auditService";
import { cursorTimestamp, decodeCursor, encodeCursor, pageSize } from "../services/cursorPage";
import { ensureNotificationSchema, getPgPool } from "../services/postgres";

export const ticketsRouter = Router();
ticketsRouter.use(verifyToken, verifyAdmin);

// Cursor pagination for the web client. Legacy routes remain compatible during migration.
ticketsRouter.get('/page', asyncRoute(async (req, res) => {
  const size = pageSize(req.query.limit);
  const providerId = req.user?.superAdmin === true ? undefined : req.user?.providerId;
  if (req.user?.superAdmin !== true && !providerId) throw new ApiError(403, 'Provedor obrigatório.', 'permission-denied');
  const scope = `tickets:${providerId || 'global'}`;
  const cursor = decodeCursor(req.query.cursor, scope, true);
  let query: FirebaseFirestore.Query = firestore.collection('tickets');
  if (providerId) query = query.where('providerId', '==', providerId);
  query = query.orderBy('updatedAt', 'desc').orderBy('__name__', 'desc');
  if (cursor) query = query.startAfter(cursorTimestamp(cursor), cursor.id);
  const snapshot = await query.limit(size + 1).get();
  const docs = snapshot.docs.slice(0, size);
  res.setHeader('Cache-Control', 'private, no-store');
  res.json({ data: docs.map(doc => serialize(doc.id, doc.data())), nextCursor: snapshot.docs.length > size ? encodeCursor(scope, docs[docs.length - 1], 'updatedAt') : null });
}));

async function requireTicket(req: Express.Request, ticketId: string) {
  const ticket = await firestore.collection("tickets").doc(ticketId).get();
  if (!ticket.exists) throw new ApiError(404, "Ticket não encontrado.", "not-found");
  const data = ticket.data() || {};
  const allowed = req.user?.superAdmin === true || (req.user?.role === "providerAdmin" && req.user?.providerId === data.providerId);
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
  const snapshot = await query.orderBy("updatedAt", "desc").limit(200).get();
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
  if (Object.keys(req.body || {}).some(key => /url|path|attachment|image|owner/i.test(key))) throw new ApiError(400, "Use o endpoint privado de anexos.");
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
  void notifyTicketReplyPush({
    providerId: String(data.providerId || ""),
    ticketId: req.params.id,
    subject: typeof data.subject === "string" ? data.subject : "",
    message,
    userId: typeof data.userId === "string" ? data.userId : "",
    cpfCnpj: String(data.cpfCnpj || data.clientCpf || data.clientId || "").replace(/\D/g, ""),
  });
  res.json({ success: true });
}));

async function notifyTicketReplyPush(input: {
  providerId: string;
  ticketId: string;
  subject: string;
  message: string;
  userId: string;
  cpfCnpj: string;
}): Promise<void> {
  const pool = getPgPool();
  if (!pool || !input.providerId || (!input.userId && !input.cpfCnpj)) return;
  try {
    await ensureNotificationSchema(pool);
    const devices = await pool.query<{ fcm_token: string }>(
      `SELECT DISTINCT fcm_token
         FROM subscriber_devices
        WHERE provider_id = $1
          AND fcm_token <> ''
          AND (($2 <> '' AND auth_uid = $2) OR ($3 <> '' AND cpfcnpj = $3))
        LIMIT 10`,
      [input.providerId, input.userId, input.cpfCnpj],
    );
    const tokens = devices.rows.map((r) => r.fcm_token).filter(Boolean);
    if (!tokens.length) return;
    const title = input.subject
      ? `Resposta no chamado: ${input.subject.slice(0, 60)}`
      : "Nova resposta no seu chamado";
    const resp = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title,
        body: input.message.slice(0, 140),
      },
      data: {
        route: "/suporte",
        ticketId: input.ticketId,
      },
    });
    const deadTokens: string[] = [];
    resp.responses.forEach((r, idx) => {
      const code = r.error?.code || "";
      if (!r.success && (code === "messaging/registration-token-not-registered" || code === "messaging/invalid-registration-token")) {
        deadTokens.push(tokens[idx]);
      }
    });
    if (deadTokens.length) {
      await pool.query(
        `DELETE FROM subscriber_devices WHERE provider_id = $1 AND fcm_token = ANY($2::text[])`,
        [input.providerId, deadTokens],
      ).catch(() => undefined);
    }
  } catch (error) {
    console.warn(JSON.stringify({ severity: "WARNING", message: "ticket.reply.push_failed", ticketId: input.ticketId, error: (error as Error).message }));
  }
}
