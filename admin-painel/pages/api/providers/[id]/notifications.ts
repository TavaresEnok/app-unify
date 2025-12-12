import type { NextApiRequest, NextApiResponse } from 'next';
import { firestore } from '../../../../lib/firebase-admin';
import { ensureNotificationsSchema } from '../../../../lib/firestore/auto-init';
export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  const { id: providerId } = req.query;
  if (!providerId || typeof providerId !== 'string') {
    return res.status(400).json({ error: 'Provider ID inválido' });
  }
  try {
    switch (req.method) {
      case 'GET':
        return await handleGet(providerId, res);
      case 'POST':
        return await handlePost(providerId, req.body, res);
      case 'PUT':
        return await handlePut(providerId, req.body, res);
      case 'DELETE':
        return await handleDelete(providerId, req.body, res);
      default:
        res.setHeader('Allow', ['GET', 'POST', 'PUT', 'DELETE']);
        return res.status(405).end(`Method ${req.method} Not Allowed`);
    }
  } catch (error) {
    console.error('Erro na API de notificações:', error);
    return res.status(500).json({ error: 'Erro interno do servidor' });
  }
}
async function handleGet(providerId: string, res: NextApiResponse) {
  // 🔥 LAZY INIT: Garantir que schema existe
  await ensureNotificationsSchema(providerId);
  const doc = await firestore.collection('provedores').doc(providerId).get();
  if (!doc.exists) {
    return res.status(404).json({ error: 'Provedor não encontrado' });
  }
  const data = doc.data();
  const notifications = data?.inAppNotifications || {
    enabled: false,
    notifications: [],
  };
  return res.status(200).json(notifications);
}
async function handlePost(providerId: string, body: any, res: NextApiResponse) {
  // 🔥 LAZY INIT
  await ensureNotificationsSchema(providerId);
  const { notification } = body;
  if (!notification || !notification.title || !notification.message || !notification.type) {
    return res.status(400).json({
      error: 'Título, mensagem e tipo são obrigatórios',
    });
  }
  const newNotification = {
    ...notification,
    id: notification.id || `notif_${Date.now()}`,
    createdAt: new Date().toISOString(),
    read: false,
  };
  const docRef = firestore.collection('provedores').doc(providerId);
  const doc = await docRef.get();
  if (!doc.exists) {
    return res.status(404).json({ error: 'Provedor não encontrado' });
  }
  const data = doc.data();
  const currentNotifications = data?.inAppNotifications?.notifications || [];
  await docRef.update({
    'inAppNotifications.notifications': [...currentNotifications, newNotification],
    'inAppNotifications.enabled': true,
  });
  return res.status(201).json({
    message: 'Notificação criada com sucesso',
    notification: newNotification,
  });
}
async function handlePut(providerId: string, body: any, res: NextApiResponse) {
  await ensureNotificationsSchema(providerId);
  const { notificationId, updates } = body;
  if (!notificationId || !updates) {
    return res.status(400).json({ error: 'ID e updates são obrigatórios' });
  }
  const docRef = firestore.collection('provedores').doc(providerId);
  const doc = await docRef.get();
  if (!doc.exists) {
    return res.status(404).json({ error: 'Provedor não encontrado' });
  }
  const data = doc.data();
  const notifications = data?.inAppNotifications?.notifications || [];
  const index = notifications.findIndex((n: any) => n.id === notificationId);
  if (index === -1) {
    return res.status(404).json({ error: 'Notificação não encontrada' });
  }
  notifications[index] = { ...notifications[index], ...updates };
  await docRef.update({
    'inAppNotifications.notifications': notifications,
  });
  return res.status(200).json({
    message: 'Notificação atualizada com sucesso',
    notification: notifications[index],
  });
}
async function handleDelete(providerId: string, body: any, res: NextApiResponse) {
  await ensureNotificationsSchema(providerId);
  const { notificationId } = body;
  if (!notificationId) {
    return res.status(400).json({ error: 'ID da notificação é obrigatório' });
  }
  const docRef = firestore.collection('provedores').doc(providerId);
  const doc = await docRef.get();
  if (!doc.exists) {
    return res.status(404).json({ error: 'Provedor não encontrado' });
  }
  const data = doc.data();
  const notifications = data?.inAppNotifications?.notifications || [];
  const filtered = notifications.filter((n: any) => n.id !== notificationId);
  await docRef.update({
    'inAppNotifications.notifications': filtered,
  });
  return res.status(200).json({
    message: 'Notificação removida com sucesso',
  });
}
