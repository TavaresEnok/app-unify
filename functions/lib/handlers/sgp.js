"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sgpApiProxy = void 0;
const firestore_1 = require("firebase-admin/firestore");
const errors_1 = require("../app/errors");
const config_1 = require("../app/config");
const firebase_1 = require("../app/firebase");
const permissions_1 = require("../app/permissions");
const SENSITIVE_KEYS = new Set(["contratocentralsenha", "senha", "password", "token", "apitoken", "authorization", "secret"]);
function sanitizeContracts(value) {
    if (!Array.isArray(value))
        return [];
    return value.map((contract) => {
        if (!contract || typeof contract !== "object")
            return contract;
        const output = {};
        for (const [key, next] of Object.entries(contract)) {
            if (!SENSITIVE_KEYS.has(key.toLowerCase()))
                output[key] = next;
        }
        return output;
    });
}
async function postProxy(path, body, timeoutMs = 30000) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);
    try {
        const response = await fetch(`${config_1.proxyUrlSecret.value()}${path}`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(body),
            signal: controller.signal,
        });
        const text = await response.text();
        let data;
        try {
            data = text ? JSON.parse(text) : {};
        }
        catch (_a) {
            data = { raw: text };
        }
        if (!response.ok)
            throw new errors_1.AppError("internal", `Proxy SGP respondeu ${response.status}.`);
        return data;
    }
    finally {
        clearTimeout(timeout);
    }
}
async function credentials(providerId) {
    var _a, _b, _c, _d;
    const providerRef = firebase_1.db.collection("provedores").doc(providerId);
    const [provider, secret] = await Promise.all([
        providerRef.get(),
        providerRef.collection("secrets").doc("sgp").get(),
    ]);
    if (!provider.exists)
        throw new errors_1.AppError("not-found", "Provedor não encontrado.");
    const data = provider.data() || {};
    const integrations = ((_a = secret.data()) === null || _a === void 0 ? void 0 : _a.integrations) || data.integrations || {};
    const result = {
        url: integrations.sgpBaseUrl || ((_b = data.details) === null || _b === void 0 ? void 0 : _b.systemUrl) || data.sgpBaseUrl,
        token: integrations.apiToken || ((_c = data.details) === null || _c === void 0 ? void 0 : _c.apiToken) || data.apiToken,
        app: integrations.appName || ((_d = data.details) === null || _d === void 0 ? void 0 : _d.appName) || data.appName || "APP-PROVEDOR",
    };
    if (!result.url || !result.token)
        throw new errors_1.AppError("invalid-argument", "Configurações do SGP incompletas.");
    if (!config_1.proxyUrlSecret.value() || !config_1.proxySecretParam.value())
        throw new errors_1.AppError("internal", "Proxy SGP não configurado.");
    return result;
}
const sgpApiProxy = async ({ requesterUid, payload }) => {
    var _a, _b, _c, _d;
    await (0, permissions_1.requireProviderAccess)(requesterUid, payload.providerId);
    const config = await credentials(payload.providerId);
    const clientsRef = firebase_1.db.collection("provedores").doc(payload.providerId).collection("clientes");
    if (payload.action === "get") {
        const limit = Math.min(Math.max(Number((_a = payload.params) === null || _a === void 0 ? void 0 : _a.limit) || 25, 1), 100);
        const offset = Math.max(Number((_b = payload.params) === null || _b === void 0 ? void 0 : _b.offset) || 0, 0);
        const searchTerm = String(((_c = payload.params) === null || _c === void 0 ? void 0 : _c.searchTerm) || "").trim();
        let query = clientsRef;
        if (searchTerm)
            query = query.where("nome", ">=", searchTerm).where("nome", "<=", `${searchTerm}\uf8ff`);
        query = query.orderBy("nome").offset(offset).limit(limit);
        const [snapshot, count] = await Promise.all([query.get(), clientsRef.count().get()]);
        return {
            clientes: snapshot.docs.map((client) => (Object.assign(Object.assign({}, client.data()), { contratos: sanitizeContracts(client.data().contratos) }))),
            paginacao: { total: count.data().count, limit, offset },
        };
    }
    if (payload.action === "get_single") {
        const clientId = String(((_d = payload.params) === null || _d === void 0 ? void 0 : _d.clientId) || "");
        if (!clientId)
            throw new errors_1.AppError("invalid-argument", "ClientID obrigatório.");
        let snapshot = await clientsRef.where("id", "==", Number(clientId)).limit(1).get();
        if (snapshot.empty)
            snapshot = await clientsRef.where("id", "==", clientId).limit(1).get();
        if (snapshot.empty)
            throw new errors_1.AppError("not-found", "Cliente não encontrado.");
        const data = snapshot.docs[0].data();
        return Object.assign(Object.assign({}, data), { contratos: sanitizeContracts(data.contratos) });
    }
    await postProxy("/sync-clients", {
        secret: config_1.proxySecretParam.value(),
        providerId: payload.providerId,
        sgpBaseUrl: config.url,
        params: { token: config.token, app: config.app },
    }, 5 * 60000);
    let offset = 0;
    let total = 0;
    const pageSize = 100;
    while (true) {
        const page = await postProxy("/get-cached-clients", {
            secret: config_1.proxySecretParam.value(),
            providerId: payload.providerId,
            params: { limit: pageSize, offset },
        });
        const clients = Array.isArray(page.clientes) ? page.clientes : [];
        if (!clients.length)
            break;
        for (let start = 0; start < clients.length; start += 400) {
            const batch = firebase_1.db.batch();
            for (const client of clients.slice(start, start + 400)) {
                const cpf = String(client.cpfcnpj || "").replace(/\D/g, "");
                if (!cpf)
                    continue;
                batch.set(clientsRef.doc(cpf), Object.assign(Object.assign({}, client), { contratos: sanitizeContracts(client.contratos), providerId: payload.providerId, updatedAt: firestore_1.FieldValue.serverTimestamp() }), { merge: true });
            }
            await batch.commit();
        }
        total += clients.length;
        if (clients.length < pageSize)
            break;
        offset += pageSize;
    }
    return { count: total, message: `Sincronização concluída: ${total} clientes atualizados.` };
};
exports.sgpApiProxy = sgpApiProxy;
//# sourceMappingURL=sgp.js.map