import { firestore } from '../firebase-admin';
/**
 * Helper de Auto-Inicialização
 * Garante que schemas existam no Firestore automaticamente
 */
export async function ensureNotificationsSchema(providerId: string) {
  const docRef = firestore.collection('provedores').doc(providerId);
  const doc = await docRef.get();
  if (!doc.exists) {
    console.warn(`⚠️  Provedor ${providerId} não encontrado`);
    return false;
  }
  const data = doc.data();
  // Se schema já existe, retornar
  if (data?.inAppNotifications) {
    return true;
  }
  // Criar schema automaticamente
  console.log(`🔥 Auto-criando schema de notificações para: ${providerId}`);
  await docRef.update({
    inAppNotifications: {
      enabled: true,
      notifications: [
        {
          id: `welcome_${Date.now()}`,
          type: 'info',
          title: 'Bem-vindo!',
          message: 'Sistema de notificações ativado automaticamente.',
          createdAt: new Date().toISOString(),
          read: false,
        },
      ],
    },
  });
  console.log(`✅ Schema criado automaticamente!`);
  return true;
}
export async function ensureAllSchemas(providerId: string) {
  const docRef = firestore.collection('provedores').doc(providerId);
  const doc = await docRef.get();
  if (!doc.exists) {
    console.warn(`⚠️  Provedor ${providerId} não encontrado`);
    return false;
  }
  const data = doc.data() || {};
  const updates: any = {};
  // 1. Notifications
  if (!data.inAppNotifications) {
    updates.inAppNotifications = {
      enabled: true,
      notifications: [
        {
          id: `welcome_${Date.now()}`,
          type: 'info',
          title: 'Bem-vindo!',
          message: 'Sistema de notificações ativado.',
          createdAt: new Date().toISOString(),
          read: false,
        },
      ],
    };
  }
  // 2. Theme (se não existir)
  if (!data.theme) {
    updates.theme = {
      primaryColor: '#673AB7',
      secondaryColor: '#9575CD',
      mode: 'light',
    };
  }
  // 3. AppVersion (se não existir)
  if (!data.appVersion) {
    updates.appVersion = {
      enabled: false,
      minVersion: '1.0.0',
      latestVersion: '1.0.0',
      forceUpdate: false,
    };
  }
  // Aplicar atualizações se houver
  if (Object.keys(updates).length > 0) {
    console.log(`🔥 Auto-criando ${Object.keys(updates).length} schemas para: ${providerId}`);
    await docRef.update(updates);
    console.log(`✅ Schemas criados automaticamente!`);
  }
  return true;
}
