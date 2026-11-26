import type { ProviderConfig } from "@/shared/contracts";

export interface AppVersionForm {
  minVersion: string;
  latestVersion: string;
  storeUrl: string;
}

const VERSION = /^\d+\.\d+\.\d+$/;

/** Compara versões X.Y.Z numericamente. */
export function compareVersions(left: string, right: string): number {
  const a = left.split(".").map(Number);
  const b = right.split(".").map(Number);
  for (let index = 0; index < 3; index += 1) {
    const x = a[index] || 0;
    const y = b[index] || 0;
    if (x !== y) return x > y ? 1 : -1;
  }
  return 0;
}

export function appVersionFormFromConfig(config: Pick<ProviderConfig, "appVersion">): AppVersionForm {
  const current = (config.appVersion || {}) as NonNullable<ProviderConfig["appVersion"]> & { storeUrl?: string };
  return {
    minVersion: current.minVersion || "",
    latestVersion: current.latestVersion || "",
    storeUrl: current.storeUrl || current.storeUrls?.android || "",
  };
}

export type AppVersionResult =
  | { ok: true; value: { minVersion: string; latestVersion: string; storeUrl: string; forceUpdate: boolean; storeUrls: { android: string } } }
  | { ok: false; error: string };

/**
 * Valida o formulário e monta `appVersion` como o app lê
 * ({minVersion, latestVersion, storeUrl}). storeUrls.android é mantido para
 * leitores antigos.
 */
export function buildAppVersion(form: AppVersionForm): AppVersionResult {
  const minVersion = form.minVersion.trim();
  const latestVersion = form.latestVersion.trim();
  const storeUrl = form.storeUrl.trim();
  if (minVersion && !VERSION.test(minVersion)) return { ok: false, error: "Versão mínima: use o formato 1.2.3." };
  if (latestVersion && !VERSION.test(latestVersion)) return { ok: false, error: "Última versão: use o formato 1.2.3." };
  if (minVersion && latestVersion && compareVersions(minVersion, latestVersion) > 0) {
    return { ok: false, error: "A versão mínima não pode ser maior que a última versão." };
  }
  if ((minVersion || latestVersion) && !storeUrl) return { ok: false, error: "Informe o link da loja para o botão Atualizar." };
  if (storeUrl) {
    let url: URL;
    try { url = new URL(storeUrl); } catch { return { ok: false, error: "Link da loja inválido." }; }
    if (url.protocol !== "https:") return { ok: false, error: "O link da loja precisa começar com https://." };
  }
  return {
    ok: true,
    value: { minVersion, latestVersion, storeUrl, forceUpdate: Boolean(minVersion), storeUrls: { android: storeUrl } },
  };
}

type StoredAppVersion = NonNullable<ProviderConfig["appVersion"]> & { storeUrl?: string };

/**
 * Junta o valor novo com o que já estava salvo: o editor só cuida de
 * min/latest/link Android, então preserva link iOS e mensagem personalizada
 * (lidos pela tela Aplicativo e por leitores antigos).
 */
export function mergeAppVersion(
  previous: ProviderConfig["appVersion"] | undefined,
  next: Extract<AppVersionResult, { ok: true }>["value"],
): StoredAppVersion {
  const old = (previous && typeof previous === "object" ? previous : {}) as StoredAppVersion;
  const ios = old.storeUrls?.ios;
  return {
    ...old,
    ...next,
    storeUrls: { android: next.storeUrls.android, ...(typeof ios === "string" && ios ? { ios } : {}) },
  };
}
