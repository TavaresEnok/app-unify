import { deleteField, doc, getDoc, onSnapshot, writeBatch, type Unsubscribe } from "firebase/firestore";
import { db } from "@/firebase/config";
import type { ProviderConfig } from "@/shared/contracts";
import {
  fromFirestoreProviderConfig,
  toFirestoreProviderConfig,
} from "@/features/provider-settings/normalizers";

export interface ProviderSettingsSnapshot {
  config: ProviderConfig;
  provider: Record<string, unknown> | null;
}

export async function subscribeProviderSettings(
  providerId: string,
  onValue: (value: ProviderSettingsSnapshot) => void,
  onError: (error: Error) => void,
): Promise<Unsubscribe> {
  const secretRef = doc(db, "provedores", providerId, "secrets", "sgp");
  const providerRef = doc(db, "provedores", providerId);
  const secretSnapshot = await getDoc(secretRef);
  const secrets = secretSnapshot.exists() ? secretSnapshot.data() : {};

  return onSnapshot(providerRef, (snapshot) => {
    const provider = snapshot.exists() ? snapshot.data() : null;
    onValue({
      config: fromFirestoreProviderConfig(provider, secrets),
      provider,
    });
  }, (error) => onError(error));
}

export async function saveProviderSettings(
  providerId: string,
  config: ProviderConfig,
): Promise<void> {
  const payload = toFirestoreProviderConfig(config);
  const batch = writeBatch(db);
  if (payload.secrets) {
    batch.set(
      doc(db, "provedores", providerId, "secrets", "sgp"),
      payload.secrets,
      { merge: true },
    );
  }
  batch.update(doc(db, "provedores", providerId), {
    ...payload.publicConfig,
    integrations: deleteField(),
    "config.integrations": deleteField(),
  });
  await batch.commit();
}
