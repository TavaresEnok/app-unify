import { deleteField, doc, onSnapshot, writeBatch, type Unsubscribe } from "firebase/firestore";
import { db } from "@/firebase/config";
import type { ProviderConfig } from "@/shared/contracts";
import { runtimeConfig } from "@/shared/config/runtime";
import {
  fromFirestoreProviderConfig,
  toFirestoreProviderConfig,
} from "@/features/provider-settings/normalizers";
import { SENSITIVE_CONFIG_FIELDS } from "@/features/provider-settings/defaults";

export interface ProviderSettingsSnapshot {
  config: ProviderConfig;
  provider: Record<string, unknown> | null;
}

export async function subscribeProviderSettings(
  providerId: string,
  onValue: (value: ProviderSettingsSnapshot) => void,
  onError: (error: Error) => void,
  canManageIntegrations = false,
): Promise<Unsubscribe> {
  const providerRef = doc(db, "provedores", providerId);

  // Assina AMBOS os documentos (não um getDoc único capturado no closure): após
  // salvar, o snapshot do provedor não reverte mais as integrações para um valor
  // antigo, e o segredo passa a atualizar reativamente (M10).
  let secrets: Record<string, unknown> = {};
  let provider: Record<string, unknown> | null = null;
  let providerLoaded = false;

  const emit = () => {
    if (!providerLoaded) return;
    onValue({ config: fromFirestoreProviderConfig(provider, secrets), provider });
  };

  const unsubscribeSecret = canManageIntegrations ? onSnapshot(
    doc(db, "provedores", providerId, "secrets", "sgp"),
    (snapshot) => { secrets = snapshot.exists() ? (snapshot.data() as Record<string, unknown>) : {}; emit(); },
    // Fail-open localizado: uma falha de permissão nos secrets degrada apenas as
    // integrações (secrets = {}), sem derrubar toda a página de configurações.
    () => { secrets = {}; emit(); },
  ) : () => {};

  const unsubscribeProvider = onSnapshot(
    providerRef,
    (snapshot) => { provider = snapshot.exists() ? (snapshot.data() as Record<string, unknown>) : null; providerLoaded = true; emit(); },
    (error) => onError(error),
  );

  return () => { unsubscribeSecret(); unsubscribeProvider(); };
}

export async function saveProviderSettings(
  providerId: string,
  config: ProviderConfig,
  canManageIntegrations = false,
): Promise<void> {
  const payload = toFirestoreProviderConfig(config);
  payload.publicConfig.apiUrl = runtimeConfig.publicApiBaseUrl || config.apiUrl || "";

  // Defesa em profundidade: o documento do provedor tem leitura pública, então
  // nenhum campo sensível pode escapar para ele — segredos vão só para
  // `secrets/sgp`.
  for (const field of SENSITIVE_CONFIG_FIELDS) {
    delete (payload.publicConfig as Record<string, unknown>)[field];
  }
  const batch = writeBatch(db);
  if (canManageIntegrations && payload.secrets) {
    batch.set(doc(db, "provedores", providerId, "secrets", "sgp"), payload.secrets, { merge: true });
  }
  batch.update(doc(db, "provedores", providerId), {
    ...payload.publicConfig,
    integrations: deleteField(),
    "config.integrations": deleteField(),
  });
  await batch.commit();
}
