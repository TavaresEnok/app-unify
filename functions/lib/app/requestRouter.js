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
exports.createRequestRouter = createRequestRouter;
const logger = __importStar(require("firebase-functions/logger"));
const contracts_1 = require("../contracts");
const errors_1 = require("./errors");
const request_1 = require("./request");
const writeResponse_1 = require("./writeResponse");
const audit_1 = require("./audit");
const firebase_1 = require("./firebase");
function createRequestRouter(registry) {
    return async (requestId, rawRequest) => {
        if ((await firebase_1.db.collection("function_responses").doc(requestId).get()).exists) {
            logger.info("Function request already completed", { requestId });
            return;
        }
        let request;
        try {
            const normalized = (0, contracts_1.isRecord)(rawRequest) && (0, contracts_1.isRecord)(rawRequest.payload) &&
                typeof rawRequest.requesterUid !== "string" && typeof rawRequest.payload.requesterUid === "string"
                ? Object.assign(Object.assign({}, rawRequest), { requesterUid: rawRequest.payload.requesterUid }) : rawRequest;
            (0, contracts_1.assertFunctionRequest)(normalized);
            request = normalized;
        }
        catch (error) {
            logger.warn("Invalid function request ignored", { requestId, error: String(error) });
            const requesterUid = (0, contracts_1.isRecord)(rawRequest) && typeof rawRequest.requesterUid === "string"
                ? rawRequest.requesterUid
                : (0, contracts_1.isRecord)(rawRequest) && (0, contracts_1.isRecord)(rawRequest.payload) && typeof rawRequest.payload.requesterUid === "string"
                    ? rawRequest.payload.requesterUid
                    : undefined;
            if (requesterUid) {
                await (0, writeResponse_1.writeFailure)(requestId, requesterUid, "Requisição inválida.", "invalid-argument");
            }
            return;
        }
        const context = (0, request_1.toRequestContext)(requestId, request);
        const providerId = typeof request.payload.providerId === "string"
            ? request.payload.providerId
            : undefined;
        logger.info("Function request started", {
            requestId,
            type: request.type,
            requesterUid: request.requesterUid,
            providerId,
        });
        try {
            const handler = registry[request.type];
            const result = await handler(context);
            await (0, writeResponse_1.writeSuccess)(requestId, request.requesterUid, result);
            await (0, audit_1.recordAudit)({
                requestId,
                type: request.type,
                requesterUid: request.requesterUid,
                providerId,
                payload: request.payload,
                outcome: "success",
            }).catch((auditError) => logger.error("Audit write failed", {
                requestId,
                type: request.type,
                error: auditError instanceof Error ? auditError.message : String(auditError),
            }));
            logger.info("Function request completed", { requestId, type: request.type, providerId });
        }
        catch (error) {
            const appError = (0, errors_1.toAppError)(error);
            await (0, writeResponse_1.writeFailure)(requestId, request.requesterUid, appError.message, appError.code);
            await (0, audit_1.recordAudit)({
                requestId,
                type: request.type,
                requesterUid: request.requesterUid,
                providerId,
                outcome: "failure",
                errorCode: appError.code,
            }).catch((auditError) => logger.error("Audit write failed", {
                requestId,
                type: request.type,
                error: auditError instanceof Error ? auditError.message : String(auditError),
            }));
            logger.error("Function request failed", {
                requestId,
                type: request.type,
                providerId,
                code: appError.code,
                error: appError.message,
            });
        }
    };
}
//# sourceMappingURL=requestRouter.js.map