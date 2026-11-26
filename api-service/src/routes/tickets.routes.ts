import { randomUUID } from "node:crypto";
import { Router } from "express";
import { verifyToken, verifyAdmin } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { getMessaging } from "../services/firebaseAdmin";
import { recordAdminAudit } from "../services/auditService";
import { cursorDate, decodeCursor, encodeCursor, pageSize } from "../services/cursorPage";
import { ensureCoreSchema, ensureNotificationSchema, getPgPool, requirePgPool } from "../services/postgres";
import { getProviderRow } from "../services/providersStore";

export const ticketsRouter = Router();
ticketsRouter.use(verifyToken, verifyAdmin);

interface TicketRow {
  id: string;
  provider_id: string;
  provider_name: string;
  subject: string;
  status: string;
  created_by_uid: string;
  created_by_email: string;
  cpfcnpj: string;
  last_message: string;
  created_at: Date;
  updated_at: Date;
}

interface TicketMessageRow {
  id: string;
  ticket_id: string;
  sender_uid: string;
  sender_email: string;
  sender_role: string;
  message: string;
  attachment_id: string | null;
  image_url: string | null;
  read: boolean;
  created_at: Date;
}

function serializeTicket(row: TicketRow) {
  return {
    id: row.id,
    providerId: row.provider_id,
    providerName: row.provider_name,
    subject: row.subject,
    status: row.status,
    createdByUid: row.created_by_uid,
    userId: row.created_by_uid,
    userEmail: row.created_by_email,
    clientCpf: row.cpfcnpj,
    cpfCnpj: row.cpfcnpj,
    lastMessage: row.last_message,
    createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : String(row.created_at),
    updatedAt: row.updated_at instanceof Date ? row.updated_at.toISOString() : String(row.updated_at),
  };
}

function serializeMessage(row: TicketMessageRow) {
  return {
    id: row.id,
    ticketId: row.ticket_id,
    senderUid: row.sender_uid,
    senderEmail: row.sender_email,
    senderRole: row.sender_role,
    message: row.message,
    attachmentId: row.attachment_id,
    imageUrl: row.image_url,
    read: row.read,
    createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : String(row.created_at),
  };
}

async function requireTicket(req: Express.Request, ticketId: string): Promise<TicketRow> {
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const res = await pool.query<TicketRow>(`SELECT * FROM tickets WHERE id = $1 LIMIT 1`, [ticketId]);
  const ticket = res.rows[0];
  if (!ticket) throw new ApiError(404, "Ticket não encontrado.", "not-found");
  const allowed = req.user?.superAdmin === true ||
    (req.user?.role === "providerAdmin" && req.user?.providerId === ticket.provider_id);
  if (!allowed) throw new ApiError(403, "Sem permissão para este ticket.", "permission-denied");
  return ticket;
}

ticketsRouter.get("/page", asyncRoute(async (req, res) => {
  const size = pageSize(req.query.limit);
  const providerId = req.user?.superAdmin === true ? undefined : req.user?.providerId;
  if (req.user?.superAdmin !== true && !providerId) throw new ApiError(403, "Provedor obrigatório.", "permission-denied");
  const scope = `tickets:${providerId || "global"}`;
  const cursor = decodeCursor(req.query.cursor, scope, true);

  const pool = requirePgPool();
  await ensureCoreSchema(pool);

  const params: unknown[] = [];
  const clauses: string[] = [];
  if (providerId) {
    params.push(providerId);
    clauses.push(`provider_id = $${params.length}`);
  }
  if (cursor) {
    params.push(cursorDate(cursor), cursor.id);
    clauses.push(`(updated_at, id) < ($${params.length - 1}::timestamptz, $${params.length})`);
  }
  const where = clauses.length ? `WHERE ${clauses.join(" AND ")}` : "";
  params.push(size + 1);
  const rowsRes = await pool.query<TicketRow>(
    `SELECT * FROM tickets ${where} ORDER BY updated_at DESC, id DESC LIMIT $${params.length}`,
    params,
  );
  const rows = rowsRes.rows.slice(0, size);
  const last = rows[rows.length - 1];
  res.setHeader("Cache-Control", "private, no-store");
  res.json({
    data: rows.map(serializeTicket),
    nextCursor: rowsRes.rows.length > size && last ? encodeCursor(scope, last.id, last.updated_at) : null,
  });
}));

ticketsRouter.get("/", asyncRoute(async (req, res) => {
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  if (req.user?.superAdmin === true) {
    const rows = await pool.query<TicketRow>(`SELECT * FROM tickets ORDER BY updated_at DESC, id DESC LIMIT 200`);
    return res.json({ data: rows.rows.map(serializeTicket) });
  }
  const providerId = typeof req.user?.providerId === "string" ? req.user.providerId : "";
  if (!providerId) throw new ApiError(403, "Sem permissão para listar tickets.", "permission-denied");
  const rows = await pool.query<TicketRow>(
    `SELECT * FROM tickets WHERE provider_id = $1 ORDER BY updated_at DESC, id DESC LIMIT 200`,
    [providerId],
  );
  res.json({ data: rows.rows.map(serializeTicket) });
}));

ticketsRouter.get("/:id", asyncRoute(async (req, res) => {
  const ticket = await requireTicket(req, req.params.id);
  res.json({ data: serializeTicket(ticket) });
}));

ticketsRouter.post("/", asyncRoute(async (req, res) => {
  const subject = typeof req.body?.subject === "string" ? req.body.subject.trim() : "";
  const message = typeof req.body?.message === "string" ? req.body.message.trim() : "";
  if (!subject || !message) throw new ApiError(400, "Assunto e mensagem são obrigatórios.", "invalid-argument");

  const requestedProvider = typeof req.body?.providerId === "string" ? req.body.providerId.trim() : "";
  const providerId = req.user?.superAdmin === true
    ? requestedProvider
    : String(req.user?.providerId || "").trim();
  if (!providerId || !/^[a-z0-9_-]{1,64}$/i.test(providerId)) {
    throw new ApiError(400, "Provedor obrigatório.", "invalid-argument");
  }
  if (req.user?.superAdmin !== true && requestedProvider && requestedProvider !== providerId) {
    throw new ApiError(403, "Provedor inválido.", "permission-denied");
  }

  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const provider = await getProviderRow(pool, providerId);
  const providerName = (typeof req.body?.providerName === "string" && req.body.providerName.trim()) ||
    provider?.name || providerId;
  const ticketId = randomUUID().replace(/-/g, "").slice(0, 20);
  const msgId = randomUUID().replace(/-/g, "").slice(0, 20);
  const email = typeof req.body?.userEmail === "string" && req.body.userEmail.trim()
    ? req.body.userEmail.trim()
    : req.user?.email || "";

  await pool.query(
    `INSERT INTO tickets (id, provider_id, provider_name, subject, status, created_by_uid, created_by_email, last_message, created_at, updated_at)
     VALUES ($1, $2, $3, $4, 'Aberto', $5, $6, $7, NOW(), NOW())`,
    [ticketId, providerId, providerName, subject.slice(0, 200), req.user!.uid, email, message.slice(0, 2000)],
  );
  await pool.query(
    `INSERT INTO ticket_messages (id, ticket_id, sender_uid, sender_email, sender_role, message, read, created_at)
     VALUES ($1, $2, $3, $4, $5, $6, FALSE, NOW())`,
    [msgId, ticketId, req.user!.uid, email, req.user?.superAdmin ? "superAdmin" : "providerAdmin", message.slice(0, 4000)],
  );
  await recordAdminAudit({ type: "CREATE_TICKET", requesterUid: req.user!.uid, providerId, correlationId: req.correlationId, payload: { ticketId, subject } });
  res.status(201).json({ success: true, ticketId });
}));

ticketsRouter.get("/:id/messages", asyncRoute(async (req, res) => {
  await requireTicket(req, req.params.id);
  const pool = requirePgPool();
  const rows = await pool.query<TicketMessageRow>(
    `SELECT * FROM ticket_messages WHERE ticket_id = $1 ORDER BY created_at ASC`,
    [req.params.id],
  );
  res.json({ data: rows.rows.map(serializeMessage) });
}));

ticketsRouter.patch("/:id", asyncRoute(async (req, res) => {
  const ticket = await requireTicket(req, req.params.id);
  const sets: string[] = ["updated_at = NOW()"];
  const params: unknown[] = [ticket.id];
  const auditPayload: Record<string, unknown> = { ticketId: ticket.id };

  if (req.body?.status !== undefined) {
    if (!["Aberto", "Em Andamento", "Fechado"].includes(req.body.status)) {
      throw new ApiError(400, "Status inválido.", "invalid-argument");
    }
    params.push(req.body.status);
    sets.push(`status = $${params.length}`);
    auditPayload.status = req.body.status;
  }
  if (typeof req.body?.subject === "string" && req.body.subject.trim()) {
    params.push(req.body.subject.trim().slice(0, 200));
    sets.push(`subject = $${params.length}`);
    auditPayload.subject = req.body.subject.trim();
  }

  await requirePgPool().query(`UPDATE tickets SET ${sets.join(", ")} WHERE id = $1`, params);
  await recordAdminAudit({ type: "UPDATE_TICKET", requesterUid: req.user!.uid, providerId: ticket.provider_id, correlationId: req.correlationId, payload: auditPayload });
  res.json({ success: true });
}));

ticketsRouter.post("/:id/reply", asyncRoute(async (req, res) => {
  if (Object.keys(req.body || {}).some((key) => /url|path|attachment|image|owner/i.test(key))) {
    throw new ApiError(400, "Use o endpoint privado de anexos.");
  }
  const ticket = await requireTicket(req, req.params.id);
  const message = typeof req.body?.message === "string" ? req.body.message.trim() : "";
  if (!message) throw new ApiError(400, "Mensagem obrigatória.", "invalid-argument");

  const pool = requirePgPool();
  const msgId = randomUUID().replace(/-/g, "").slice(0, 20);
  await pool.query(
    `INSERT INTO ticket_messages (id, ticket_id, sender_uid, sender_email, sender_role, message, read, created_at)
     VALUES ($1, $2, $3, $4, $5, $6, FALSE, NOW())`,
    [msgId, ticket.id, req.user!.uid, req.user?.email || "", req.user?.superAdmin ? "superAdmin" : "providerAdmin", message.slice(0, 4000)],
  );
  await pool.query(
    `UPDATE tickets SET updated_at = NOW(), status = 'Em Andamento', last_message = $2 WHERE id = $1`,
    [ticket.id, message.slice(0, 2000)],
  );

  await recordAdminAudit({ type: "REPLY_TO_TICKET", requesterUid: req.user!.uid, providerId: ticket.provider_id, correlationId: req.correlationId, payload: { ticketId: ticket.id } });
  void notifyTicketReplyPush({
    providerId: ticket.provider_id,
    ticketId: ticket.id,
    subject: ticket.subject,
    message,
    userId: ticket.created_by_uid,
    cpfCnpj: ticket.cpfcnpj.replace(/\D/g, ""),
  });
  res.json({ success: true });
}));

ticketsRouter.delete("/:id", asyncRoute(async (req, res) => {
  const ticket = await requireTicket(req, req.params.id);
  await requirePgPool().query(`DELETE FROM tickets WHERE id = $1`, [ticket.id]);
  await recordAdminAudit({ type: "DELETE_TICKET", requesterUid: req.user!.uid, providerId: ticket.provider_id, correlationId: req.correlationId, payload: { ticketId: ticket.id } });
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
  const fcm = getMessaging();
  const pool = getPgPool();
  if (!fcm || !pool || !input.providerId || (!input.userId && !input.cpfCnpj)) return;
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
    const resp = await fcm.sendEachForMulticast({
      tokens,
      notification: { title, body: input.message.slice(0, 140) },
      // A resposta aparece em Notificações; não há tela de chamados no app.
      data: { route: "/notificacoes", ticketId: input.ticketId },
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
