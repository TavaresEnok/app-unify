export interface IxcGateway {
  handle(path: string, body?: Record<string, unknown>): Promise<any>;
  boletoPdf(body: { cpfcnpj: string; faturaId: string; contrato?: string }): Promise<{ pdf: Buffer; faturaId: string }>;
}
export function decodeBoletoPdf(data: unknown): Buffer;
export function ixcErrorText(data: unknown): string;
export const MAX_BOLETO_BYTES: number;
export function createIxcGateway(options: {
  call: (table: string, body: Record<string, unknown>, action: string) => Promise<any>;
  allowWrites?: boolean;
  pixLookup?: boolean;
  now?: () => Date;
}): IxcGateway;
export function ixcHeaders(token: string, action?: string): Record<string, string>;
export function ixcUrl(baseUrl: string, table: string): string;
export function formatCpfCnpj(value: unknown): string;
export function ixcDate(value: unknown): string | null;
export function contractStatusLabel(contract: Record<string, unknown>): string;
export const CENTRAL_MARKER: string;
