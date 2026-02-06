import { createContext, useState, useEffect, useCallback, useContext } from 'react';
import { doc, onSnapshot, setDoc } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Loader2 } from 'lucide-react';
import { toast } from 'sonner';

// Re-export types for gradual adoption
export type { ProviderConfig, LayoutType, ThemeColors, Typography } from '@/lib/types/provider-config';

export interface ProviderConfigLegacy {
  [key: string]: any;
}
export type ProviderData = any;

// --- CORES PADRÃO E TEXTOS (Garantia Anti-Tela-Preta) ---
const UI_DEFAULTS: any = {
  themeColor: '#673AB7',
  secondaryColor: '#9575CD',
  textColor: '#FFFFFF',
  invoiceColor: '#10B981',
  actionColor: '#E11D48',
  cardColor: '#F8F8F8',
  cardTextColor: '#333333',
  logoUrl: '',
  layoutType: 'layout_06',
  quickActionsCardColor: '#FFFFFF', // [NEW] Default value
  quickActionsTextColor: '#333333', // [NEW] Default value
  otherCardsColor: '#FFFFFF', // [NEW] Default value
  otherCardsTextColor: '#333333', // [NEW] Default value

  // --- NOVOS DEFAULTS DE TEXTO ---
  strings: {
    hello_prefix: "Bem-vindo",
    plan_prefix: "Seu plano é:",
    logout_label: "Sair",
    home_tab_title: "Início",
    diagnostics_button: "Diagnóstico de Rede",
    status_ok_title: "Tudo certo",
    status_ok_message: "com seu(s) plano(s)!",
    select_contract_message: "Selecionar contrato",
    last_invoice_label: "Última fatura",
    view_invoices_label: "Ver faturas",
    pay_invoice_label: "Pagar fatura",
    promise_payment_label: "Prometer pagamento",
    support_title: "Suporte Técnico",
    channels_title: "Canais de Atendimento",
    open_ticket_title: "Abrir Novo Ticket",
    terms_title: "Termos de Serviço",
    ticket_subjects: [
      "Financeiro",
      "Suporte Técnico",
      "Comercial",
      "Outros"
    ]
  },

  // Typography defaults
  typography: {
    fontFamily: 'Inter',
    titleSize: 'medium',
    bodySize: 'medium',
    fontWeight: 'medium',
  }
};

interface SettingsContextType {
  config: ProviderConfigLegacy;
  setConfig: React.Dispatch<React.SetStateAction<any>>;
  loading: boolean;
  saveConfig: () => Promise<void>;
  isSaving: boolean;
  providerId: string;
  provider: any;
}

export const SettingsContext = createContext<SettingsContextType | undefined>(undefined);

export function SettingsProvider({ children, providerId }: { children: React.ReactNode, providerId: string }) {
  const [config, setConfig] = useState<ProviderConfigLegacy>(UI_DEFAULTS);
  const [provider, setProvider] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    setLoading(true);
    if (!providerId) return;
    const unsubscribe = onSnapshot(doc(db, 'provedores', providerId), (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data();
        setProvider(data);

        // Lógica de Leitura: Mescla Defaults + Antigo + Novo
        const legacy = data.config || {};
        const root = { ...data };
        delete root.config;
        const finalConfig = { ...UI_DEFAULTS, ...legacy, ...root };

        // Segurança extra para cores vazias
        Object.keys(UI_DEFAULTS).forEach(key => {
          if (!finalConfig[key]) finalConfig[key] = UI_DEFAULTS[key];
        });

        setConfig(finalConfig);
      } else {
        setConfig(UI_DEFAULTS);
      }
      setTimeout(() => setLoading(false), 100);
    }, (error) => {
      console.error("Erro config:", error);
      setLoading(false);
    });
    return () => unsubscribe();
  }, [providerId]);

  const saveConfig = useCallback(async () => {
    setIsSaving(true);
    try {
      const payload = JSON.parse(JSON.stringify(config));
      delete payload.config;

      console.log("💾 Salvando:", payload);

      // Salva direto no banco para garantir
      await setDoc(doc(db, 'provedores', providerId), {
        ...payload,
        config: payload // Espelho para compatibilidade
      }, { merge: true });

      toast.success("Salvo com sucesso!");
    } catch (error: any) {
      toast.error("Erro ao salvar: " + error.message);
    } finally {
      setIsSaving(false);
    }
  }, [config, providerId]);

  if (loading) return <div className="flex h-screen items-center justify-center"><Loader2 className="animate-spin" /></div>;

  return (
    <SettingsContext.Provider value={{ config, setConfig, loading, saveConfig, isSaving, providerId, provider }}>
      {children}
    </SettingsContext.Provider>
  );
}

export const useSettings = () => {
  const context = useContext(SettingsContext);
  if (!context) throw new Error('useSettings must be used within a SettingsProvider');
  return context;
};
