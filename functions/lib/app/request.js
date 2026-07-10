"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.toRequestContext = toRequestContext;
function toRequestContext(requestId, request) {
    return {
        requestId,
        type: request.type,
        requesterUid: request.requesterUid,
        payload: request.payload,
    };
}
//# sourceMappingURL=request.js.map