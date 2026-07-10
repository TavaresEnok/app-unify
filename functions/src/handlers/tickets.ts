import { FieldValue } from "firebase-admin/firestore";
import type { TicketStatus } from "../contracts";
import type { RequestHandler } from "../app/request";
import { AppError } from "../app/errors";
import { db } from "../app/firebase";
import {
  isSuperAdmin,
  requesterProviderId,
  requireProviderAccess,
  requireRequester,
  requireSuperAdmin,
} from "../app/permissions";
import { isValidTicketStatus } from "../utils";

function serialize(doc: FirebaseFirestore.QueryDocumentSnapshot): Record<string, unknown> {
  return { id: doc.id, ...doc.data() };
}

async function requireTicketAccess(requesterUid: string, ticketId: string) {
  const [user, ticket] = await Promise.all([
    requireRequester(requesterUid),
    db.collection("tickets").doc(ticketId).get(),
  ]);
  if (!ticket.exists) throw new AppError("not-found", "Ticket não encontrado.");
  const data = ticket.data() || {};
  const allowed = isSuperAdmin(user) || requesterProviderId(user) === data.providerId || data.createdByUid === requesterUid;
  if (!allowed) throw new AppError("permission-denied", "Permissão negada para este ticket.");
  return { user, ticket, data };
}

export const getAllTickets: RequestHandler<"GET_ALL_TICKETS"> = async ({ requesterUid }) => {
  await requireSuperAdmin(requesterUid);
  const snapshot = await db.collection("tickets").orderBy("updatedAt", "desc").get();
  return snapshot.docs.map(serialize);
};

export const getProviderTickets: RequestHandler<"GET_PROVIDER_TICKETS"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  const snapshot = await db.collection("tickets")
    .where("providerId", "==", payload.providerId)
    .orderBy("updatedAt", "desc")
    .get();
  return snapshot.docs.map(serialize);
};

export const createTicket: RequestHandler<"CREATE_TICKET"> = async ({ requestId, requesterUid, payload }) => {
  const user = await requireRequester(requesterUid);
  const claimedProvider = requesterProviderId(user);
  if (!isSuperAdmin(user) && claimedProvider && claimedProvider !== payload.providerId) {
    throw new AppError("permission-denied", "Permissão negada para este provedor.");
  }
  if (!isSuperAdmin(user) && !claimedProvider) {
    const client = await db.collection("clientes").doc(requesterUid).get();
    if (!client.exists || client.data()?.providerId !== payload.providerId) {
      throw new AppError("permission-denied", "Cliente não associado a este provedor.");
    }
  }
  if (!payload.subject.trim() || !payload.message.trim()) {
    throw new AppError("invalid-argument", "Assunto e mensagem são obrigatórios.");
  }

  const ticketRef = db.collection("tickets").doc(requestId);
  const now = FieldValue.serverTimestamp();
  await ticketRef.set({
    subject: payload.subject.trim(),
    status: "Aberto" satisfies TicketStatus,
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
    senderRole: isSuperAdmin(user) ? "superAdmin" : (claimedProvider ? "providerAdmin" : "client"),
    imageUrl: payload.imageUrl || null,
    createdAt: now,
  });
  return { success: true, message: "Ticket criado com sucesso.", ticketId: ticketRef.id };
};

export const replyToTicket: RequestHandler<"REPLY_TO_TICKET"> = async ({ requesterUid, payload }) => {
  const { user, ticket } = await requireTicketAccess(requesterUid, payload.ticketId);
  if (!payload.message.trim()) throw new AppError("invalid-argument", "A mensagem é obrigatória.");
  const now = FieldValue.serverTimestamp();
  await Promise.all([
    ticket.ref.collection("messages").add({
      message: payload.message.trim(),
      senderUid: requesterUid,
      senderEmail: user.email || "",
      senderRole: isSuperAdmin(user) ? "superAdmin" : (requesterProviderId(user) ? "providerAdmin" : "client"),
      imageUrl: payload.imageUrl || null,
      createdAt: now,
    }),
    ticket.ref.set({ updatedAt: now }, { merge: true }),
  ]);
  return { success: true, message: "Resposta enviada." };
};

export const updateTicketStatus: RequestHandler<"UPDATE_TICKET_STATUS"> = async ({ requesterUid, payload }) => {
  const { user, ticket, data } = await requireTicketAccess(requesterUid, payload.ticketId);
  if (!isSuperAdmin(user) && requesterProviderId(user) !== data.providerId) {
    throw new AppError("permission-denied", "Apenas administradores podem alterar o status.");
  }
  if (!isValidTicketStatus(payload.status)) throw new AppError("invalid-argument", "Status inválido.");
  await ticket.ref.set({ status: payload.status, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  return { success: true, message: "Status atualizado." };
};

export const deleteTicket: RequestHandler<"DELETE_TICKET"> = async ({ requesterUid, payload }) => {
  await requireSuperAdmin(requesterUid);
  const ref = db.collection("tickets").doc(payload.ticketId);
  if (!(await ref.get()).exists) return { success: true, message: "Ticket apagado." };
  await db.recursiveDelete(ref);
  return { success: true, message: "Ticket apagado." };
};
