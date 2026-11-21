import { publicProviderData } from '@/features/provider-settings/configBoundary';
import { readPanel, PanelHttpError } from '@/shared/api/panelHttp';
import type { Provider } from '@/shared/contracts';

async function requestProviders(): Promise<Provider[]> {
  const body = await readPanel<{ data: Record<string, unknown>[] }>('/admin/providers/summaries');
  if (!Array.isArray(body.data)) throw new Error('Resposta inválida.');
  return body.data.map(provider => publicProviderData(provider) as unknown as Provider);
}

function subscribe<T>(load: () => Promise<T>, onValue: (value: T) => void, onError?: (error: Error) => void): () => void {
  let stopped = false, pending = false;
  let lastValue: string | undefined;
  const refresh = async () => {
    if (pending || stopped || document.visibilityState === 'hidden') return;
    pending = true;
    try {
      const data = await load();
      const serialized = JSON.stringify(data);
      if (!stopped && serialized !== lastValue) { lastValue = serialized; onValue(data); }
    } catch (error) {
      if (!stopped) onError?.(error instanceof Error ? error : new Error('Falha ao carregar.'));
    } finally { pending = false; }
  };
  void refresh();
  const timer = setInterval(() => { void refresh(); }, 15_000);
  const resume = () => { if (document.visibilityState === 'visible') void refresh(); };
  document.addEventListener('visibilitychange', resume);
  return () => { stopped = true; clearInterval(timer); document.removeEventListener('visibilitychange', resume); };
}

export function subscribeProviders(onValue: (providers: Provider[]) => void, onError?: (error: Error) => void): () => void {
  return subscribe(requestProviders, onValue, onError);
}
export function subscribeProvider(providerId: string, onValue: (provider: Provider | null) => void, onError?: (error: Error) => void): () => void {
  return subscribe(() => getProvider(providerId), onValue, onError);
}
export async function getProvider(providerId: string): Promise<Provider | null> {
  try {
    const body = await readPanel<{ data: Record<string, unknown> }>(`/admin/providers/${encodeURIComponent(providerId)}`);
    return publicProviderData(body.data) as unknown as Provider;
  } catch (error) {
    if (error instanceof PanelHttpError && error.status === 404) return null;
    throw error;
  }
}
