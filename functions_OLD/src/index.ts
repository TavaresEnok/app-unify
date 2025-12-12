import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import * as logger from "firebase-functions/logger";
import cors from "cors";

const corsHandler = cors({ origin: true });

initializeApp();
const db = getFirestore();
const auth = getAuth();

const getDecodedToken = async (request: any, response: any): Promise<any> => {
  if (!request.headers.authorization || !request.headers.authorization.startsWith("Bearer ")) {
    response.status(403).send({ error: "Unauthorized" });
    return null;
  }
  const idToken = request.headers.authorization.split("Bearer ")[1];
  try {
    return await auth.verifyIdToken(idToken);
  } catch (error) {
    logger.error("Token inválido:", error);
    response.status(403).send({ error: "Token inválido." });
    return null;
  }
};

const verifySuperAdmin = (decodedToken: any, response: any): boolean => {
  if (decodedToken.superAdmin !== true) {
    response.status(403).send({ error: "Apenas Super Admins podem executar esta ação." });
    return false;
  }
  return true;
};

// --- FUNÇÕES DA APLICAÇÃO ---

export const getDashboardData = onRequest({ region: "southamerica-east1" }, (request, response) => {
  corsHandler(request, response, async () => {
    const decodedToken = await getDecodedToken(request, response);
    if (!decodedToken || !verifySuperAdmin(decodedToken, response)) return;
    try {
      const providerCount = (await db.collection("provedores").count().get()).data().count;
      const clientCount = (await db.collection("clientes").count().get()).data().count;
      const oneDayAgo = Timestamp.now().toMillis() - (24 * 60 * 60 * 1000);
      const notificationsQuery = db.collection("sent_notifications").where("sentAt", ">=", new Date(oneDayAgo));
      const notificationCount = (await notificationsQuery.count().get()).data().count;

      const providersSnapshot = await db.collection("provedores").get();
      const chartData = [];
      for (const doc of providersSnapshot.docs) {
        const clientQuery = db.collection("clientes").where("providerId", "==", doc.id);
        const count = (await clientQuery.count().get()).data().count;
        chartData.push({ name: doc.data().name, clientes: count });
      }

      response.json({ data: { stats: { providerCount, clientCount, notificationCount }, chartData } });
    } catch (error) {
      response.status(500).send({ error: "Erro ao buscar dados do dashboard." });
    }
  });
});

export const listAdminUsers = onRequest({ region: "southamerica-east1" }, (request, response) => {
  corsHandler(request, response, async () => {
    const decodedToken = await getDecodedToken(request, response);
    if (!decodedToken || !verifySuperAdmin(decodedToken, response)) return;
    try {
      const listUsersResult = await auth.listUsers(1000);
      const users = listUsersResult.users.map((user) => ({
        uid: user.uid, email: user.email,
        superAdmin: user.customClaims?.superAdmin === true,
        providerId: user.customClaims?.providerId || null,
      }));
      response.json({ data: { users } });
    } catch (error) {
      response.status(500).send({ error: "Erro ao listar utilizadores." });
    }
  });
});

export const createAdminUser = onRequest({ region: "southamerica-east1" }, (request, response) => {
  corsHandler(request, response, async () => {
    const decodedToken = await getDecodedToken(request, response);
    if (!decodedToken || !verifySuperAdmin(decodedToken, response)) return;

    const { email, password, role, providerId } = request.body.data;
    if (!email || !password || !role) {
      response.status(400).send({ error: "Email, senha e permissão são obrigatórios." });
      return;
    }
    if (role === "providerAdmin" && !providerId) {
      response.status(400).send({ error: "É necessário selecionar um provedor." });
      return;
    }

    try {
      const userRecord = await auth.createUser({ email, password });
      let claims = {};
      if (role === "superAdmin") {
        claims = { superAdmin: true };
      } else {
        claims = { providerId: providerId };
      }
      await auth.setCustomUserClaims(userRecord.uid, claims);
      response.json({ data: { message: `Utilizador ${email} criado com sucesso.` } });
    } catch (error: any) {
      response.status(500).send({ error: error.message });
    }
  });
});

export const createProvider = onRequest({ region: "southamerica-east1" }, (request, response) => {
  corsHandler(request, response, async () => {
    const decodedToken = await getDecodedToken(request, response);
    if (!decodedToken || !verifySuperAdmin(decodedToken, response)) return;
    const { providerId, name } = request.body.data;
    if (!providerId || !name) {
      response.status(400).send({ error: "ID e Nome são obrigatórios." });
      return;
    }
    try {
      const ref = db.collection("provedores").doc(providerId);
      if ((await ref.get()).exists) {
        response.status(409).send({ error: `ID '${providerId}' já existe.` });
        return;
      }
      await ref.set({ name });
      response.json({ data: { message: `Provedor '${name}' criado.` } });
    } catch (error) {
      response.status(500).send({ error: "Erro ao criar provedor." });
    }
  });
});

export const updateProviderConfig = onRequest({ region: "southamerica-east1" }, (request, response) => {
  corsHandler(request, response, async () => {
    const decodedToken = await getDecodedToken(request, response);
    if (!decodedToken || !verifySuperAdmin(decodedToken, response)) return;
    const { providerId, config } = request.body.data;
    if (!providerId || !config) {
      response.status(400).send({ error: "ID do provedor e config são obrigatórios." });
      return;
    }
    try {
      const providerRef = db.collection("provedores").doc(providerId);
      await providerRef.set({ config }, { merge: true });
      response.json({ data: { message: `Configurações do provedor '${providerId}' atualizadas.` } });
    } catch (error) {
      response.status(500).send({ error: "Erro ao atualizar configuração." });
    }
  });
});

export const deleteProvider = onRequest({ region: "southamerica-east1" }, (request, response) => {
  corsHandler(request, response, async () => {
    const decodedToken = await getDecodedToken(request, response);
    if (!decodedToken || !verifySuperAdmin(decodedToken, response)) return;
    const { providerId } = request.body.data;
    if (!providerId) {
      response.status(400).send({ error: "ID do provedor é obrigatório." });
      return;
    }
    try {
      await db.collection("provedores").doc(providerId).delete();
      response.json({ data: { message: "Provedor apagado." } });
    } catch (error) {
      response.status(500).send({ error: "Erro ao apagar provedor." });
    }
  });
});
