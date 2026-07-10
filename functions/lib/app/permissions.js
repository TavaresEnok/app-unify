"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireRequester = requireRequester;
exports.isSuperAdmin = isSuperAdmin;
exports.requesterProviderId = requesterProviderId;
exports.requireSuperAdmin = requireSuperAdmin;
exports.requireProviderAccess = requireProviderAccess;
const firebase_1 = require("./firebase");
const errors_1 = require("./errors");
async function requireRequester(requesterUid) {
    if (!requesterUid)
        throw new errors_1.AppError("unauthenticated", "RequesterUID é obrigatório.");
    try {
        return await firebase_1.auth.getUser(requesterUid);
    }
    catch (_a) {
        throw new errors_1.AppError("unauthenticated", "Utilizador não encontrado.");
    }
}
function isSuperAdmin(user) {
    var _a;
    return ((_a = user.customClaims) === null || _a === void 0 ? void 0 : _a.superAdmin) === true;
}
function requesterProviderId(user) {
    var _a;
    const value = (_a = user.customClaims) === null || _a === void 0 ? void 0 : _a.providerId;
    return typeof value === "string" ? value : undefined;
}
async function requireSuperAdmin(requesterUid) {
    const user = await requireRequester(requesterUid);
    if (!isSuperAdmin(user)) {
        throw new errors_1.AppError("permission-denied", "Permissão negada. Apenas Super Admin.");
    }
    return user;
}
async function requireProviderAccess(requesterUid, providerId) {
    const user = await requireRequester(requesterUid);
    if (!isSuperAdmin(user) && requesterProviderId(user) !== providerId) {
        throw new errors_1.AppError("permission-denied", "Permissão negada para este provedor.");
    }
    return user;
}
//# sourceMappingURL=permissions.js.map