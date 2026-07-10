import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type Dispatch,
  type ReactNode,
  type SetStateAction,
} from "react";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import type { ProviderConfig } from "@/shared/contracts";
import { DEFAULT_PROVIDER_CONFIG } from "@/features/provider-settings/defaults";
import {
  saveProviderSettings,
  subscribeProviderSettings,
} from "@/shared/firebase/providerSettingsService";

export type { ProviderConfig, LayoutType } from "@/shared/contracts";
export type ProviderConfigLegacy = ProviderConfig;
export interface ProviderData extends Record<string, unknown> {
  id?: string;
  name?: string;
  logoUrl?: string;
  details?: { appName?: string } & Record<string, unknown>;
}

interface SettingsContextType {
  config: ProviderConfig;
  setConfig: Dispatch<SetStateAction<ProviderConfig>>;
  loading: boolean;
  saveConfig: (nextConfig?: ProviderConfig) => Promise<void>;
  isSaving: boolean;
  providerId: string;
  provider: ProviderData | null;
}

export const SettingsContext = createContext<SettingsContextType | undefined>(undefined);

export function SettingsProvider({ children, providerId }: { children: ReactNode; providerId: string }) {
  const [config, setConfig] = useState<ProviderConfig>(DEFAULT_PROVIDER_CONFIG);
  const [provider, setProvider] = useState<ProviderData | null>(null);
  const [loading, setLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    let active = true;
    let unsubscribe: () => void = () => {};
    setLoading(true);

    if (!providerId) {
      setLoading(false);
      return undefined;
    }

    subscribeProviderSettings(providerId, ({ config: nextConfig, provider: nextProvider }) => {
      if (!active) return;
      setConfig(nextConfig);
      setProvider(nextProvider);
      setLoading(false);
    }, (error) => {
      if (!active) return;
      console.error("Erro ao carregar configurações", error);
      toast.error("Não foi possível carregar as configurações.");
      setLoading(false);
    }).then((stop) => {
      if (active) unsubscribe = stop;
      else stop();
    }).catch((error: Error) => {
      if (!active) return;
      console.error("Erro ao iniciar configurações", error);
      toast.error("Não foi possível carregar as configurações.");
      setLoading(false);
    });

    return () => {
      active = false;
      unsubscribe();
    };
  }, [providerId]);

  const saveConfig = useCallback(async (nextConfig: ProviderConfig = config) => {
    setIsSaving(true);
    try {
      await saveProviderSettings(providerId, nextConfig);
      toast.success("Salvo com sucesso!");
    } catch (error) {
      const message = error instanceof Error ? error.message : "Falha inesperada.";
      toast.error(`Erro ao salvar: ${message}`);
      throw error;
    } finally {
      setIsSaving(false);
    }
  }, [config, providerId]);

  if (loading) {
    return <div className="flex h-screen items-center justify-center"><Loader2 className="animate-spin" /></div>;
  }

  return (
    <SettingsContext.Provider value={{ config, setConfig, loading, saveConfig, isSaving, providerId, provider }}>
      {children}
    </SettingsContext.Provider>
  );
}

export function useSettings(): SettingsContextType {
  const context = useContext(SettingsContext);
  if (!context) throw new Error("useSettings must be used within a SettingsProvider");
  return context;
}
