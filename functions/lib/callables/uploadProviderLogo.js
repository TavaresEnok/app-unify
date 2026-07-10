"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.uploadProviderLogo = void 0;
const https_1 = require("firebase-functions/v2/https");
const logger = __importStar(require("firebase-functions/logger"));
const firebase_1 = require("../app/firebase");
const permissions_1 = require("../app/permissions");
const MAX_LOGO_BYTES = 5 * 1024 * 1024;
exports.uploadProviderLogo = (0, https_1.onCall)({
    region: "southamerica-east1",
    maxInstances: 10,
}, async (request) => {
    var _a, _b;
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Utilizador não autenticado.");
    const providerId = typeof ((_a = request.data) === null || _a === void 0 ? void 0 : _a.providerId) === "string" ? request.data.providerId : "";
    const imageBase64 = typeof ((_b = request.data) === null || _b === void 0 ? void 0 : _b.imageBase64) === "string" ? request.data.imageBase64 : "";
    if (!providerId || !imageBase64)
        throw new https_1.HttpsError("invalid-argument", "Imagem e ProviderID são obrigatórios.");
    try {
        await (0, permissions_1.requireProviderAccess)(request.auth.uid, providerId);
        const match = imageBase64.match(/^data:image\/(png|jpeg|webp);base64,([\s\S]+)$/);
        if (!match)
            throw new https_1.HttpsError("invalid-argument", "Formato de imagem inválido.");
        const extension = match[1] === "jpeg" ? "jpg" : match[1];
        const buffer = Buffer.from(match[2], "base64");
        if (!buffer.length || buffer.length > MAX_LOGO_BYTES) {
            throw new https_1.HttpsError("invalid-argument", "A imagem deve ter no máximo 5 MB.");
        }
        const bucket = firebase_1.storage.bucket();
        const filePath = `providers/${providerId}/logo.${extension}`;
        await bucket.file(filePath).save(buffer, {
            metadata: {
                contentType: `image/${match[1]}`,
                cacheControl: "public, max-age=31536000, immutable",
            },
        });
        const url = `https://storage.googleapis.com/${bucket.name}/${filePath}`;
        await firebase_1.db.collection("provedores").doc(providerId).set({ logoUrl: url }, { merge: true });
        return { success: true, url };
    }
    catch (error) {
        if (error instanceof https_1.HttpsError)
            throw error;
        const message = error instanceof Error ? error.message : "Falha ao enviar a imagem.";
        logger.error("Logo upload failed", { providerId, requesterUid: request.auth.uid, error: message });
        if (message.toLowerCase().includes("permiss"))
            throw new https_1.HttpsError("permission-denied", message);
        throw new https_1.HttpsError("internal", message);
    }
});
//# sourceMappingURL=uploadProviderLogo.js.map