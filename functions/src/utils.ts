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
