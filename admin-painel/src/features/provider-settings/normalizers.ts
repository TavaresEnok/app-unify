import type { ProviderConfig } from "@/shared/contracts";
import { sanitizePersonalization, parsePersonalization } from "./configBoundary";
import { DEFAULT_PROVIDER_CONFIG } from "./defaults";

type UnknownRecord = Record<string, unknown>;

export function isPlainObject(value: unknown): value is UnknownRecord {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function mergeConfig<T extends UnknownRecord>(base: T, value: UnknownRecord): T {
  const output: UnknownRecord = { ...base };
  for (const [key, next] of Object.entries(value)) {
    const current = output[key];
    output[key] = isPlainObject(current) && isPlainObject(next)
      ? mergeConfig(current, next)
      : next;
  }
  return output as T;
}

function nonEmptyString(value: unknown, fallback: string): string {
  return typeof value === "string" && value.trim() ? value : fallback;
}

export function normalizeProviderConfig(
  providerData: UnknownRecord | null | undefined,
  _secrets: UnknownRecord = {},
): ProviderConfig {
  const data = isPlainObject(providerData) ? providerData : {};
  const merged = mergeConfig(
    DEFAULT_PROVIDER_CONFIG as UnknownRecord,
    sanitizePersonalization(data),
  ) as ProviderConfig;



  merged.themeColor = nonEmptyString(merged.themeColor, DEFAULT_PROVIDER_CONFIG.themeColor);
  merged.secondaryColor = nonEmptyString(merged.secondaryColor, DEFAULT_PROVIDER_CONFIG.secondaryColor);
  merged.layoutType = nonEmptyString(merged.layoutType, DEFAULT_PROVIDER_CONFIG.layoutType) as ProviderConfig["layoutType"];
  return merged;
}

export interface FirestoreProviderPayload {
  publicConfig: Record<string, unknown>;
  secrets: Record<string, unknown> | null;
}

export function toFirestoreProviderConfig(config: ProviderConfig): FirestoreProviderPayload {
  const publicConfig = parsePersonalization(config);
  return { publicConfig, secrets: null };
}

export function fromFirestoreProviderConfig(
  providerData: UnknownRecord | null | undefined,
  secretData: UnknownRecord = {},
): ProviderConfig {
  return normalizeProviderConfig(providerData, secretData);
}
