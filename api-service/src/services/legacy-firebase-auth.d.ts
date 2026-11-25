import type { LiveSessionIdentity } from "./self-auth";

export function legacyFirebaseAuthEnabled(now?: Date, until?: string): boolean;
export function looksLikeFirebaseIdToken(token: unknown): boolean;
export function verifyLegacyFirebaseSession(pool: unknown, token: string, options?: { auth?: unknown; now?: Date }): Promise<LiveSessionIdentity & { legacyFirebase: true }>;
export function verifySessionWithLegacy(
  pool: any,
  token: string,
  verifyLiveSession: (pool: any, token: string) => Promise<LiveSessionIdentity>,
  options?: { auth?: unknown; now?: Date },
): Promise<LiveSessionIdentity>;
export function issueLegacyCustomToken(identity: unknown, options?: { auth?: unknown; now?: Date; persistSubscriber?: (auth: unknown, identity: unknown) => Promise<string> }): Promise<string | null>;
export function resetLegacyAuthForTests(): void;
