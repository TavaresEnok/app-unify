const privateKeys = new Set(['integrations', 'apitoken', 'api_token', 'token', 'password', 'senha', 'secret']);

// Provider documents are readable before login to load branding. Never merge
// integration credentials into this public document, including nested settings.
export function publicProviderData(value: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(Object.entries(value)
    .filter(([key]) => !privateKeys.has(key.toLowerCase()))
    .map(([key, item]) => [key, Array.isArray(item)
      ? item.map(entry => entry && typeof entry === 'object' ? publicProviderData(entry as Record<string, unknown>) : entry)
      : item && typeof item === 'object' ? publicProviderData(item as Record<string, unknown>) : item]));
}
