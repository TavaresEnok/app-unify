export interface PublicApiLocation {
  protocol: string;
  hostname: string;
  port: string;
  origin: string;
}

const trimTrailingSlash = (value: string) => value.replace(/\/+$/, "");

function hostForUrl(hostname: string): string {
  return hostname.includes(":") ? `[${hostname}]` : hostname;
}

export function resolvePublicApiBaseUrl(
  configuredUrl: string | undefined,
  location?: PublicApiLocation,
): string {
  const configured = configuredUrl?.trim();
  if (configured) return trimTrailingSlash(configured);
  if (!location) return "";

  if (location.port === "8031" || location.port === "8080") {
    return `${trimTrailingSlash(location.origin)}/api`;
  }

  if (location.protocol === "http:") {
    return `http://${hostForUrl(location.hostname)}:8034`;
  }

  return `${trimTrailingSlash(location.origin)}/api`;
}
