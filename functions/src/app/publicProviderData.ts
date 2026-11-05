const privateKeys = new Set(['integrations', 'apitoken', 'token', 'password', 'senha', 'secret', 'secrets']);

function sanitize(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(sanitize);
  if (!value || typeof value !== 'object') return value;
  // Preserve Firestore timestamps, references and other SDK values.
  const prototype = Object.getPrototypeOf(value);
  if (prototype !== Object.prototype && prototype !== null) return value;
  return publicProviderData(value as Record<string, unknown>);
}

// Provider documents are readable before login to load branding. Never merge
// integration credentials into this public document, including nested settings.
export function publicProviderData(value: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(Object.entries(value)
    .filter(([key]) => !privateKeys.has(key.toLowerCase().replace(/[^a-z0-9]/g, '')))
    .map(([key, item]) => [key, sanitize(item)]));
}
