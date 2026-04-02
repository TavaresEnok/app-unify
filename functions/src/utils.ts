/** Parse JSON seguro para respostas de texto de APIs externas. */
export function parseJsonSafely(value: string): unknown | null {
    try {
        return value ? JSON.parse(value) : null;
    } catch {
        return null;
    }
}

export const TICKET_STATUSES = new Set(["Aberto", "Em Andamento", "Fechado"]);

export function isValidTicketStatus(status: string): boolean {
    return TICKET_STATUSES.has(status);
}

/** ID de provedor para criação: apenas minúsculas, números, _ e -. */
export function isValidNewProviderId(id: string): boolean {
    return /^[a-z0-9_-]+$/.test(id);
}

// =========================================================================
// LOGS ESTRUTURADOS — compatíveis com Google Cloud Logging
// Cloud Logging captura severity automaticamente ao usar console.error/warn,
// mas os campos abaixo adicionam contexto rastreável.
// =========================================================================

type LogSeverity = "DEBUG" | "INFO" | "WARNING" | "ERROR" | "CRITICAL";

function structuredLog(
    severity: LogSeverity,
    message: string,
    context: Record<string, unknown> = {}
): void {
    const entry = {
        severity,
        message,
        ...context,
        timestamp: new Date().toISOString(),
    };
    if (severity === "ERROR" || severity === "CRITICAL") {
        console.error(JSON.stringify(entry));
    } else if (severity === "WARNING") {
        console.warn(JSON.stringify(entry));
    } else {
        console.log(JSON.stringify(entry));
    }
}

export const logger = {
    info: (message: string, context?: Record<string, unknown>) =>
        structuredLog("INFO", message, context),
    warn: (message: string, context?: Record<string, unknown>) =>
        structuredLog("WARNING", message, context),
    error: (message: string, context?: Record<string, unknown>) =>
        structuredLog("ERROR", message, context),
    critical: (message: string, context?: Record<string, unknown>) =>
        structuredLog("CRITICAL", message, context),
};
