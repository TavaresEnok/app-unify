export interface IxcGateway {
  handle(path: string, body?: Record<string, unknown>): Promise<any>;
}
export function createIxcGateway(options: {
  call: (table: string, body: Record<string, unknown>, action: string) => Promise<any>;
  allowWrites?: boolean;
  now?: () => Date;
}): IxcGateway;
export function ixcHeaders(token: string, action?: string): Record<string, string>;
export function ixcUrl(baseUrl: string, table: string): string;
export function formatCpfCnpj(value: unknown): string;
export function ixcDate(value: unknown): string | null;
export function contractStatusLabel(contract: Record<string, unknown>): string;
export const CENTRAL_MARKER: string;
