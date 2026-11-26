import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
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
} from "@/shared/settings/providerSettingsService";

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
  /** Há edições locais ainda não salvas no servidor. */
  dirty: boolean;
  /** Descarta as edições locais e volta para a última versão do servidor. */
  discardChanges: () => void;
  /** Erro ao carregar o provedor (rede, 5xx, sessão). */
  loadError: string | null;
  retryLoad: () => void;
}

export const SettingsContext = createContext<SettingsContextType | undefined>(undefined);

export function SettingsProvider({ children, providerId }: { children: ReactNode; providerId: string }) {
  const [config, setConfigState] = useState<ProviderConfig>(DEFAULT_PROVIDER_CONFIG);
  const [provider, setProvider] = useState<ProviderData | null>(null);
  const [loading, setLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [dirty, setDirty] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [reloadToken, setReloadToken] = useState(0);
  const dirtyRef = useRef(false);
  const serverConfigRef = useRef<ProviderConfig>(DEFAULT_PROVIDER_CONFIG);
  const latestConfigRef = useRef<ProviderConfig>(config);
  latestConfigRef.current = config;

  const markDirty = useCallback((value: boolean) => {
    dirtyRef.current = value;
    setDirty(value);
  }, []);

  // Toda edição feita pelas telas passa por aqui e marca a configuração como alterada.
  const setConfig = useCallback<Dispatch<SetStateAction<ProviderConfig>>>((value) => {
    markDirty(true);
    setConfigState(value);
  }, [markDirty]);

  useEffect(() => {
    let active = true;
    let unsubscribe: () => void = () => {};
    setLoading(true);
    setLoadError(null);
    markDirty(false);

    if (!providerId) {
      setLoading(false);
      return undefined;
    }

    subscribeProviderSettings(providerId, ({ config: nextConfig, provider: nextProvider }) => {
      if (!active) return;
      serverConfigRef.current = nextConfig;
      // Com edições pendentes, a leitura periódica não sobrescreve o que a pessoa está fazendo.
      if (!dirtyRef.current) setConfigState(nextConfig);
      setProvider(nextProvider);
      setLoadError(null);
      setLoading(false);
    }, (error) => {
      if (!active) return;
      console.error("Erro ao carregar configurações", error);
      setLoadError(error.message || "Não foi possível carregar o provedor.");
      setLoading(false);
    }).then((stop) => {
      if (active) unsubscribe = stop;
      else stop();
    }).catch((error: Error) => {
      if (!active) return;
      console.error("Erro ao iniciar configurações", error);
      setLoadError(error.message || "Não foi possível carregar o provedor.");
      setLoading(false);
    });

    return () => {
      active = false;
      unsubscribe();
    };
  }, [providerId, reloadToken, markDirty]);

  useEffect(() => {
    if (!dirty || typeof window === "undefined") return undefined;
    const warn = (event: BeforeUnloadEvent) => {
      event.preventDefault();
      event.returnValue = "";
    };
    window.addEventListener("beforeunload", warn);
    return () => window.removeEventListener("beforeunload", warn);
  }, [dirty]);

  const saveConfig = useCallback(async (nextConfig: ProviderConfig = config) => {
    // Sem a configuração do servidor, a tela mostra valores padrão: salvar agora apagaria a real.
    if (!provider && loadError) {
      const message = "Não foi possível carregar o provedor. Tente carregar de novo antes de salvar.";
      toast.error(message);
      throw new Error(message);
    }
    const savedFrom = config;
    setIsSaving(true);
    try {
      await saveProviderSettings(providerId, nextConfig);
      serverConfigRef.current = nextConfig;
      // Telas que salvam só uma parte ({...config, appVersion}) precisam refletir o valor salvo
      // no estado; senão o próximo "Salvar alterações" manda a versão antiga de volta.
      // Se a pessoa editou algo durante o envio, mantém a edição pendente.
      if (latestConfigRef.current === savedFrom) {
        latestConfigRef.current = nextConfig;
        setConfigState(nextConfig);
        markDirty(false);
      }
      toast.success("Salvo com sucesso!");
    } catch (error) {
      const message = error instanceof Error ? error.message : "Falha inesperada.";
      toast.error(`Erro ao salvar: ${message}`);
      throw error;
    } finally {
      setIsSaving(false);
    }
  }, [config, providerId, markDirty, provider, loadError]);

  const discardChanges = useCallback(() => {
    markDirty(false);
    setConfigState(serverConfigRef.current);
  }, [markDirty]);

  const retryLoad = useCallback(() => setReloadToken((value) => value + 1), []);

  if (loading) {
    return <div className="flex h-screen items-center justify-center"><Loader2 className="animate-spin" /></div>;
  }

  return (
    <SettingsContext.Provider value={{ config, setConfig, loading, saveConfig, isSaving, providerId, provider, dirty, discardChanges, loadError, retryLoad }}>
      {children}
    </SettingsContext.Provider>
  );
}

export function useSettings(): SettingsContextType {
  const context = useContext(SettingsContext);
  if (!context) throw new Error("useSettings must be used within a SettingsProvider");
  return context;
}

/** Igual a useSettings, mas devolve null fora de um SettingsProvider. */
export function useOptionalSettings(): SettingsContextType | null {
  return useContext(SettingsContext) ?? null;
}
