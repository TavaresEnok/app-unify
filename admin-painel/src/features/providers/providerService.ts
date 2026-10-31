import { auth } from "@/firebase/config";
import { resolvePublicApiBaseUrl } from "@/shared/config/publicApi";
import { publicProviderData } from "@/features/provider-settings/configBoundary";
import type { Provider } from "@/shared/contracts";

async function requestProviders(signal?: AbortSignal): Promise<Provider[]> {
  if (!auth.currentUser) throw new Error("Sessão necessária.");
  const base = resolvePublicApiBaseUrl(import.meta.env.VITE_API_URL, window.location);
  const response = await fetch(`${base}/admin/providers`, {
    headers: { Authorization: `Bearer ${await auth.currentUser.getIdToken()}` }, cache: "no-store", signal,
  });
  if (!response.ok) throw new Error("Não foi possível carregar provedores.");
  const body = await response.json();
  if (!Array.isArray(body.data)) throw new Error("Resposta inválida.");
  return body.data.map((provider: Record<string, unknown>) => publicProviderData(provider) as unknown as Provider);
}

// Poll the sanitized HTTP projection. Never subscribe to raw legacy documents.
export function subscribeProviders(onValue: (providers: Provider[]) => void, onError?: (error: Error) => void): () => void {
  const controller = new AbortController();
  let pending = false;
  let lastValue: string | undefined;
  const refresh = async () => {
    if (pending || controller.signal.aborted) return;
    pending = true;
    try {
      const data = await requestProviders(controller.signal);
      const serialized = JSON.stringify(data);
      if (!controller.signal.aborted && serialized !== lastValue) {
        lastValue = serialized;
        onValue(data);
      }
    } catch (error) {
      if (!controller.signal.aborted) onError?.(error instanceof Error ? error : new Error("Falha ao carregar."));
    } finally { pending = false; }
  };
  void refresh();
  const timer = setInterval(() => { void refresh(); }, 15_000);
  return () => { controller.abort(); clearInterval(timer); };
}
export function subscribeProvider(providerId: string, onValue: (provider: Provider | null) => void, onError?: (error: Error) => void): () => void {
  let lastValue: string | undefined;
  return subscribeProviders(providers => {
    const provider = providers.find(provider => provider.id === providerId) || null;
    const serialized = JSON.stringify(provider);
    if (serialized !== lastValue) { lastValue = serialized; onValue(provider); }
  }, onError);
}
export async function getProvider(providerId: string): Promise<Provider | null> {
  return (await requestProviders()).find(provider => provider.id === providerId) || null;
}
