import type { Unsubscribe } from "firebase/firestore";
import { subscribeProvider } from "@/features/providers/providerService";
import { auth, db } from "@/firebase/config";
import type { ProviderConfig } from "@/shared/contracts";
import { fromFirestoreProviderConfig, toFirestoreProviderConfig } from "@/features/provider-settings/normalizers";
import { publicProviderData } from "@/features/provider-settings/configBoundary";
import { callFunctionRequest } from "@/shared/api/functionRequests";

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
  if (!auth.currentUser) throw new Error("Sessão necessária.");
  const { publicConfig } = toFirestoreProviderConfig(config);
  await callFunctionRequest(db, "UPDATE_PROVIDER_CONFIG", { providerId, config: publicConfig },
    { requesterUid: auth.currentUser.uid });
}
