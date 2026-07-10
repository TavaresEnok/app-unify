import { FieldValue } from "firebase-admin/firestore";
import type { RequestHandler } from "../app/request";
import { AppError } from "../app/errors";
import { db, messaging } from "../app/firebase";
import { isSuperAdmin, requesterProviderId, requireProviderAccess, requireRequester } from "../app/permissions";

interface PushPayload {
  title: string;
  body: string;
  providerId?: string;
  category?: string;
  targetAll?: boolean;
  targetCpf?: string;
  route?: string;
}

async function sendTokens(tokens: string[], title: string, body: string, data: Record<string, string>) {
  let successCount = 0;
  let failureCount = 0;
  for (let index = 0; index < tokens.length; index += 500) {
    const response = await messaging.sendEachForMulticast({
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

async function sendPush(requesterUid: string, payload: PushPayload) {
  const requester = await requireRequester(requesterUid);
  const providerId = payload.providerId || requesterProviderId(requester);
  if (!providerId && !isSuperAdmin(requester)) throw new AppError("invalid-argument", "ProviderID obrigatório.");
  if (providerId) await requireProviderAccess(requesterUid, providerId);
  const title = payload.title.trim();
  const body = payload.body.trim();
  if (!title || !body) throw new AppError("invalid-argument", "Título e mensagem são obrigatórios.");

  let counts = { successCount: 0, failureCount: 0 };
  const data = { route: payload.route || "", category: payload.category || "info" };
  if (payload.targetCpf) {
    let client = await db.collection("clientes").doc(payload.targetCpf).get();
    if (!client.exists) {
      const matches = await db.collection("clientes").where("cpfCnpj", "==", payload.targetCpf).limit(1).get();
      client = matches.docs[0];
    }
    if (!client?.exists || (providerId && client.data()?.providerId !== providerId)) {
      throw new AppError("not-found", "Cliente não encontrado.");
    }
    const token = client.data()?.fcmToken;
    if (typeof token === "string" && token) counts = await sendTokens([token], title, body, data);
  } else if (payload.targetAll && providerId) {
    await messaging.send({
      topic: `provider_${providerId}`,
      notification: { title, body },
      data,
      android: { priority: "high", notification: { channelId: "high_importance_channel", priority: "high" } },
    });
    counts.successCount = 1;
  } else if (providerId) {
    const clients = await db.collection("clientes").where("providerId", "==", providerId).get();
    const tokens = clients.docs.map((client) => client.data().fcmToken).filter((token): token is string => typeof token === "string" && !!token);
    counts = await sendTokens(tokens, title, body, data);
  }

  await db.collection("notifications").add({
    providerId: providerId || null,
    title,
    body,
    category: payload.category || "info",
    targetAll: !!payload.targetAll,
    targetCpf: payload.targetCpf || null,
    ...counts,
    sentBy: requesterUid,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { success: true, message: `Notificação enviada: ${counts.successCount} entrega(s), ${counts.failureCount} falha(s).` };
}

export const sendPushNotification: RequestHandler<"SEND_PUSH_NOTIFICATION"> = async ({ requesterUid, payload }) => {
  return sendPush(requesterUid, payload);
};

export const sendScopedNotification: RequestHandler<"SEND_SCOPED_NOTIFICATION"> = async ({ requesterUid, payload }) => {
  return sendPush(requesterUid, payload);
};

export const sendSegmentedNotification: RequestHandler<"SEND_SCOPED_NOTIFICATION_SEGMENTED"> = async ({ requesterUid, payload }) => {
  if (!payload.providerId) throw new AppError("invalid-argument", "ProviderID obrigatório.");
  await requireProviderAccess(requesterUid, payload.providerId);
  const title = payload.title.trim();
  const body = payload.body.trim();
  if (!title || !body) throw new AppError("invalid-argument", "Título e mensagem são obrigatórios.");

  const clients = await db.collection("clientes").where("providerId", "==", payload.providerId).get();
  const tokens = clients.docs.flatMap((client) => {
    const data = client.data();
    const token = data.fcmToken;
    if (typeof token !== "string" || !token) return [];
    if (payload.statusFilter && payload.statusFilter !== "all" &&
      !String(data.status || "").toLowerCase().includes(payload.statusFilter.toLowerCase())) return [];
    if (payload.planFilter && payload.planFilter !== "all" &&
      !String(data.plano || data.plan || "").toLowerCase().includes(payload.planFilter.toLowerCase())) return [];
    return [token];
  });
  const counts = await sendTokens(tokens, title, body, { route: "/provedor/dashboard", category: "segmented" });
  await db.collection("notifications").add({
    providerId: payload.providerId,
    title,
    body,
    category: "segmented",
    statusFilter: payload.statusFilter || "all",
    planFilter: payload.planFilter || "all",
    ...counts,
    sentBy: requesterUid,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { success: true, message: `Notificação enviada: ${counts.successCount} entrega(s), ${counts.failureCount} falha(s).` };
};
