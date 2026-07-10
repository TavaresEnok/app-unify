"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setSuperAdminByEmail = exports.deleteAdminUser = exports.createAdminUser = exports.listAdminUsers = void 0;
const firestore_1 = require("firebase-admin/firestore");
const errors_1 = require("../app/errors");
const firebase_1 = require("../app/firebase");
const permissions_1 = require("../app/permissions");
function validatePassword(password) {
    if (password.length < 12 || !/[A-Z]/.test(password) || !/[a-z]/.test(password) ||
        !/[0-9]/.test(password) || !/[^A-Za-z0-9]/.test(password)) {
        throw new errors_1.AppError("invalid-argument", "A senha não atende à política de segurança.");
    }
}
const listAdminUsers = async ({ requesterUid }) => {
    await (0, permissions_1.requireSuperAdmin)(requesterUid);
    const result = await firebase_1.auth.listUsers(1000);
    return result.users
        .filter((user) => { var _a, _b; return ((_a = user.customClaims) === null || _a === void 0 ? void 0 : _a.superAdmin) || ((_b = user.customClaims) === null || _b === void 0 ? void 0 : _b.providerId); })
        .map((user) => {
        var _a, _b;
        return ({
            uid: user.uid,
            email: user.email,
            superAdmin: ((_a = user.customClaims) === null || _a === void 0 ? void 0 : _a.superAdmin) === true,
            providerId: typeof ((_b = user.customClaims) === null || _b === void 0 ? void 0 : _b.providerId) === "string" ? user.customClaims.providerId : undefined,
        });
    });
};
exports.listAdminUsers = listAdminUsers;
const createAdminUser = async ({ requestId, requesterUid, payload }) => {
    var _a;
    await (0, permissions_1.requireSuperAdmin)(requesterUid);
    const email = payload.email.trim().toLowerCase();
    if (!email.includes("@"))
        throw new errors_1.AppError("invalid-argument", "Email inválido.");
    validatePassword(payload.password);
    if (payload.role === "providerAdmin" && !payload.providerId) {
        throw new errors_1.AppError("invalid-argument", "O provedor é obrigatório para este perfil.");
    }
    try {
        const existing = await firebase_1.auth.getUserByEmail(email);
        const metadata = await firebase_1.db.collection("users").doc(existing.uid).get();
        if (((_a = metadata.data()) === null || _a === void 0 ? void 0 : _a.createdByRequestId) === requestId) {
            return { success: true, message: "Utilizador criado com sucesso.", uid: existing.uid };
        }
        throw new errors_1.AppError("conflict", "Já existe um utilizador com este email.");
    }
    catch (error) {
        if (error instanceof errors_1.AppError)
            throw error;
        const code = error.code;
        if (code !== "auth/user-not-found")
            throw error;
    }
    const user = await firebase_1.auth.createUser({ email, password: payload.password, emailVerified: false });
    try {
        const claims = payload.role === "superAdmin"
            ? { superAdmin: true, role: "superAdmin" }
            : { providerId: payload.providerId, role: "providerAdmin" };
        await firebase_1.auth.setCustomUserClaims(user.uid, claims);
        await firebase_1.db.collection("users").doc(user.uid).set(Object.assign(Object.assign({ email }, claims), { createdAt: firestore_1.FieldValue.serverTimestamp(), createdBy: requesterUid, createdByRequestId: requestId }));
    }
    catch (error) {
        await firebase_1.auth.deleteUser(user.uid).catch(() => undefined);
        throw error;
    }
    return { success: true, message: "Utilizador criado com sucesso.", uid: user.uid };
};
exports.createAdminUser = createAdminUser;
const deleteAdminUser = async ({ requesterUid, payload }) => {
    await (0, permissions_1.requireSuperAdmin)(requesterUid);
    if (requesterUid === payload.uid)
        throw new errors_1.AppError("invalid-argument", "Você não pode apagar sua própria conta.");
    await Promise.all([
        firebase_1.auth.deleteUser(payload.uid).catch((error) => {
            if (error.code !== "auth/user-not-found")
                throw error;
        }),
        firebase_1.db.collection("users").doc(payload.uid).delete(),
    ]);
    return { success: true, message: "Utilizador apagado." };
};
exports.deleteAdminUser = deleteAdminUser;
const setSuperAdminByEmail = async ({ requesterUid, payload }) => {
    await (0, permissions_1.requireSuperAdmin)(requesterUid);
    let target;
    try {
        target = await firebase_1.auth.getUserByEmail(payload.email.trim().toLowerCase());
    }
    catch (_a) {
        throw new errors_1.AppError("not-found", "Utilizador não encontrado.");
    }
    await firebase_1.auth.setCustomUserClaims(target.uid, Object.assign(Object.assign({}, (target.customClaims || {})), { superAdmin: true, role: "superAdmin" }));
    await firebase_1.db.collection("users").doc(target.uid).set({
        email: target.email,
        superAdmin: true,
        role: "superAdmin",
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { success: true, message: "Permissão de Super Admin concedida.", uid: target.uid };
};
exports.setSuperAdminByEmail = setSuperAdminByEmail;
//# sourceMappingURL=users.js.map