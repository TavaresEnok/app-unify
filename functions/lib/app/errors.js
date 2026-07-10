"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppError = void 0;
exports.toAppError = toAppError;
class AppError extends Error {
    constructor(code, message) {
        super(message);
        this.code = code;
        this.name = "AppError";
    }
}
exports.AppError = AppError;
function toAppError(error) {
    if (error instanceof AppError)
        return error;
    if (error instanceof Error)
        return new AppError("internal", error.message);
    return new AppError("internal", "Falha interna inesperada.");
}
//# sourceMappingURL=errors.js.map