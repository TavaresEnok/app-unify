import { auth } from '@/shared/auth/session';
import { resolvePublicApiBaseUrl } from '@/shared/config/publicApi';
import { fallbackErrorMessage } from './panelHttp';

export const MAX_ASSET_BYTES = 2 * 1024 * 1024;
export const ACCEPTED_ASSET_TYPES = ['image/png', 'image/jpeg', 'image/webp'] as const;

/**
 * O servidor devolve `/api/public/assets/<id>/<arquivo>`. O app do assinante
 * precisa de URL absoluta, então prefixamos a origem pública da API.
 */
export function absoluteAssetUrl(url: string, apiBase: string, origin = ''): string {
  if (/^https?:\/\//i.test(url)) return url;
  const path = url.startsWith('/') ? url : `/${url}`;
  const base = apiBase.replace(/\/+$/, '');
  if (!/^https?:\/\//i.test(base)) {
    // Produção usa VITE_API_URL=/api (relativo): o caminho devolvido pelo servidor
    // (/api/public/assets/...) já é relativo à origem pública do painel.
    const cleanOrigin = origin.replace(/\/+$/, '');
    if (!/^https?:\/\//i.test(cleanOrigin)) throw new Error('Não foi possível montar o endereço público da imagem.');
    return `${cleanOrigin}${path}`;
  }
  // A base da API já inclui o prefixo público (https://dominio/api), igual ao builder do APK.
  return `${base}${path.replace(/^\/api(?=\/)/i, '')}`;
}

export function assetFileError(file: { type: string; size: number }): string | null {
  if (!(ACCEPTED_ASSET_TYPES as readonly string[]).includes(file.type)) return 'Use uma imagem PNG, JPG ou WebP.';
  return null;
}

/** Reduz imagens grandes para caber no limite de 2 MiB do servidor. */
async function shrinkImage(file: File, maxSide = 1600): Promise<Blob> {
  if (file.size <= MAX_ASSET_BYTES) return file;
  const objectUrl = URL.createObjectURL(file);
  try {
    const img = await new Promise<HTMLImageElement>((resolve, reject) => {
      const image = new Image();
      image.onload = () => resolve(image);
      image.onerror = () => reject(new Error('Não foi possível ler a imagem.'));
      image.src = objectUrl;
    });
    const scale = Math.min(1, maxSide / Math.max(img.width, img.height));
    const canvas = document.createElement('canvas');
    canvas.width = Math.max(1, Math.round(img.width * scale));
    canvas.height = Math.max(1, Math.round(img.height * scale));
    const ctx = canvas.getContext('2d');
    if (!ctx) throw new Error('Não foi possível processar a imagem.');
    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
    const type = file.type === 'image/png' ? 'image/png' : 'image/jpeg';
    const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, type, 0.85));
    if (!blob) throw new Error('Não foi possível processar a imagem.');
    if (blob.size > MAX_ASSET_BYTES) throw new Error('Imagem grande demais. Use uma imagem de até 2 MB.');
    return blob;
  } finally {
    URL.revokeObjectURL(objectUrl);
  }
}

/** Envia uma imagem para POST /admin/providers/:id/assets e devolve a URL pública absoluta. */
export async function uploadProviderAsset(providerId: string, file: File): Promise<string> {
  const typeError = assetFileError(file);
  if (typeError) throw new Error(typeError);
  const user = auth.currentUser;
  if (!user) throw new Error('Sessão expirada. Entre novamente.');
  const body = await shrinkImage(file);
  const apiBase = resolvePublicApiBaseUrl(import.meta.env.VITE_API_URL, window.location);
  const response = await fetch(`${apiBase}/admin/providers/${encodeURIComponent(providerId)}/assets`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${await user.getIdToken()}`, 'Content-Type': body.type || file.type },
    body,
    cache: 'no-store',
  });
  const data = await response.json().catch(() => ({})) as { url?: string; error?: string | { message?: string } };
  if (!response.ok || !data.url) {
    const message = typeof data.error === 'string' ? data.error : data.error?.message;
    throw new Error(message || fallbackErrorMessage(response.status));
  }
  return absoluteAssetUrl(data.url, apiBase, window.location.origin);
}
