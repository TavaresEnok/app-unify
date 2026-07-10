const trimTrailingSlash = (value: string) => value.replace(/\/+$/, '');

const envUrl = (value: string | undefined, fallback: string) =>
  trimTrailingSlash(value?.trim() || fallback);

export const runtimeConfig = Object.freeze({
  apiBaseUrl: envUrl(import.meta.env.VITE_API_URL, '/api'),
  apkBuilderBaseUrl: envUrl(import.meta.env.VITE_APK_BUILDER_URL, '/apk-builder'),
  downloadsBaseUrl: envUrl(import.meta.env.VITE_DOWNLOADS_URL, ''),
  panelUrl: envUrl(
    import.meta.env.VITE_PANEL_URL,
    typeof window === 'undefined' ? '' : window.location.origin,
  ),
});

export function publicDownloadUrl(path: string): string {
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  return `${runtimeConfig.downloadsBaseUrl}${normalizedPath}`;
}
