export interface LiveSessionIdentity {
  uid: string;
  sub: string;
  email?: string;
  role: string;
  superAdmin: boolean;
  providerId?: string;
  cpfCnpj?: string;
  auth_time: number;
  iat: number;
  exp: number;
}

export function loadKey(envName: string, fileEnvName?: string, fallbackPath?: string): string;
export function encryptSecret(obj: unknown): string;
export function decryptSecret(ciphertext: string): Record<string, any>;
export function hashPassword(password: string): string;
export function verifyPassword(password: string, stored: string): boolean;
export function hashPasswordAsync(password: string, policy?: { minLength?: number; requireMixed?: boolean }): Promise<string>;
export function verifyPasswordAsync(password: string, stored: string | null | undefined): Promise<boolean>;
export function passwordPolicyError(password: unknown, policy?: { minLength?: number; requireMixed?: boolean }): string | null;
export const DUMMY_PASSWORD_HASH: string;
export function signJwt(
  claims: {
    uid: string;
    role: string;
    superAdmin?: boolean;
    providerId?: string;
    cpfCnpj?: string;
    email?: string;
    tv?: number;
    auth_time?: number;
  },
  options?: { ttlSeconds?: number },
): string;
export function verifyJwt(token: string): Record<string, any>;
export function verifyLiveSession(pool: { query: (sql: string, params?: unknown[]) => Promise<{ rows: any[] }> } | null, token: string): Promise<LiveSessionIdentity>;
export function clearKeyCacheForTests(): void;
