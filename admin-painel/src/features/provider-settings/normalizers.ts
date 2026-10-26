import type { ProviderConfig } from "@/shared/contracts";
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
  secrets: UnknownRecord = {},
): ProviderConfig {
  const data = isPlainObject(providerData) ? providerData : {};
  const legacy = isPlainObject(data.config) ? data.config : {};
  const root = { ...data };
  delete root.config;

  const merged = mergeConfig(
    DEFAULT_PROVIDER_CONFIG as UnknownRecord,
    mergeConfig(legacy, root),
  ) as ProviderConfig;

  if (isPlainObject(secrets.integrations)) {
    merged.integrations = secrets.integrations;
  }

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
  const publicConfig = structuredClone(config) as Record<string, unknown>;
  const integrations = isPlainObject(publicConfig.integrations)
    ? publicConfig.integrations
    : null;
  delete publicConfig.integrations;
  delete publicConfig.config;

  return {
    publicConfig,
    secrets: integrations ? { integrations } : null,
  };
}

export function fromFirestoreProviderConfig(
  providerData: UnknownRecord | null | undefined,
  secretData: UnknownRecord = {},
): ProviderConfig {
  return normalizeProviderConfig(providerData, secretData);
}
