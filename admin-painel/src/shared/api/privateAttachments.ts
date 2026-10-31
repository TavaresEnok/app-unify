import type { User } from 'firebase/auth';
import { auth } from '@/firebase/config';
import { resolvePublicApiBaseUrl } from '@/shared/config/publicApi';

export type PrivateResource = { ticketId: string } | { providerId: string; resultId: string };
const opaque = (value: string) => {
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(value)) throw new Error('Identificador inválido.');
  return value;
};
export function privateAttachmentPath(resource: PrivateResource, attachmentId: string) {
  const parent = 'ticketId' in resource ? `/tickets/${opaque(resource.ticketId)}/attachments`
    : `/providers/${opaque(resource.providerId)}/results/${opaque(resource.resultId)}/reports`;
  return `/private${parent}/${opaque(attachmentId)}`;
}
export async function privateAttachmentRequest(user: User, resource: PrivateResource, attachmentId: string, signal: AbortSignal, file?: File): Promise<Blob | void> {
  const path = privateAttachmentPath(resource, attachmentId);
  if (signal.aborted || auth.currentUser !== user) throw new Error('Sessão alterada.');
  const token = await user.getIdToken();
  if (signal.aborted || auth.currentUser !== user) throw new Error('Sessão alterada.');
  const base = resolvePublicApiBaseUrl(import.meta.env.VITE_API_URL, window.location);
  const response = await fetch(`${base}${path}`, { method: file ? 'PUT' : 'GET', signal, cache: 'no-store',
    headers: { Authorization: `Bearer ${token}`, ...(file ? { 'Content-Type': file.type } : {}) }, body: file });
  if (!response.ok) throw new Error('Não foi possível acessar o anexo privado.');
  if (signal.aborted || auth.currentUser !== user) throw new Error('Sessão alterada.');
  if (!file) {
    const blob = await response.blob();
    if (!['image/png', 'image/jpeg', 'application/pdf'].includes(blob.type) || blob.size > 5 * 1024 * 1024 || !blob.size) throw new Error('Arquivo inválido.');
    if (signal.aborted || auth.currentUser !== user) throw new Error('Sessão alterada.');
    return blob;
  }
}
export class PrivateBlob {
  private abort = new AbortController();
  private url?: string;
  dispose() { this.abort.abort(); if (this.url) URL.revokeObjectURL(this.url); this.url = undefined; }
  async load(user: User, resource: PrivateResource, attachmentId: string) {
    const blob = await privateAttachmentRequest(user, resource, attachmentId, this.abort.signal);
    if (this.abort.signal.aborted || !blob) throw new Error('Leitura cancelada.');
    this.url = URL.createObjectURL(blob);
    return { url: this.url, mime: blob.type };
  }
}
