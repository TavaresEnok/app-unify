import { subscribeProvider } from "@/features/providers/providerService";
import type { ProviderConfig } from "@/shared/contracts";
import { fromFirestoreProviderConfig, toFirestoreProviderConfig } from "@/features/provider-settings/normalizers";
import { publicProviderData } from "@/features/provider-settings/configBoundary";
import { panelRequest, clearPanelReads } from "@/shared/api/panelHttp";

export type Unsubscribe = () => void;

export interface ProviderSettingsSnapshot {
  config: ProviderConfig;
  provider: Record<string, unknown> | null;
}
export async function subscribeProviderSettings(
  providerId: string,
  onValue: (value: ProviderSettingsSnapshot) => void,
  onError: (error: Error) => void,
): Promise<Unsubscribe> {
  return subscribeProvider(providerId, data => {
    const provider = data ? publicProviderData(data) : null;
    onValue({ config: fromFirestoreProviderConfig(provider), provider });
  }, onError);
}
export async function saveProviderSettings(providerId: string, config: ProviderConfig): Promise<void> {
  const { publicConfig } = toFirestoreProviderConfig(config);
  await panelRequest(`/admin/providers/${encodeURIComponent(providerId)}/config`, { method: 'PATCH', body: publicConfig });
  clearPanelReads();
}
