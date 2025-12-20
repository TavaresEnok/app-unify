# 🌐 Sistema Web Admin - Código Completo

> **Tecnologias:** React + TypeScript + Vite + Firebase + TailwindCSS  
> **Componentes UI:** shadcn/ui  
> **Gerado em:** 2025-12-19 20:46:26  
> **Total de arquivos:** 87  
> **Localização:** `/admin-painel/src/`

---

## 📂 Índice

1. [Estrutura Principal](#estrutura-principal)
   - App.tsx (Rotas e configuração)
   - main.tsx (Entry point)
2. [Contexts](#contexts)
   - AuthContext (Autenticação)
   - SettingsContext (Configurações)
3. [Hooks e Utils](#hooks-e-utils)
4. [Componentes](#componentes)
   - Layouts (MainLayout, ProviderSettingsLayout)
   - Dialogs (AddProvider, AddTicket, etc.)
   - UI Components (Button, Card, Dialog, etc.)
5. [Páginas](#paginas)
   - Dashboard
   - Provedores
   - Configurações do Provedor
   - Clientes
   - Tickets

---

# 🔧 ESTRUTURA PRINCIPAL

> Arquivos raiz que configuram a aplicação React.


---

### `src/main.tsx`
> Entry point da aplicação React

```tsx
import React from 'react'; import ReactDOM from 'react-dom/client'; import App from './App'; import './index.css'; import { BrowserRouter } from 'react-router-dom';
ReactDOM.createRoot(document.getElementById('root')!).render(<React.StrictMode><BrowserRouter><App /></BrowserRouter></React.StrictMode>);
```

---

### `src/App.tsx`
> Componente principal com rotas e providers

```tsx
import { Routes, Route, Navigate } from "react-router-dom";
import DashboardBuilder from './pages/provider-settings/DashboardBuilder';
import NotificationsManager from './pages/provider-settings/NotificationsManager';
import PromotionsManager from './pages/provider-settings/PromotionsManager';
import SplashLoginConfig from './pages/provider-settings/SplashLoginConfig';
import { AuthProvider, useAuth } from "@/contexts/AuthContext";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import MainLayout from "@/components/MainLayout";
import DashboardPage from "@/pages/DashboardPage";
import ProvidersPage from "@/pages/ProvidersPage";
import ProviderDetailPage from "@/pages/ProviderDetailPage";
import UsersPage from "@/pages/UsersPage";
import LoginPage from "@/pages/LoginPage";
import ProtectedRoute from "@/components/ProtectedRoute";
import ProviderSettingsLayout from "@/components/ProviderSettingsLayout";
import AppearanceSettings from "@/pages/provider-settings/AppearanceSettings";
import FeaturesSettings from "@/pages/provider-settings/FeaturesSettings";
import SupportSettings from "@/pages/provider-settings/SupportSettings";
import CarouselSettings from "@/pages/provider-settings/CarouselSettings";
import TipsSettings from "@/pages/provider-settings/TipsSettings";
import FaqSettings from "@/pages/provider-settings/FaqSettings";
import ImagesIconsSettings from "@/pages/provider-settings/ImagesIconsSettings";
import MessagesSettings from "@/pages/provider-settings/MessagesSettings";
import SocialNetworksSettings from "@/pages/provider-settings/SocialNetworksSettings";
import OtherSettings from "@/pages/provider-settings/OtherSettings";
import BackupSettings from "@/pages/provider-settings/BackupSettings";
import IntegrationsSettings from "@/pages/provider-settings/IntegrationsSettings";
import PersonalizedTextsSettings from "@/pages/provider-settings/PersonalizedTextsSettings";
import ProviderDashboardPage from "./pages/provider/ProviderDashboardPage";
import NotificationSenderPage from "./pages/provider/NotificationSenderPage";
import ProviderClientsPage from "./pages/provider/ProviderClientsPage";
import ClientDetailPage from "./pages/provider/ClientDetailPage";
import AdminTicketsPage from "./pages/AdminTicketsPage";
import ProviderTicketsPage from "./pages/provider/ProviderTicketsPage";
import TicketDetailPage from "./pages/TicketDetailPage";
import MyCompanyPage from "./pages/provider/MyCompanyPage";
import MenusSettingsPage from "./pages/provider-settings/MenusSettingsPage";

function PostLoginRedirect() {
  const { userRole } = useAuth();
  if (userRole === 'superAdmin') return <Navigate to="/dashboard" replace />;
  if (userRole === 'providerAdmin') return <Navigate to="/provedor/dashboard" replace />;
  return <Navigate to="/login" replace />;
}

const ProviderSettingsRoutes = (
  <Route element={<ProviderSettingsLayout />}>
    <Route index element={<Navigate to="appearance" replace />} />
    <Route path="appearance" element={<AppearanceSettings />} />
    <Route path="images" element={<ImagesIconsSettings />} />
    <Route path="menus" element={<MenusSettingsPage />} />
    <Route path="features" element={<FeaturesSettings />} />
    <Route path="integrations" element={<IntegrationsSettings />} />
    <Route path="support" element={<SupportSettings />} />
    <Route path="carousel" element={<CarouselSettings />} />
    <Route path="social" element={<SocialNetworksSettings />} />
    <Route path="tips" element={<TipsSettings />} />
    <Route path="faq" element={<FaqSettings />} />
    <Route path="messages" element={<MessagesSettings />} />
    <Route path="other" element={<OtherSettings />} />
    <Route path="backup" element={<BackupSettings />} />
    <Route path="dashboard-builder" element={<DashboardBuilder />} />
    <Route path="notifications" element={<NotificationsManager />} />
    <Route path="promotions" element={<PromotionsManager />} />
    <Route path="splash-login" element={<SplashLoginConfig />} />
    <Route path="texts" element={<PersonalizedTextsSettings />} />
  </Route>
);

export default function App() {
  return (
    <ThemeProvider defaultTheme="dark" storageKey="vite-ui-theme">
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/" element={<ProtectedRoute><PostLoginRedirect /></ProtectedRoute>} />
          <Route path="/" element={<ProtectedRoute><MainLayout /></ProtectedRoute>}>
            <Route path="dashboard" element={<DashboardPage />} />
            <Route path="provedores" element={<ProvidersPage />} />
            <Route path="utilizadores" element={<UsersPage />} />
            <Route path="tickets" element={<AdminTicketsPage />} />
            <Route path="tickets/:ticketId" element={<TicketDetailPage />} />
            <Route path="provedores/:providerId" element={<ProviderDetailPage />}>
              {ProviderSettingsRoutes}
            </Route>
            <Route path="provedor/dashboard" element={<ProviderDashboardPage />} />
            <Route path="provedor/notificacoes" element={<NotificationSenderPage />} />
            <Route path="provedor/clientes" element={<ProviderClientsPage />} />
            <Route path="provedor/clientes/:clientId" element={<ClientDetailPage />} />
            <Route path="provedor/minha-empresa" element={<MyCompanyPage />} />
            <Route path="provedor/tickets" element={<ProviderTicketsPage />} />
            <Route path="provedor/tickets/:ticketId" element={<TicketDetailPage />} />
            <Route path="provedor/personalizacao" element={<ProviderDetailPage />}>
              {ProviderSettingsRoutes}
            </Route>
          </Route>
        </Routes>
      </AuthProvider>
      <Toaster />
    </ThemeProvider>
  );
}
```

---

# 🔐 CONTEXTS

> Gerenciamento de estado global com React Context API.


---

### `src/contexts/AuthContext.tsx`
> Contexto de autenticação Firebase

```tsx
import React, { useContext, useState, useEffect } from 'react'; 
import { onAuthStateChanged, User } from 'firebase/auth';
import { auth } from '@/firebase/config';
import { Loader2 } from 'lucide-react';

interface AuthContextType {
    user: User | null;
    userRole: 'superAdmin' | 'providerAdmin' | null;
    providerId: string | null; 
    loading: boolean;
}

const AuthContext = React.createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [user, setUser] = useState<User | null>(null);
    const [userRole, setUserRole] = useState<'superAdmin' | 'providerAdmin' | null>(null);
    const [providerId, setProviderId] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
            if (currentUser) {
                await currentUser.getIdToken(true); 
                const tokenResult = await currentUser.getIdTokenResult();
                
                setUser(currentUser);
                if (tokenResult.claims.superAdmin) {
                    setUserRole('superAdmin');
                    setProviderId(null);
                } else if (tokenResult.claims.providerId) {
                    setUserRole('providerAdmin');
                    setProviderId(tokenResult.claims.providerId as string);
                } else {
                    setUserRole(null);
                    setProviderId(null);
                }
            } else {
                setUser(null);
                setUserRole(null);
                setProviderId(null);
            }
            setLoading(false);
        });
        return () => unsubscribe();
    }, []);

    if (loading) {
        return (
            <div className="flex h-screen w-full items-center justify-center bg-background">
                <Loader2 className="h-8 w-8 animate-spin" />
            </div>
        );
    }

    return (
        <AuthContext.Provider value={{ user, userRole, providerId, loading }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};
```

---

### `src/contexts/SettingsContext.tsx`
> Contexto de configurações do provedor

```tsx
import { createContext, useState, useEffect, useCallback, useContext } from 'react';
import { doc, onSnapshot, setDoc } from "firebase/firestore";
import { db } from '@/firebase/config';
import { useApi } from '@/hooks/useApi';
import { Loader2 } from 'lucide-react';
import { toast } from 'sonner';
export interface ProviderConfig {
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
    }
};
interface SettingsContextType {
  config: ProviderConfig;
  setConfig: React.Dispatch<React.SetStateAction<any>>;
  loading: boolean;
  saveConfig: () => Promise<void>;
  isSaving: boolean;
  providerId: string;
  provider: any;
}
export const SettingsContext = createContext<SettingsContextType | undefined>(undefined);
export function SettingsProvider({ children, providerId }: { children: React.ReactNode, providerId: string }) {
  const [config, setConfig] = useState<ProviderConfig>(UI_DEFAULTS);
  const [provider, setProvider] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const { callFunction } = useApi();
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
```

---

# 🔥 FIREBASE

> Configuração do Firebase para autenticação e banco de dados.


---

### `src/firebase/config.ts`
> Configuração do Firebase

```tsx
// ARQUIVO: src/firebase/config.ts

import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
// O getAnalytics é opcional, mas vamos mantê-lo como está na sua configuração.
import { getAnalytics } from "firebase/analytics";

// Your web app's Firebase configuration - COPIADO DO SEU CONSOLE
const firebaseConfig = {
  apiKey: "AIzaSyCMySTH49MgYk2TyuGxnLd0zOQ-Cah2l5A",
  authDomain: "app-ajust-provedor.firebaseapp.com",
  projectId: "app-ajust-provedor",
  storageBucket: "app-ajust-provedor.appspot.com", // Corrigido de .firebasestorage.app
  messagingSenderId: "2735150999",
  appId: "1:2735150999:web:20a6ba508b510ce90a56d2",
  measurementId: "G-2W0E4E1KLB"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const analytics = getAnalytics(app); // Inicializa o Analytics

export { auth, db, analytics };
```

---

# 🪝 HOOKS

> Custom hooks reutilizáveis.


---

### `src/hooks/useApi.ts`
> Hook para chamadas à API

```tsx
import { useState } from 'react';
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";
import { db } from '@/firebase/config';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from "sonner";

// Lista de todas as ações possíveis
type ApiAction = 
  | 'UPDATE_PROVIDER_CONFIG'
  | 'SEND_SCOPED_NOTIFICATION' 
  | 'SEND_SCOPED_NOTIFICATION_SEGMENTED' 
  | 'SGP_API_PROXY'
  | 'GET_DASHBOARD_DATA'
  | 'LIST_ADMIN_USERS'
  | 'CREATE_PROVIDER'
  | 'DELETE_PROVIDER'
  | 'UPDATE_PROVIDER_DETAILS'
  | 'CREATE_ADMIN_USER'
  | 'DELETE_ADMIN_USER'
  | 'SET_SUPER_ADMIN_BY_EMAIL'
  | 'GET_PROVIDER_DASHBOARD_DATA'
  | 'GET_ALL_TICKETS'
  | 'GET_PROVIDER_TICKETS'
  | 'CREATE_TICKET'
  | 'REPLY_TO_TICKET'
  | 'UPDATE_TICKET_STATUS'
  | 'DELETE_TICKET'
  | 'LIST_PROVIDER_CLIENTS'
  | 'DELETE_CLIENT'
  | 'GET_CLIENT_DETAILS'
  | 'BACKUP_PROVIDER_CONFIG'
  | 'LIST_PROVIDER_BACKUPS'
  | 'RESTORE_PROVIDER_CONFIG'
  | 'DELETE_PROVIDER_BACKUP';

export function useApi() {
  const { user, userRole, providerId: authProviderId } = useAuth(); 
  const [loading, setLoading] = useState(false);

  const callFunction = <T extends object>(type: ApiAction, payload: T): Promise<any> => {
    return new Promise((resolve, reject) => {
      if (!user) {
        toast.error("Erro de autenticação", { description: "Utilizador não encontrado. Por favor, faça login novamente." });
        reject(new Error("Utilizador não autenticado."));
        return;
      }

      setLoading(true);
      const requestId = doc(collection(db, 'function_requests')).id;
      const requestDocRef = doc(db, 'function_requests', requestId);
      const responseDocRef = doc(db, 'function_responses', requestId);

      const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
        if (docSnap.exists()) {
          unsubscribe();
          setLoading(false);
          const response = docSnap.data();
          if (response.error) {
            toast.error("Erro no servidor", { description: response.error });
            reject(new Error(response.error));
          } else {
            // Evita toast de sucesso para GETs
            if (type.startsWith('GET_') || type.startsWith('LIST_')) {
                resolve(response.result);
            } else {
                toast.success("Sucesso!", { description: response.result?.message || "Operação concluída." });
                resolve(response.result);
            }
          }
        }
      });

      // ===== LÓGICA DE INJEÇÃO DE providerId (SEGURANÇA) =====
      let finalPayload: any = { ...payload, requesterUid: user.uid };

      // Se o usuário for um admin de provedor, FORÇA o providerId do token dele.
      if (userRole === 'providerAdmin' && authProviderId) {
        finalPayload.providerId = authProviderId;
      }
      // ===================================

      setDoc(requestDocRef, {
        type,
        createdAt: serverTimestamp(),
        payload: finalPayload,
      }).catch(error => {
        unsubscribe();
        setLoading(false);
        toast.error("Erro ao solicitar a operação", { description: error.message });
        reject(error);
      });
    });
  };

  return { callFunction, loading };
}
```

---

# 🛠️ UTILS


---

### `src/lib/utils.ts`
> Utilitários gerais (cn, etc.)

```tsx
import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

---

# 🧩 COMPONENTES

> Componentes React reutilizáveis.

## 📐 Layouts


---

### `src/components/MainLayout.tsx`
> Layout principal com sidebar e header

```tsx
import { NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";
import { LayoutDashboard, Server, Users, Brush, Bell, MessageSquare, ShieldCheck, Menu, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Sun, Moon } from "lucide-react";
import { useTheme } from "@/components/theme-provider";
import { signOut, getIdTokenResult } from "firebase/auth";
import { auth } from "@/firebase/config";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";

function ThemeToggle() {
  const { setTheme, theme } = useTheme();
  return (
    <Button variant="ghost" size="icon" onClick={() => setTheme(theme === "light" ? "dark" : "light")}>
      <Sun className="h-[1.2rem] w-[1.2rem] rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
      <Moon className="absolute h-[1.2rem] w-[1.2rem] rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
      <span className="sr-only">Toggle theme</span>
    </Button>
  );
}

export default function MainLayout() {
  const { user, userRole } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const getInitials = (email: string | null | undefined) => {
    if (!email) return "?";
    return email.substring(0, 2).toUpperCase();
  };

  const handleLogout = async () => {
    await signOut(auth);
    navigate('/login');
  };

  const handleIdentityCheck = async () => {
    if (user) {
      console.log("--- INICIANDO TESTE DE IDENTIDADE ---");
      const tokenResult = await getIdTokenResult(user, true);
      console.log("Email do Usuário:", tokenResult.claims.email);
      console.log("É Super Admin?", tokenResult.claims.superAdmin === true);
      console.log("ID do Provedor:", tokenResult.claims.providerId || "Nenhum");
      console.log("Todas as permissões (claims):", tokenResult.claims);
      alert(`Verifique o console (F12) para ver suas permissões.`);
    } else {
      alert("Usuário não está logado.");
    }
  };

  const getNavLinkClass = (path: string) => {
    const isActive = location.pathname === path || (path !== '/' && location.pathname.startsWith(path));
    return cn("w-full justify-start text-base py-6", isActive ? 'bg-secondary text-secondary-foreground' : 'hover:bg-secondary/80');
  }

  // Componente de navegação reutilizável
  const NavContent = ({ onNavigate }: { onNavigate?: () => void }) => (
    <>
      <div className="p-4 mb-4"><h1 className="text-3xl font-bold tracking-tight">Admin</h1></div>
      <nav className="flex flex-col gap-2">
        {userRole === 'superAdmin' ? (
          <>
            <NavLink to="/dashboard" onClick={onNavigate}><Button variant="ghost" className={getNavLinkClass('/dashboard')}><LayoutDashboard className="mr-4 h-5 w-5" />Dashboard</Button></NavLink>
            <NavLink to="/provedores" onClick={onNavigate}><Button variant="ghost" className={getNavLinkClass('/provedores')}><Server className="mr-4 h-5 w-5" />Provedores</Button></NavLink>
            <NavLink to="/utilizadores" onClick={onNavigate}><Button variant="ghost" className={getNavLinkClass('/utilizadores')}><Users className="mr-4 h-5 w-5" />Utilizadores</Button></NavLink>
            <NavLink to="/tickets" onClick={onNavigate}><Button variant="ghost" className={getNavLinkClass('/tickets')}><MessageSquare className="mr-4 h-5 w-5" />Tickets</Button></NavLink>
          </>
        ) : (
          <>
            <NavLink to="/provedor/dashboard" onClick={onNavigate}><Button variant="ghost" className={getNavLinkClass("/provedor/dashboard")}><LayoutDashboard className="mr-4 h-5 w-5" />Dashboard</Button></NavLink>
            <NavLink to="/provedor/notificacoes" onClick={onNavigate}><Button variant="ghost" className={getNavLinkClass("/provedor/notificacoes")}><Bell className="mr-4 h-5 w-5" />Notificações</Button></NavLink>
            <NavLink to="/provedor/clientes" onClick={onNavigate}><Button variant="ghost" className={getNavLinkClass("/provedor/clientes")}><Users className="mr-4 h-5 w-5" />Clientes</Button></NavLink>
            <NavLink to="/provedor/minha-empresa" onClick={onNavigate}><Button variant="ghost" className={getNavLinkClass("/provedor/minha-empresa")}><Server className="mr-4 h-5 w-5" />Minha Empresa</Button></NavLink>
            <NavLink to="/provedor/personalizacao" onClick={onNavigate}><Button variant="ghost" className={getNavLinkClass("/provedor/personalizacao")}><Brush className="mr-4 h-5 w-5" />Personalização</Button></NavLink>
            <NavLink to="/provedor/tickets" onClick={onNavigate}><Button variant="ghost" className={getNavLinkClass("/provedor/tickets")}><MessageSquare className="mr-4 h-5 w-5" />Suporte</Button></NavLink>
          </>
        )}
      </nav>
      <div className="mt-auto p-4 border-t">
        <Button variant="outline" className="w-full" onClick={handleIdentityCheck}>
          <ShieldCheck className="mr-2 h-4 w-4" /> Testar Identidade
        </Button>
      </div>
    </>
  );

  return (
    <div className="flex h-screen bg-muted/10">
      {/* Sidebar Desktop */}
      <aside className="hidden w-72 flex-col border-r bg-background sm:flex p-4">
        <NavContent />
      </aside>

      <div className="flex flex-1 flex-col">
        <header className="flex h-20 items-center justify-between gap-6 border-b bg-background px-4 sm:px-8">
          {/* Botão Menu Mobile */}
          <Sheet open={mobileMenuOpen} onOpenChange={setMobileMenuOpen}>
            <SheetTrigger asChild className="sm:hidden">
              <Button variant="ghost" size="icon">
                <Menu className="h-6 w-6" />
                <span className="sr-only">Menu</span>
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="w-72 p-4">
              <NavContent onNavigate={() => setMobileMenuOpen(false)} />
            </SheetContent>
          </Sheet>

          {/* Placeholder para manter alinhamento no desktop */}
          <div className="hidden sm:block" />

          <div className="flex items-center gap-4">
            <ThemeToggle />
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="outline" size="icon" className="rounded-full">
                  <Avatar className="h-9 w-9"><AvatarFallback>{getInitials(user?.email)}</AvatarFallback></Avatar>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem onClick={handleLogout}>Sair</DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </header>
        <main className="flex-1 overflow-y-auto p-4 sm:p-8 bg-muted/40">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
```

---

### `src/components/ProviderSettingsLayout.tsx`
> Layout para páginas de configuração

```tsx
import { NavLink, Outlet, useParams, useLocation } from "react-router-dom";
import { cn } from "@/lib/utils";
import { Button } from "./ui/button";
import { useAuth } from "@/contexts/AuthContext";

const menuItems = [
  { name: "Aparência", path: "appearance" },
  { name: "Imagens & Ícones", path: "images" },
  { name: "Menus", path: "menus" },
  { name: "Módulos", path: "features" },
  { name: "Integrações", path: "integrations" },
  { name: "Contato & Suporte", path: "support" },
  { name: "Carrossel", path: "carousel" },
  { name: "Redes Sociais", path: "social" },
  { name: "Dicas", path: "tips" },
  { name: "FAQ", path: "faq" },
  { name: "Mensagens", path: "messages" },
  { name: "Outros", path: "other" },
  { name: "Backup/Restore", path: "backup" },
];

export default function ProviderSettingsLayout() {
  const { providerId: providerIdFromParams } = useParams();
  const { userRole, providerId: providerIdFromAuth } = useAuth();
  const location = useLocation();

  const providerId = userRole === 'superAdmin' ? providerIdFromParams : providerIdFromAuth;
  const basePath = userRole === 'superAdmin' ? `/provedores/${providerId}` : '/provedor/personalizacao';

  const navLinkClass = (path: string) =>
    cn("w-full justify-start", location.pathname.endsWith(path) ? "bg-secondary text-secondary-foreground" : "hover:bg-muted");

  return (
    <div className="grid grid-cols-1 md:grid-cols-4 lg:grid-cols-5 gap-8">
      <aside className="md:col-span-1">
        <nav className="flex flex-col gap-1">
          {menuItems.map(item => (
            <NavLink key={item.path} to={`${basePath}/${item.path}`}>
              <Button variant="ghost" className={navLinkClass(item.path)}>
                {item.name}
              </Button>
            </NavLink>
          ))}
        </nav>
      </aside>
      <main className="md:col-span-3 lg:col-span-4">
        <Outlet />
      </main>
    </div>
  );
}
```

---

### `src/components/AppCustomizationLayout.tsx`
> Layout de customização do app

```tsx
import { NavLink, Outlet, useLocation } from "react-router-dom";
import { cn } from "@/lib/utils";

const tabs = [
    { name: "Aplicativo", path: "/provedor/personalizacao/aplicativo" },
    { name: "Menus", path: "/provedor/personalizacao/menus" },
    { name: "Redes Sociais", path: "/provedor/personalizacao/redes-sociais" },
    { name: "Contatos para Suporte", path: "/provedor/personalizacao/contatos" },
    { name: "Termos de Uso", path: "/provedor/personalizacao/termos" },
    { name: "Textos Personalizados", path: "/provedor/personalizacao/textos" },
];

export default function AppCustomizationLayout() {
    const location = useLocation();

    const getTabClass = (path: string) => {
        return cn(
            "inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
            location.pathname.startsWith(path)
                ? "bg-primary text-primary-foreground shadow"
                : "hover:bg-accent hover:text-accent-foreground"
        );
    };

    return (
        <div className="flex flex-col gap-6">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">Aplicativos</h1>
                <p className="text-muted-foreground">
                    Personalize a aparência e as funcionalidades do seu aplicativo.
                </p>
            </div>

            <div className="flex items-center space-x-2 overflow-x-auto pb-2">
                {tabs.map((tab) => (
                    <NavLink key={tab.path} to={tab.path} className={getTabClass(tab.path)}>
                        {tab.name}
                    </NavLink>
                ))}
            </div>

            <div className="w-full">
                <Outlet />
            </div>
        </div>
    );
}
```

---

### `src/components/ProtectedRoute.tsx`
> Route guard para autenticação

```tsx
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Loader2 } from 'lucide-react';

interface ProtectedRouteProps {
  children: React.ReactNode;
}

export default function ProtectedRoute({ children }: ProtectedRouteProps) {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="flex h-screen w-full items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
}
```

## 💬 Dialogs


---

### `src/components/AddProviderDialog.tsx`
> Dialog para adicionar provedor

```tsx
// admin-painel/src/components/AddProviderDialog.tsx - VERSÃO CORRIGIDA
import { useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import { PlusCircle, Loader2 } from "lucide-react";
import { db } from "@/firebase/config";
// AQUI ESTÁ A CORREÇÃO: onSnapshot foi adicionado à importação
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";
import { useAuth } from "@/contexts/AuthContext";

export default function AddProviderDialog({ onUpdate }: { onUpdate: () => void }) {
    const [name, setName] = useState('');
    const [providerId, setProviderId] = useState('');
    const [isSaving, setIsSaving] = useState(false);
    const [isOpen, setIsOpen] = useState(false);
    const { user } = useAuth();

    const handleSave = async () => {
        if (!name || !providerId) { toast.error("Nome e ID são obrigatórios."); return; }
        if (!user) { toast.error("Utilizador não autenticado."); return; }

        setIsSaving(true);
        const toastId = toast.loading("Enviando pedido para criar provedor...");
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                if (response.result) {
                    toast.success(response.result.message || "Provedor criado com sucesso!", { id: toastId });
                    onUpdate(); // Atualiza a lista na página principal
                    setIsOpen(false);
                    setName('');
                    setProviderId('');
                } else if (response.error) {
                    toast.error(`Erro ao criar provedor: ${response.error}`, { id: toastId });
                }
                // Parar de ouvir após receber a resposta
                unsubscribe();
                setIsSaving(false); // Reativa o botão
            }
        });
        
        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'CREATE_PROVIDER',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: { name, providerId }
            });
        } catch (error: any) {
            toast.error(`Erro ao solicitar criação: ${error.message}`, { id: toastId });
            unsubscribe();
            setIsSaving(false); // Reativa o botão em caso de erro na solicitação
        }
    };

    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogTrigger asChild><Button><PlusCircle className="mr-2 h-4 w-4" />Adicionar Novo Provedor</Button></DialogTrigger>
            <DialogContent>
                <DialogHeader>
                    <DialogTitle>Adicionar Novo Provedor</DialogTitle>
                    <DialogDescription>Crie um novo provedor na plataforma.</DialogDescription>
                </DialogHeader>
                <div className="grid gap-4 py-4">
                    <div className="space-y-2"><Label htmlFor="name">Nome do Provedor</Label><Input id="name" value={name} onChange={(e) => setName(e.target.value)} /></div>
                    <div className="space-y-2"><Label htmlFor="id">ID do Provedor (sem espaços/caracteres especiais)</Label><Input id="id" value={providerId} onChange={(e) => setProviderId(e.target.value.toLowerCase().trim())} /></div>
                </div>
                <DialogFooter>
                    <Button variant="outline" onClick={() => setIsOpen(false)}>Cancelar</Button>
                    <Button onClick={handleSave} disabled={isSaving}>{isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}Salvar</Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
```

---

### `src/components/EditProviderDialog.tsx`
> Dialog para editar provedor

```tsx
// admin-painel/src/components/EditProviderDialog.tsx
import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { toast } from "sonner";
import { Loader2, FilePenLine } from "lucide-react";
import { db } from "@/firebase/config";
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";
import { useAuth } from "@/contexts/AuthContext";

interface Provider {
    id: string;
    name?: string;
    details?: ProviderDetails;
}

interface ProviderDetails {
    appName?: string;
    apiToken?: string;
    systemUrl?: string;
    systemType?: string;
    apiUrl?: string;  // URL do Proxy/API
    city?: string;
    state?: string;
    hasAndroidApp?: boolean;
    hasIosApp?: boolean;
}

interface EditProviderDialogProps {
    provider: Provider;
    onUpdate: () => void;
}

export default function EditProviderDialog({ provider, onUpdate }: EditProviderDialogProps) {
    const { user } = useAuth();
    const [details, setDetails] = useState<ProviderDetails>(provider.details || {});
    const [name, setName] = useState(provider.name || '');
    const [isSaving, setIsSaving] = useState(false);
    const [isOpen, setIsOpen] = useState(false);

    // Garante que o estado do formulário é atualizado se o prop do provedor mudar
    useEffect(() => {
        setDetails(provider.details || {});
        setName(provider.name || '');
    }, [provider]);

    const handleDetailChange = (key: keyof ProviderDetails, value: any) => {
        setDetails(prev => ({ ...prev, [key]: value }));
    };

    const handleSave = async () => {
        if (!user) {
            toast.error("Utilizador não autenticado.");
            return;
        }

        setIsSaving(true);
        const toastId = toast.loading("A guardar alterações...");

        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                unsubscribe();
                if (response.result) {
                    toast.success(response.result.message || "Provedor atualizado com sucesso!", { id: toastId });
                    onUpdate(); // Atualiza a lista na página principal
                    setIsOpen(false);
                } else {
                    toast.error(`Erro ao guardar: ${response.error}`, { id: toastId });
                }
                setIsSaving(false);
            }
        });

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'UPDATE_PROVIDER_DETAILS',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: { providerId: provider.id, details: { ...details, name } } // Enviamos 'name' dentro de details
            });
        } catch (error: any) {
            toast.error(`Falha ao solicitar a operação: ${error.message}`, { id: toastId });
            setIsSaving(false);
            unsubscribe();
        }
    };

    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogTrigger asChild>
                <Button variant="outline" size="sm"><FilePenLine className="h-4 w-4" /></Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[800px]">
                <DialogHeader>
                    <DialogTitle>Gerenciar Provedor</DialogTitle>
                    <DialogDescription>Edite as informações de base e de sistema para este provedor.</DialogDescription>
                </DialogHeader>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 py-4">
                    <div className="space-y-2">
                        <Label htmlFor="providerName">Nome do Provedor</Label>
                        <Input id="providerName" value={name} onChange={(e) => setName(e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="appName">Nome do Aplicativo</Label>
                        <Input id="appName" value={details.appName || ''} onChange={(e) => handleDetailChange('appName', e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="apiToken">Token da API (SGP)</Label>
                        <Input id="apiToken" value={details.apiToken || ''} onChange={(e) => handleDetailChange('apiToken', e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="systemUrl">URL do Sistema (SGP)</Label>
                        <Input id="systemUrl" value={details.systemUrl || ''} onChange={(e) => handleDetailChange('systemUrl', e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="systemType">Tipo de Sistema</Label>
                        <Input id="systemType" value={details.systemType || ''} onChange={(e) => handleDetailChange('systemType', e.target.value)} />
                    </div>
                    <div className="space-y-2 md:col-span-2">
                        <Label htmlFor="apiUrl">URL do Proxy/API (usado pelo app)</Label>
                        <Input id="apiUrl" placeholder="http://168.194.13.18:3000" value={details.apiUrl || ''} onChange={(e) => handleDetailChange('apiUrl', e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="city">Cidade</Label>
                        <Input id="city" value={details.city || ''} onChange={(e) => handleDetailChange('city', e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="state">Estado</Label>
                        <Input id="state" value={details.state || ''} onChange={(e) => handleDetailChange('state', e.target.value)} />
                    </div>
                    <div className="flex flex-col gap-2 pt-2">
                        <div className="flex items-center space-x-2">
                            <Switch id="hasAndroidApp" checked={details.hasAndroidApp} onCheckedChange={(c) => handleDetailChange('hasAndroidApp', c)} />
                            <Label htmlFor="hasAndroidApp">Habilitar app Android</Label>
                        </div>
                        <div className="flex items-center space-x-2">
                            <Switch id="hasIosApp" checked={details.hasIosApp} onCheckedChange={(c) => handleDetailChange('hasIosApp', c)} />
                            <Label htmlFor="hasIosApp">Habilitar app iPhone</Label>
                        </div>
                    </div>
                </div>
                <DialogFooter>
                    <Button variant="outline" onClick={() => setIsOpen(false)}>Cancelar</Button>
                    <Button onClick={handleSave} disabled={isSaving}>
                        {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Guardar Alterações
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
```

---

### `src/components/AddTicketDialog.tsx`
> Dialog para abrir ticket

```tsx
// admin-painel/src/components/AddTicketDialog.tsx - TESTE FINAL DE CAMINHO
import { useState, useRef } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "sonner";
import { PlusCircle, Loader2, Paperclip, XCircle } from "lucide-react";
import { db } from "@/firebase/config";
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { useAuth } from "@/contexts/AuthContext";

interface AddTicketDialogProps {
  providerName: string;
  onTicketCreated: () => void;
}

export default function AddTicketDialog({ providerName, onTicketCreated }: AddTicketDialogProps) {
    const [subject, setSubject] = useState('');
    const [message, setMessage] = useState('');
    const [isSaving, setIsSaving] = useState(false);
    const [isOpen, setIsOpen] = useState(false);
    const [imageFile, setImageFile] = useState<File | null>(null);
    const [imagePreview, setImagePreview] = useState<string | null>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);
    const { user, providerId } = useAuth();

    const resetState = () => {
        setSubject('');
        setMessage('');
        setImageFile(null);
        setImagePreview(null);
        if (fileInputRef.current) fileInputRef.current.value = "";
    };

    const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files[0]) {
            const file = e.target.files[0];
            setImageFile(file);
            setImagePreview(URL.createObjectURL(file));
        }
    };

    const handleSave = async () => {
        if (!subject.trim()) {
            toast.error("O campo 'Assunto' é obrigatório.");
            return;
        }
        if (!user || !providerId || !user.email) {
            toast.error("Utilizador não autenticado corretamente.");
            return;
        }
        
        setIsSaving(true);
        const toastId = toast.loading("A abrir novo ticket...");

        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                if (response.result) {
                    toast.success(response.result.message || "Ticket criado com sucesso!", { id: toastId });
                    onTicketCreated();
                    setIsOpen(false);
                    resetState();
                } else if (response.error) {
                    toast.error(`Erro ao criar ticket: ${response.error}`, { id: toastId });
                }
                setIsSaving(false);
                unsubscribe();
            }
        });

        try {
            let imageUrl: string | null = null;
            if (imageFile) {
                toast.loading("A enviar imagem...", { id: toastId });
                const storage = getStorage();

                // ===================================================================
                // O TESTE FINAL ESTÁ AQUI: Mudamos o caminho para dentro de 'providers'
                // ===================================================================
                const filePath = `providers/${providerId}/ticket_attachments/${Date.now()}_${imageFile.name}`;
                
                const storageRef = ref(storage, filePath);
                const uploadResult = await uploadBytes(storageRef, imageFile);
                imageUrl = await getDownloadURL(uploadResult.ref);
            }

            toast.loading("A registar ticket...", { id: toastId });
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'CREATE_TICKET',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: { subject, message, providerName, providerId, userEmail: user.email, imageUrl }
            });

        } catch (error: any) {
            toast.error(`Falha crítica ao criar ticket: ${error.message}`, { id: toastId });
            setIsSaving(false);
            unsubscribe();
        }
    };

    return (
        <Dialog open={isOpen} onOpenChange={(open) => { if (!open) resetState(); setIsOpen(open); }}>
            <DialogTrigger asChild><Button><PlusCircle className="mr-2 h-4 w-4" />Abrir Novo Ticket</Button></DialogTrigger>
            <DialogContent className="sm:max-w-[625px]">
                <DialogHeader>
                    <DialogTitle>Abrir Novo Ticket de Suporte</DialogTitle>
                    <DialogDescription>Descreva o seu problema ou dúvida. A nossa equipe responderá o mais breve possível.</DialogDescription>
                </DialogHeader>
                <div className="grid gap-4 py-4">
                    <div className="space-y-2">
                        <Label htmlFor="subject">Assunto</Label>
                        <Input id="subject" value={subject} onChange={(e) => setSubject(e.target.value)} placeholder="Ex: Dúvida sobre o módulo de faturas" />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="message">Mensagem</Label>
                        <Textarea id="message" value={message} onChange={(e) => setMessage(e.target.value)} placeholder="Detalhe aqui a sua solicitação..." rows={6} />
                    </div>
                    {imagePreview && (
                        <div className="relative w-32 h-32">
                            <img src={imagePreview} alt="Pré-visualização" className="rounded-md w-full h-full object-cover"/>
                            <Button variant="ghost" size="icon" className="absolute top-0 right-0 h-6 w-6 bg-black/50 hover:bg-black/70" onClick={() => { setImageFile(null); setImagePreview(null); if(fileInputRef.current) fileInputRef.current.value = ""; }}>
                                <XCircle className="text-white"/>
                            </Button>
                        </div>
                    )}
                </div>
                <DialogFooter className="sm:justify-between">
                    <Button variant="outline" onClick={() => fileInputRef.current?.click()} disabled={isSaving}>
                        <Paperclip className="mr-2 h-4 w-4" />
                        Anexar Imagem
                    </Button>
                    <input type="file" ref={fileInputRef} className="hidden" accept="image/png, image/jpeg" onChange={handleImageSelect}/>
                    <div className="flex gap-2">
                        <Button variant="outline" onClick={() => setIsOpen(false)}>Cancelar</Button>
                        <Button onClick={handleSave} disabled={isSaving}>
                            {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            Enviar Ticket
                        </Button>
                    </div>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
```

---

### `src/components/AddAdminDialog.tsx`
> Dialog para adicionar admin

```tsx
import { useState, useEffect } from "react";
import { Dialog, DialogContent,  DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { toast } from "sonner";
import { PlusCircle, Loader2 } from "lucide-react";
import { db } from "@/firebase/config";
import { collection, onSnapshot, doc, setDoc, serverTimestamp } from "firebase/firestore";
import { useAuth } from "@/contexts/AuthContext";

interface Provider { id: string; name: string; }

export default function AddAdminDialog({ onUpdate }: { onUpdate: () => void }) {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [role, setRole] = useState('');
    const [providerId, setProviderId] = useState('');
    const [providers, setProviders] = useState<Provider[]>([]);
    const [isSaving, setIsSaving] = useState(false);
    const [isOpen, setIsOpen] = useState(false);
    const { user } = useAuth();

    useEffect(() => {
        if (isOpen) {
            const unsubscribe = onSnapshot(collection(db, 'provedores'), (snapshot) => {
                const list = snapshot.docs.map(doc => ({ id: doc.id, name: doc.data().name as string }));
                setProviders(list);
            });
            return () => unsubscribe();
        }
    }, [isOpen]);

    const handleSave = async () => {
        if (!email || !password || !role) { toast.error("Email, senha e permissão são obrigatórios."); return; }
        if (role === 'providerAdmin' && !providerId) { toast.error("Para um Admin de Provedor, é necessário selecionar o provedor."); return; }
        if (!user) { toast.error("Utilizador principal não autenticado."); return; }

        setIsSaving(true);
        const toastId = toast.loading("Enviando pedido para criar utilizador...");
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                if (response.result) {
                    toast.success(response.result.message || "Utilizador criado com sucesso!", { id: toastId });
                    onUpdate();
                    setIsOpen(false);
                    setEmail(''); setPassword(''); setRole(''); setProviderId('');
                } else if (response.error) {
                    toast.error(`Erro ao criar utilizador: ${response.error}`, { id: toastId });
                }
                unsubscribe();
                setIsSaving(false);
            }
        });

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'CREATE_ADMIN_USER',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: { email, password, role, providerId }
            });
        } catch (error: any) {
            toast.error(`Erro ao solicitar criação: ${error.message}`, { id: toastId });
            unsubscribe();
            setIsSaving(false);
        }
    };

    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogTrigger asChild><Button><PlusCircle className="mr-2 h-4 w-4" />Adicionar Utilizador</Button></DialogTrigger>
            <DialogContent>
                <DialogHeader><DialogTitle>Adicionar Novo Utilizador</DialogTitle></DialogHeader>
                <div className="grid gap-4 py-4">
                    <div className="space-y-2"><Label htmlFor="email">Email</Label><Input id="email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} /></div>
                    <div className="space-y-2"><Label htmlFor="password">Senha</Label><Input id="password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} /></div>
                    <div className="space-y-2"><Label>Permissão</Label>
                        <Select onValueChange={setRole} value={role}>
                            <SelectTrigger><SelectValue placeholder="Selecione a permissão" /></SelectTrigger>
                            <SelectContent>
                                <SelectItem value="superAdmin">Super Admin</SelectItem>
                                <SelectItem value="providerAdmin">Admin de Provedor</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                    {role === 'providerAdmin' && (
                        <div className="space-y-2"><Label>Provedor</Label>
                            <Select onValueChange={setProviderId} value={providerId}>
                                <SelectTrigger><SelectValue placeholder="Selecione o provedor" /></SelectTrigger>
                                <SelectContent>
                                    {providers.map(p => <SelectItem key={p.id} value={p.id}>{p.name}</SelectItem>)}
                                </SelectContent>
                            </Select>
                        </div>
                    )}
                </div>
                <DialogFooter>
                    <Button variant="outline" onClick={() => setIsOpen(false)}>Cancelar</Button>
                    <Button onClick={handleSave} disabled={isSaving}>{isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}Salvar</Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
```

---

### `src/components/AddMenuItemDialog.tsx`
> Dialog para item de menu

```tsx
import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { PlusCircle } from "lucide-react";

interface AddMenuItemDialogProps {
  onAddItem: (name: string, url: string) => void;
}

export default function AddMenuItemDialog({ onAddItem }: AddMenuItemDialogProps) {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [url, setUrl] = useState("");

  const handleSave = () => {
    if (name && url) {
      onAddItem(name, url);
      setOpen(false); // Fecha o diálogo
      // Limpa os campos para a próxima vez
      setName("");
      setUrl("");
    }
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>
          <PlusCircle className="mr-2 h-4 w-4" />
          Adicionar
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Adicionar Novo Item ao Menu</DialogTitle>
          <DialogDescription>
            Crie um atalho personalizado para um link externo, como o site da sua empresa.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4 py-4">
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="name" className="text-right">
              Nome
            </Label>
            <Input
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="col-span-3"
              placeholder="Ex: Nosso Site"
            />
          </div>
          <div className="grid grid-cols-4 items-center gap-4">
            <Label htmlFor="url" className="text-right">
              URL
            </Label>
            <Input
              id="url"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              className="col-span-3"
              placeholder="https://..."
            />
          </div>
        </div>
        <DialogFooter>
          <Button type="submit" onClick={handleSave}>Salvar Item</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
```

## 📊 Cards e Charts


---

### `src/components/StatsCard.tsx`
> Card de estatísticas

```tsx
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { LucideIcon } from 'lucide-react';

interface StatsCardProps {
    title: string;
    value: number | string;
    icon: LucideIcon;
    trend?: number; // Porcentagem de crescimento (opcional)
    trendLabel?: string;
}

export default function StatsCard({ title, value, icon: Icon, trend, trendLabel = "vs. mês passado" }: StatsCardProps) {
    return (
        <Card className="hover:shadow-md transition-shadow duration-200">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
                <Icon className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
                <div className="text-2xl font-bold">{value}</div>
                {trend !== undefined && (
                    <p className="text-xs text-muted-foreground mt-1 flex items-center">
                        {trend > 0 ? (
                            <span className="text-emerald-500 flex items-center font-medium">
                                +{trend}% <span className="ml-1">↗</span>
                            </span>
                        ) : trend < 0 ? (
                            <span className="text-rose-500 flex items-center font-medium">
                                {trend}% <span className="ml-1">↘</span>
                            </span>
                        ) : (
                            <span className="text-muted-foreground flex items-center">
                                0% <span className="ml-1">-</span>
                            </span>
                        )}
                        <span className="ml-2 opacity-80">{trendLabel}</span>
                    </p>
                )}
            </CardContent>
        </Card>
    );
}
```

---

### `src/components/ClientsChart.tsx`
> Gráfico de clientes

```tsx
import { Bar, BarChart, XAxis, YAxis, Tooltip, ResponsiveContainer, LabelList } from 'recharts';
interface ChartData { name: string; clientes: number; }
export default function ClientsChart({ data }: { data: ChartData[] }) {
  return (
    <ResponsiveContainer width="100%" height={350}>
      <BarChart data={data}>
        <XAxis dataKey="name" stroke="#888888" fontSize={12} tickLine={false} axisLine={false} />
        <YAxis stroke="#888888" fontSize={12} tickLine={false} axisLine={false} />
        <Tooltip cursor={{fill: 'hsl(var(--secondary))'}} contentStyle={{backgroundColor: 'hsl(var(--background))', borderColor: 'hsl(var(--border))'}}/>
        <Bar dataKey="clientes" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]}>
           <LabelList dataKey="clientes" position="top" style={{ fill: 'hsl(var(--foreground))' }} />
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}
```

---

### `src/components/NewClientsChart.tsx`
> Gráfico de novos clientes

```tsx
// src/components/NewClientsChart.tsx
import { Bar, BarChart, ResponsiveContainer, XAxis, YAxis, Tooltip, Legend } from "recharts";
import { useTheme } from "@/components/theme-provider";

interface NewClientsChartProps {
  data: {
    name: string;
    clientes: number;
  }[];
}

export default function NewClientsChart({ data }: NewClientsChartProps) {
    const { theme } = useTheme();
    const tickColor = theme === 'dark' ? '#A1A1AA' : '#71717A'; // zinc-400 or zinc-500

    if (data.length === 0) {
        return (
            <div className="flex h-[350px] w-full items-center justify-center">
                <p className="text-muted-foreground">Sem dados de novos clientes nos últimos 7 dias.</p>
            </div>
        )
    }

    return (
        <ResponsiveContainer width="100%" height={350}>
            <BarChart data={data}>
                <XAxis
                    dataKey="name"
                    stroke={tickColor}
                    fontSize={12}
                    tickLine={false}
                    axisLine={false}
                />
                <YAxis
                    stroke={tickColor}
                    fontSize={12}
                    tickLine={false}
                    axisLine={false}
                    allowDecimals={false}
                />
                 <Tooltip 
                    cursor={{fill: 'transparent'}}
                    contentStyle={{
                        backgroundColor: theme === 'dark' ? '#09090B' : '#FFFFFF', // zinc-950 or white
                        borderColor: theme === 'dark' ? '#27272A' : '#E4E4E7' // zinc-800 or zinc-200
                    }}
                />
                <Legend />
                <Bar dataKey="clientes" name="Novos Clientes" fill="#8884d8" radius={[4, 4, 0, 0]} />
            </BarChart>
        </ResponsiveContainer>
    );
}
```

---

### `src/components/MobilePreview.tsx`
> Preview do app mobile

```tsx
import { useContext } from 'react';
import { SettingsContext } from '@/contexts/SettingsContext';
import { Battery, Signal, Wifi, User, Bell } from 'lucide-react';
import { Home, BarChart2, LifeBuoy, FileText, Lock, Zap, Globe, HelpCircle, Lightbulb, Share2, Image as ImageIcon } from 'lucide-react';

export default function MobilePreview() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config } = context;
    
    const primaryColor = config.themeColor || '#673AB7';
    const secondaryColor = config.secondaryColor || '#9575CD';
    
    // Verifica se deve usar imagem
    const useBackgroundImage = config.other?.useBackgroundImage || false;

    const rawFirstImage = config.imageCarousel?.[0];
    let headerImageUrl: string | null = null;
    if (typeof rawFirstImage === 'string') {
        headerImageUrl = rawFirstImage;
    } else if (typeof rawFirstImage === 'object' && rawFirstImage?.url) {
        headerImageUrl = rawFirstImage.url;
    }

    const getIcon = (id: string) => {
        const icons: any = {
            'home': Home, 'internet_usage': BarChart2, 'support': LifeBuoy,
            'invoices': FileText, 'payment_promise': Lock, 'speed_test': Zap,
            'notifications': Bell, 'faq': HelpCircle, 'useful_tips': Lightbulb,
            'social': Share2, 'website': Globe
        };
        return icons[id] || Home;
    };

    const menuOrder = config.menuConfig?.order || ['invoices', 'internet_usage', 'support', 'speed_test'];
    const menuItems = config.menuConfig?.items || {};

    return (
        <div className="sticky top-24">
            <div className="flex items-center justify-between mb-4 px-2">
                <h3 className="text-lg font-semibold tracking-tight">Visualização App</h3>
                <span className="text-[10px] uppercase tracking-wider text-muted-foreground bg-muted/50 px-2 py-1 rounded-md font-bold border border-white/5">Preview</span>
            </div>

            <div className="relative mx-auto border-gray-900 bg-gray-900 border-[12px] rounded-[3rem] h-[620px] w-[310px] shadow-2xl ring-1 ring-white/10">
                <div className="w-[100px] h-[22px] bg-gray-900 top-0 rounded-b-[1rem] left-1/2 -translate-x-1/2 absolute z-20 border-b border-x border-gray-800"></div>
                {/* Botões laterais */}
                <div className="h-[46px] w-[3px] bg-gray-800 absolute -start-[15px] top-[100px] rounded-s-lg"></div>
                <div className="h-[46px] w-[3px] bg-gray-800 absolute -start-[15px] top-[160px] rounded-s-lg"></div>
                <div className="h-[64px] w-[3px] bg-gray-800 absolute -end-[15px] top-[130px] rounded-e-lg"></div>
                
                {/* TELA: Fundo Padrão #F8F9FC (Cinza muito claro) */}
                <div className="rounded-[2.3rem] overflow-hidden w-full h-full bg-[#F8F9FC] relative flex flex-col font-sans selection:bg-transparent">
                    <style>{`.no-scrollbar::-webkit-scrollbar { display: none; } .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }`}</style>

                    {/* Status Bar */}
                    <div className="h-10 w-full flex justify-between items-end px-5 pb-1 z-30 text-[10px] font-medium tracking-wide" style={{ color: useBackgroundImage ? 'white' : '#0F172A' }}>
                        <span>12:30</span>
                        <div className="flex gap-1.5 items-center opacity-90"><Signal className="h-3 w-3"/><Wifi className="h-3 w-3"/><Battery className="h-3.5 w-3.5"/></div>
                    </div>

                    {/* HEADER */}
                    <div className="relative shrink-0">
                        {useBackgroundImage && headerImageUrl ? (
                            <div className="absolute inset-0 border-b-2 border-white/5" style={{ borderBottomLeftRadius: '2rem', borderBottomRightRadius: '2rem', overflow: 'hidden' }}>
                                <img src={headerImageUrl} className="w-full h-full object-cover" alt="Header" />
                                <div className="absolute inset-0 bg-black/40 backdrop-blur-[1px]"></div>
                            </div>
                        ) : (
                            <div className="absolute inset-0 opacity-90" style={{ background: `linear-gradient(160deg, ${primaryColor} 0%, ${secondaryColor} 100%)`, borderBottomLeftRadius: '2rem', borderBottomRightRadius: '2rem' }} />
                        )}
                        
                        <div className="relative z-10 pt-2 pb-6 px-5">
                            <div className="flex justify-between items-start mb-6">
                                <div className="flex items-center gap-3">
                                    <div className="h-10 w-10 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center border border-white/20 shadow-sm"><User className="h-5 w-5 text-white"/></div>
                                    <div><div className="h-2.5 w-20 bg-white/40 rounded-full mb-1.5"></div><div className="h-2 w-12 bg-white/25 rounded-full"></div></div>
                                </div>
                                <Bell className="h-5 w-5 text-white" />
                            </div>

                            {/* Fatura Card */}
                            <div className="bg-white/15 backdrop-blur-md rounded-2xl p-4 border border-white/20 shadow-lg relative overflow-hidden">
                                <div className="flex justify-between items-center mb-3">
                                    <div className="h-2 w-16 bg-white/50 rounded-full"></div>
                                    <div className="h-5 w-16 bg-emerald-500/30 border border-emerald-400/50 rounded-full"></div>
                                </div>
                                <div className="h-7 w-28 bg-white/90 rounded-md mb-2"></div>
                                <div className="h-2 w-24 bg-white/40 rounded-full"></div>
                            </div>
                        </div>
                    </div>

                    {/* CONTEÚDO */}
                    <div className="flex-1 overflow-y-auto no-scrollbar p-5 -mt-2 relative z-20">
                        <div className="h-3 w-24 bg-slate-200 rounded-full mb-4"></div>
                        
                        <div className="grid grid-cols-2 gap-3 mb-6">
                            {menuOrder.map((id: string) => {
                                const item = menuItems[id];
                                if (item && !item.enabled) return null;
                                const IconComp = getIcon(id);
                                const label = item?.name || id;

                                return (
                                    <div key={id} className="aspect-[1.4/1] bg-white rounded-2xl flex flex-col items-center justify-center gap-2 p-2 shadow-sm border border-slate-100">
                                        <div className="p-2 rounded-xl" style={{ backgroundColor: `${primaryColor}15` }}>
                                            <IconComp className="h-5 w-5" style={{ color: primaryColor }} />
                                        </div>
                                        <span className="text-[10px] font-medium text-slate-600 text-center leading-tight line-clamp-1 px-1">{label}</span>
                                    </div>
                                );
                            })}
                        </div>

                        {!useBackgroundImage && (
                            <div className="relative w-full aspect-[2.5/1] bg-white rounded-2xl border border-slate-100 overflow-hidden shadow-sm flex items-center justify-center group">
                                 <div className="flex flex-col items-center gap-2 text-slate-300">
                                     <ImageIcon className="h-8 w-8" />
                                     <span className="text-[10px] uppercase tracking-widest">Carrossel</span>
                                 </div>
                            </div>
                        )}
                        <div className="h-10"></div>
                    </div>

                    {/* BOTTOM NAV */}
                    <div className="h-[70px] bg-white/90 backdrop-blur-xl border-t border-slate-100 flex justify-around items-center px-4 pb-3 absolute bottom-0 w-full z-40">
                        <div className="flex flex-col items-center gap-1 cursor-pointer">
                            <div className="p-1.5 rounded-xl" style={{ backgroundColor: `${primaryColor}15` }}>
                                <Home className="h-5 w-5" style={{ color: primaryColor }} />
                            </div>
                        </div>
                        <div className="flex flex-col items-center gap-1 opacity-40"><BarChart2 className="h-5 w-5 text-slate-800" /></div>
                        <div className="flex flex-col items-center gap-1 opacity-40"><LifeBuoy className="h-5 w-5 text-slate-800" /></div>
                    </div>
                </div>
            </div>
        </div>
    );
}
```

---

# 📄 PÁGINAS

> Páginas da aplicação (rotas).

## 🏠 Páginas Principais


---

### `src/pages/LoginPage.tsx`
> Página de login

```tsx
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '@/firebase/config';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Loader2 } from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';

export default function LoginPage() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const navigate = useNavigate();
    const { user } = useAuth();

    useEffect(() => {
        // O redirecionamento agora é centralizado no App.tsx
        if (user) {
            navigate('/', { replace: true });
        }
    }, [user, navigate]);

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!email || !password) {
            toast.error('Por favor, preencha o email e a senha.');
            return;
        }
        setIsLoading(true);
        try {
            await signInWithEmailAndPassword(auth, email, password);
            toast.success('Login bem-sucedido! A redirecionar...');
            // A navegação será tratada pelo useEffect e pelo PostLoginRedirect
        } catch (error: any) {
            toast.error('Falha no login. Verifique suas credenciais.');
            console.error(error);
        } finally {
            setIsLoading(false);
        }
    };

    if (user) {
        return null;
    }

    return (
        <div className="flex min-h-screen items-center justify-center bg-background">
            <Card className="w-full max-w-sm">
                <CardHeader>
                    <CardTitle className="text-2xl">Login</CardTitle>
                    <CardDescription>Insira seu email e senha para aceder ao painel.</CardDescription>
                </CardHeader>
                <CardContent>
                    <form onSubmit={handleLogin} className="grid gap-4">
                        <div className="grid gap-2">
                            <Label htmlFor="email">Email</Label>
                            <Input id="email" type="email" placeholder="m@example.com" required value={email} onChange={(e) => setEmail(e.target.value)} disabled={isLoading} />
                        </div>
                        <div className="grid gap-2">
                            <Label htmlFor="password">Senha</Label>
                            <Input id="password" type="password" required value={password} onChange={(e) => setPassword(e.target.value)} disabled={isLoading} />
                        </div>
                        <Button type="submit" className="w-full" disabled={isLoading}>
                            {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            Entrar
                        </Button>
                    </form>
                </CardContent>
            </Card>
        </div>
    );
}
```

---

### `src/pages/DashboardPage.tsx`
> Dashboard do super admin

```tsx
import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { toast } from "sonner";
import { collection, getDocs, query, where, orderBy, limit } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Server, Users, Bell, MessageSquare } from "lucide-react";
import ClientsChart from '@/components/ClientsChart';
import { DashboardSkeleton } from '@/components/DashboardSkeleton';
import StatsCard from '@/components/StatsCard';

interface ChartData { name: string; clientes: number; }
interface RecentTicket {
    id: string;
    subject: string;
    providerName: string;
    status: 'Aberto' | 'Em Andamento' | 'Fechado';
    updatedAt: { _seconds: number; _nanoseconds: number; };
}

export default function DashboardPage() {
    const { userRole, user } = useAuth();
    const navigate = useNavigate();
    const [stats, setStats] = useState({ providerCount: 0, clientCount: 0, notificationCount: 0, openTicketsCount: 0 });
    const [chartData, setChartData] = useState<ChartData[]>([]);
    const [recentTickets, setRecentTickets] = useState<RecentTicket[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (userRole !== 'superAdmin' || !user) {
            setLoading(false);
            return;
        }

        const loadDashboardData = async () => {
            try {
                // 1. Contar provedores
                const providersSnapshot = await getDocs(collection(db, 'provedores'));
                const providerCount = providersSnapshot.size;

                // 2. Preparar dados do gráfico (provedores)
                const chartDataTemp: ChartData[] = [];
                providersSnapshot.forEach(doc => {
                    const data = doc.data();
                    chartDataTemp.push({
                        name: data.name || doc.id,
                        clientes: data.clientCount || 0
                    });
                });
                setChartData(chartDataTemp);

                // 3. Contar usuários (clientes)
                let clientCount = 0;
                try {
                    const usersSnapshot = await getDocs(collection(db, 'users'));
                    clientCount = usersSnapshot.size;
                } catch (e) {
                    console.log('Coleção users não existe ou sem permissão');
                }

                // 4. Contar tickets abertos
                let openTicketsCount = 0;
                let recentTicketsTemp: RecentTicket[] = [];
                try {
                    const openTicketsQuery = query(
                        collection(db, 'tickets'),
                        where('status', 'in', ['Aberto', 'Em Andamento'])
                    );
                    const openTicketsSnapshot = await getDocs(openTicketsQuery);
                    openTicketsCount = openTicketsSnapshot.size;

                    // Tickets recentes
                    const recentTicketsQuery = query(
                        collection(db, 'tickets'),
                        orderBy('updatedAt', 'desc'),
                        limit(5)
                    );
                    const recentTicketsSnapshot = await getDocs(recentTicketsQuery);
                    recentTicketsTemp = recentTicketsSnapshot.docs.map(doc => {
                        const data = doc.data();
                        return {
                            id: doc.id,
                            subject: data.subject || 'Sem assunto',
                            providerName: data.providerName || 'Desconhecido',
                            status: data.status || 'Aberto',
                            updatedAt: data.updatedAt
                        };
                    });
                } catch (e) {
                    console.log('Coleção tickets não existe ou sem permissão');
                }
                setRecentTickets(recentTicketsTemp);

                // 5. Contar notificações (últimas 24h)
                let notificationCount = 0;
                try {
                    const notificationsSnapshot = await getDocs(collection(db, 'notifications'));
                    notificationCount = notificationsSnapshot.size;
                } catch (e) {
                    console.log('Coleção notifications não existe ou sem permissão');
                }

                // Atualizar stats
                setStats({
                    providerCount,
                    clientCount,
                    notificationCount,
                    openTicketsCount
                });

                setLoading(false);
            } catch (error: any) {
                console.error('Erro ao carregar dashboard:', error);
                toast.error(`Erro ao carregar dados: ${error.message}`);
                setLoading(false);
            }
        };

        loadDashboardData();
    }, [userRole, user]);

    const getStatusVariant = (status: RecentTicket['status']) => {
        switch (status) {
            case 'Aberto': return 'default';
            case 'Em Andamento': return 'secondary';
            case 'Fechado': return 'outline';
            default: return 'default';
        }
    };

    if (loading) {
        return <DashboardSkeleton />;
    }

    return (
        <div className="flex flex-col gap-6 fade-in">
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <StatsCard
                    title="Total de Provedores"
                    value={stats.providerCount}
                    icon={Server}
                    trend={5}
                />
                <StatsCard
                    title="Total de Clientes (App)"
                    value={stats.clientCount}
                    icon={Users}
                    trend={12}
                />
                <StatsCard
                    title="Tickets Abertos"
                    value={stats.openTicketsCount}
                    icon={MessageSquare}
                    trend={-2}
                />
                <StatsCard
                    title="Notificações (24h)"
                    value={stats.notificationCount}
                    icon={Bell}
                />
            </div>

            <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
                <Card className="xl:col-span-1 shadow-sm">
                    <CardHeader>
                        <CardTitle>Clientes por Provedor</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <ClientsChart data={chartData} />
                    </CardContent>
                </Card>
                <Card className="xl:col-span-1 shadow-sm">
                    <CardHeader>
                        <CardTitle>Atividade Recente de Tickets</CardTitle>
                        <CardDescription>Os últimos 5 tickets atualizados.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead>Assunto</TableHead>
                                    <TableHead>Provedor</TableHead>
                                    <TableHead>Status</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {recentTickets.length === 0 ? (
                                    <TableRow>
                                        <TableCell colSpan={3} className="text-center text-muted-foreground">
                                            Nenhum ticket encontrado
                                        </TableCell>
                                    </TableRow>
                                ) : (
                                    recentTickets.map((ticket) => (
                                        <TableRow key={ticket.id} className="cursor-pointer hover:bg-muted/50" onClick={() => navigate(`/tickets/${ticket.id}`)}>
                                            <TableCell className="font-medium">{ticket.subject}</TableCell>
                                            <TableCell>{ticket.providerName}</TableCell>
                                            <TableCell><Badge variant={getStatusVariant(ticket.status)}>{ticket.status}</Badge></TableCell>
                                        </TableRow>
                                    ))
                                )}
                            </TableBody>
                        </Table>
                    </CardContent>
                </Card>
            </div>
        </div>
    );
};
```

---

### `src/pages/ProvidersPage.tsx`
> Lista de provedores

```tsx
// admin-painel/src/pages/ProvidersPage.tsx - VERSÃO CORRIGIDA
import { useState, useEffect, useMemo, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { collection, onSnapshot, doc, setDoc, serverTimestamp } from 'firebase/firestore'; // <-- MUDANÇA AQUI
import { db } from '@/firebase/config'; // <-- MUDANÇA AQUI (removido functions)
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogHeader, AlertDialogTitle, AlertDialogFooter, AlertDialogTrigger, AlertDialogDescription } from "@/components/ui/alert-dialog";
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Trash2, Loader2, Search, Settings, ServerCrash } from 'lucide-react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import AddProviderDialog from '@/components/AddProviderDialog.tsx';
import EditProviderDialog from '@/components/EditProviderDialog.tsx';
import EmptyState from '@/components/EmptyState.tsx';

interface Provider {
    id: string;
    name?: string;
}

const ITEMS_PER_PAGE = 10;

export default function ProvidersPage() {
    const navigate = useNavigate();
    const { user, userRole } = useAuth();
    const [providers, setProviders] = useState<Provider[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentPage, setCurrentPage] = useState(1);

    const fetchProviders = useCallback(() => {
        if (!user || userRole !== 'superAdmin') {
            setLoading(false);
            return () => {};
        }
        setLoading(true);
        const unsubscribe = onSnapshot(collection(db, 'provedores'), (snapshot) => {
            const list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Provider));
            setProviders(list);
            setLoading(false);
        }, () => {
            toast.error("Falha ao carregar provedores.");
            setLoading(false);
        });
        return unsubscribe;
    }, [user, userRole]);

    useEffect(() => {
        const unsubscribe = fetchProviders();
        return () => unsubscribe();
    }, [fetchProviders]);

    const filteredProviders = useMemo(() => providers.filter(p =>
        p.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.id.toLowerCase().includes(searchTerm.toLowerCase())
    ), [providers, searchTerm]);
    
    const pageCount = Math.ceil(filteredProviders.length / ITEMS_PER_PAGE);
    const paginatedProviders = filteredProviders.slice((currentPage - 1) * ITEMS_PER_PAGE, currentPage * ITEMS_PER_PAGE);

    const handleDelete = async (providerToDelete: Provider) => {
        if (!user) return;
        
        const toastId = toast.loading(`Apagando ${providerToDelete.name}...`);
        
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                unsubscribe();
                if (response.result) {
                    toast.success(response.result.message || "Provedor apagado com sucesso!", { id: toastId });
                    // O onSnapshot da 'fetchProviders' irá atualizar a lista automaticamente
                } else {
                    toast.error(`Erro ao apagar: ${response.error}`, { id: toastId });
                }
            }
        });

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'DELETE_PROVIDER',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: { providerId: providerToDelete.id }
            });
        } catch (error: any) {
            toast.error(`Falha ao solicitar a exclusão: ${error.message}`, { id: toastId });
            unsubscribe();
        }
    };

    if (loading) return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin" /></div>;
    if (userRole !== 'superAdmin') return <Card><CardHeader><CardTitle>Acesso Negado</CardTitle></CardHeader></Card>;

    return (
        <TooltipProvider>
            <Card>
                <CardHeader>
                    <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                        <div>
                            <CardTitle>Gerir Provedores</CardTitle>
                            <CardDescription>Adicione, configure ou remova provedores da plataforma.</CardDescription>
                        </div>
                        <div className="flex items-center gap-2 w-full sm:w-auto">
                            <div className="relative w-full sm:w-64">
                                <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                                <Input
                                    type="search"
                                    placeholder="Pesquisar por nome ou ID..."
                                    className="pl-8 w-full"
                                    value={searchTerm}
                                    onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
                                />
                            </div>
                            <AddProviderDialog onUpdate={fetchProviders} />
                        </div>
                    </div>
                </CardHeader>
                <CardContent>
                    {filteredProviders.length === 0 ? (
                        <EmptyState 
                            icon={ServerCrash}
                            title="Nenhum provedor encontrado"
                            description="Adicione um novo provedor para começar a gerir."
                        />
                    ) : (
                        <Table>
                            <TableHeader><TableRow><TableHead>Nome</TableHead><TableHead>ID</TableHead><TableHead className="text-right">Ações</TableHead></TableRow></TableHeader>
                            <TableBody>
                                {paginatedProviders.map((p) => (
                                    <TableRow key={p.id}>
                                        <TableCell className="font-medium cursor-pointer hover:underline" onClick={() => navigate(`/provedores/${p.id}`)}>{p.name}</TableCell>
                                        <TableCell className="cursor-pointer hover:underline" onClick={() => navigate(`/provedores/${p.id}`)}>{p.id}</TableCell>
                                        <TableCell className="text-right">
                                            <div className="flex gap-2 justify-end">
                                                <Tooltip>
                                                    <TooltipTrigger asChild><Button variant="outline" size="sm" onClick={() => navigate(`/provedores/${p.id}`)}><Settings className="h-4 w-4" /></Button></TooltipTrigger>
                                                    <TooltipContent><p>Personalizar App</p></TooltipContent>
                                                </Tooltip>
                                                <EditProviderDialog provider={p} onUpdate={fetchProviders} />
                                                <AlertDialog>
                                                    <Tooltip>
                                                        <TooltipTrigger asChild><AlertDialogTrigger asChild><Button variant="destructive" size="sm"><Trash2 className="h-4 w-4" /></Button></AlertDialogTrigger></TooltipTrigger>
                                                        <TooltipContent><p>Apagar Provedor</p></TooltipContent>
                                                    </Tooltip>
                                                    <AlertDialogContent>
                                                        <AlertDialogHeader>
                                                            <AlertDialogTitle>Tem a certeza?</AlertDialogTitle>
                                                            <AlertDialogDescription>Esta ação é irreversível e irá apagar o provedor e todos os seus utilizadores de painel associados.</AlertDialogDescription>
                                                        </AlertDialogHeader>
                                                        <AlertDialogFooter>
                                                            <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                                            <AlertDialogAction onClick={() => handleDelete(p)}>Sim, apagar</AlertDialogAction>
                                                        </AlertDialogFooter>
                                                    </AlertDialogContent>
                                                </AlertDialog>
                                            </div>
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    )}
                </CardContent>
                {filteredProviders.length > 0 && (
                     <CardFooter className="flex items-center justify-between">
                        <span className="text-sm text-muted-foreground">A exibir {paginatedProviders.length} de {filteredProviders.length} provedores.</span>
                        <div className="flex items-center gap-2">
                            <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}>Anterior</Button>
                            <span className="text-sm">Página {currentPage} de {pageCount > 0 ? pageCount : 1}</span>
                            <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.min(pageCount, p + 1))} disabled={currentPage === pageCount || pageCount === 0}>Próxima</Button>
                        </div>
                    </CardFooter>
                )}
            </Card>
        </TooltipProvider>
    );
};
```

---

### `src/pages/ProviderDetailPage.tsx`
> Detalhes do provedor

```tsx
import { useState, useEffect, useCallback, useRef } from 'react';
import { useParams, Outlet, useNavigate } from 'react-router-dom';
import { doc, onSnapshot, setDoc, collection, serverTimestamp } from 'firebase/firestore';
import { db } from '@/firebase/config';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Loader2, Save } from 'lucide-react';
import { SettingsContext, ProviderData, ProviderConfig } from '@/contexts/SettingsContext';
import { useAuth } from '@/contexts/AuthContext';
import Breadcrumbs from '@/components/Breadcrumbs';

export default function ProviderDetailPage() {
    const { providerId: providerIdFromParams } = useParams<{ providerId: string }>();
    const { user, userRole, providerId: providerIdFromAuth } = useAuth();
    const navigate = useNavigate();

    const providerId = userRole === 'superAdmin' ? providerIdFromParams : providerIdFromAuth;

    const [provider, setProvider] = useState<ProviderData | null>(null);
    const [config, setConfig] = useState<ProviderConfig>({});
    const [loading, setLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);
    
    const hasLoadedInitialConfig = useRef(false);

    useEffect(() => {
        if (!providerId) {
            toast.error("ID do provedor não identificado.");
            setLoading(false);
            return;
        }

        hasLoadedInitialConfig.current = false;

        const docRef = doc(db, "provedores", providerId);
        const unsubscribe = onSnapshot(docRef, (docSnap) => {
            if (docSnap.exists()) {
                const data = docSnap.data() as ProviderData;
                setProvider(data);
                
                const mergedConfig = {
                    themeColor: data.themeColor,
                    secondaryColor: data.secondaryColor,
                    logoUrl: data.logoUrl,
                    socialNetworks: data.socialNetworks,
                    integrations: data.integrations,
                    menuConfig: data.menuConfig,
                    tips: data.tips || data.dicas, 
                    faq: data.faq,
                    imageCarousel: data.imageCarousel,
                    ...(data.config || {})
                };

                if (!hasLoadedInitialConfig.current) {
                    setConfig(mergedConfig);
                    hasLoadedInitialConfig.current = true; 
                }
            } else {
                toast.error("Provedor não encontrado.");
                if (userRole === 'superAdmin') navigate('/provedores');
            }
            setLoading(false);
        }, (error) => {
            toast.error(`Erro ao buscar provedor: ${error.message}`);
            setLoading(false);
        });
        return () => unsubscribe();
    }, [providerId, navigate, userRole]);

    const handleSave = useCallback(async () => {
        if (!providerId || !user) return;
        setIsSaving(true);
        const toastId = toast.loading("Salvando configurações...");
        
        // --- CORREÇÃO DO ERRO FIREBASE ---
        // Remove qualquer campo 'undefined' do objeto config antes de enviar.
        // O Firebase não aceita 'undefined'. O JSON stringify/parse é um truque rápido para limpar isso.
        const cleanConfig = JSON.parse(JSON.stringify(config));
        // ----------------------------------

        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                unsubscribe();
                const response = docSnap.data();
                if (response.result) {
                    toast.success("Configurações salvas com sucesso!", { id: toastId });
                } else {
                    console.error("Erro do Backend:", response.error);
                    toast.error(`Erro ao salvar. Verifique o console.`, { id: toastId });
                }
                setIsSaving(false);
            }
        });

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'UPDATE_PROVIDER_CONFIG',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: { 
                    providerId, 
                    config: cleanConfig, // Envia a versão limpa
                    requesterUid: user.uid 
                }
            });
        } catch (error: any) {
            toast.error(`Erro ao solicitar a gravação: ${error.message}`);
            setIsSaving(false);
            unsubscribe();
        }
    }, [providerId, user, config]);

    if (loading) {
        return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin h-8 w-8 text-primary" /></div>;
    }

    if (!provider) {
        return <div className="text-center p-8"><h2 className="text-xl font-semibold text-destructive">Não foi possível carregar os dados.</h2></div>;
    }

    const providerIdString = providerId ?? 'firebase'; 

    return (
        <SettingsContext.Provider value={{ config, setConfig, providerId: providerIdString, provider, loading, saveConfig: handleSave, isSaving }}>
            <div className="space-y-6 h-full flex flex-col">
                <div className="flex flex-col gap-4 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-40 py-2 -mx-4 px-4 border-b md:static md:border-none md:p-0 md:mx-0">
                    <div className="flex items-center justify-between">
                        <div>
                            <Breadcrumbs />
                            <h1 className="text-2xl md:text-3xl font-bold truncate">Personalização: {provider.name}</h1>
                        </div>
                        <Button 
                            onClick={handleSave} 
                            disabled={isSaving} 
                            className={`shrink-0 shadow-lg transition-all ${isSaving ? 'opacity-80' : 'hover:ring-2 hover:ring-primary/50'}`}
                        >
                            {isSaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
                            <span className="hidden sm:inline">Salvar Alterações</span>
                            <span className="sm:hidden">Salvar</span>
                        </Button>
                    </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-start flex-1">
                    <div className="lg:col-span-2 space-y-6 order-2 lg:order-1 pb-10">
                        <Outlet />
                    </div>
                </div>
            </div>
        </SettingsContext.Provider>
    );
}
```

---

### `src/pages/UsersPage.tsx`
> Gerenciamento de usuários

```tsx
// admin-painel/src/pages/UsersPage.tsx - VERSÃO FINAL MIGRADA
import { useState, useEffect, useMemo, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card";
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Loader2, Trash2, UserX, Search } from 'lucide-react';
import AddAdminDialog from '@/components/AddAdminDialog.tsx';
import SetSuperAdminDialog from '@/components/SetSuperAdminDialog.tsx'; // <-- ADICIONADO
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog";
import EmptyState from '@/components/EmptyState.tsx';

interface AdminUser {
    uid: string;
    email?: string;
    superAdmin: boolean;
    providerId?: string;
}

const ITEMS_PER_PAGE = 10;

export default function UsersPage() {
    const { user, userRole } = useAuth();
    const [users, setUsers] = useState<AdminUser[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentPage, setCurrentPage] = useState(1);

    const fetchUsers = useCallback(() => {
        if (userRole !== 'superAdmin' || !user) {
            setLoading(false);
            return () => {};
        }
        setLoading(true);
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                if (response.result && response.result.users) {
                    setUsers(response.result.users);
                } else if (response.error) {
                    toast.error(`Falha ao carregar utilizadores: ${response.error}`);
                }
                setLoading(false);
                unsubscribe();
            }
        });

        const triggerFunction = async () => {
            try {
                const requestDocRef = doc(db, 'function_requests', requestId);
                await setDoc(requestDocRef, {
                    type: 'LIST_ADMIN_USERS',
                    requesterUid: user.uid,
                    createdAt: serverTimestamp(),
                });
            } catch (error: any) {
                toast.error(`Falha ao solicitar lista de utilizadores: ${error.message}`);
                setLoading(false);
                unsubscribe();
            }
        };
        triggerFunction();
        return unsubscribe;
    }, [userRole, user]);

    useEffect(() => {
        const unsubscribe = fetchUsers();
        return () => {
            if (unsubscribe) unsubscribe();
        };
    }, [fetchUsers]);

    const filteredUsers = useMemo(() => users.filter(u =>
        u.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.providerId?.toLowerCase().includes(searchTerm.toLowerCase())
    ), [users, searchTerm]);

    const pageCount = Math.ceil(filteredUsers.length / ITEMS_PER_PAGE);
    const paginatedUsers = filteredUsers.slice((currentPage - 1) * ITEMS_PER_PAGE, currentPage * ITEMS_PER_PAGE);

    const handleDelete = async (userToDelete: AdminUser) => {
        if (!user) return;
        const toastId = toast.loading(`Apagando ${userToDelete.email}...`);
        
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                unsubscribe();
                if (response.result) {
                    toast.success(response.result.message || "Utilizador apagado com sucesso!", { id: toastId });
                    fetchUsers();
                } else {
                    toast.error(`Erro ao apagar: ${response.error}`, { id: toastId });
                }
            }
        });

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'DELETE_ADMIN_USER',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: { uid: userToDelete.uid, requesterUid: user.uid }
            });
        } catch (error: any) {
            toast.error(`Falha ao solicitar a exclusão: ${error.message}`, { id: toastId });
            unsubscribe();
        }
    };

    if (loading) return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin" /></div>;
    if (userRole !== 'superAdmin') return <Card><CardHeader><CardTitle>Acesso Negado</CardTitle></CardHeader></Card>;

    return (
        <Card>
            <CardHeader>
                <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                    <div>
                        <CardTitle>Gerir Utilizadores</CardTitle>
                        <CardDescription>Adicione ou remova administradores do painel.</CardDescription>
                    </div>
                    <div className="flex flex-wrap items-center gap-2 w-full sm:w-auto">
                        <div className="relative w-full sm:w-auto flex-grow">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder="Pesquisar por email ou ID..."
                                className="pl-8 w-full"
                                value={searchTerm}
                                onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
                            />
                        </div>
                        <SetSuperAdminDialog onUpdate={fetchUsers} /> {/* <-- ADICIONADO */}
                        <AddAdminDialog onUpdate={fetchUsers} />
                    </div>
                </div>
            </CardHeader>
            <CardContent>
                {filteredUsers.length === 0 ? (
                    <EmptyState
                        icon={UserX}
                        title="Nenhum utilizador encontrado"
                        description="Adicione um novo utilizador para começar a gerir."
                    />
                ) : (
                    <Table>
                        <TableHeader><TableRow><TableHead>Email</TableHead><TableHead>Permissão</TableHead><TableHead className="text-right">Ações</TableHead></TableRow></TableHeader>
                        <TableBody>
                            {paginatedUsers.map((u) => (
                                <TableRow key={u.uid}>
                                    <TableCell className="font-medium">{u.email}</TableCell>
                                    <TableCell>{u.superAdmin ? <Badge>Super Admin</Badge> : <Badge variant="secondary">Admin de {u.providerId}</Badge>}</TableCell>
                                    <TableCell className="text-right">
                                        {user?.uid !== u.uid && (
                                            <AlertDialog>
                                                <AlertDialogTrigger asChild><Button variant="destructive" size="sm"><Trash2 className="h-4 w-4" /></Button></AlertDialogTrigger>
                                                <AlertDialogContent>
                                                    <AlertDialogHeader><AlertDialogTitle>Tem a certeza?</AlertDialogTitle><AlertDialogDescription>Esta ação é irreversível.</AlertDialogDescription></AlertDialogHeader>
                                                    <AlertDialogFooter>
                                                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                                        <AlertDialogAction onClick={() => handleDelete(u)}>Sim, apagar</AlertDialogAction>
                                                    </AlertDialogFooter>
                                                </AlertDialogContent>
                                            </AlertDialog>
                                        )}
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                )}
            </CardContent>
             {filteredUsers.length > 0 && (
                <CardFooter className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">A exibir {paginatedUsers.length} de {filteredUsers.length} utilizadores.</span>
                    <div className="flex items-center gap-2">
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}>Anterior</Button>
                        <span className="text-sm">Página {currentPage} de {pageCount > 0 ? pageCount : 1}</span>
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.min(pageCount, p + 1))} disabled={currentPage === pageCount || pageCount === 0}>Próxima</Button>
                    </div>
                </CardFooter>
            )}
        </Card>
    );
}
```

## 👤 Páginas do Provedor


---

### `src/pages/provider/ProviderDashboardPage.tsx`
> Dashboard do provedor

```tsx
import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { toast } from "sonner";
import { doc, setDoc, onSnapshot, serverTimestamp, collection, Timestamp } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Users, MessageSquare } from "lucide-react";
import { ProviderDashboardSkeleton } from '@/components/ProviderDashboardSkeleton';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';

interface RecentTicket {
    id: string;
    subject: string;
    status: 'Aberto' | 'Em Andamento' | 'Fechado';
    updatedAt?: Timestamp;
}

export default function ProviderDashboardPage() {
    const navigate = useNavigate();
    const { user, providerId } = useAuth();
    const [stats, setStats] = useState({ totalClients: 0, openTicketsCount: 0 });
    const [recentTickets, setRecentTickets] = useState<RecentTicket[]>([]);
    const [loading, setLoading] = useState(true);

    const fetchDashboardData = useCallback(() => {
        if (!providerId || !user) {
            setLoading(false);
            return () => {};
        }

        setLoading(true);
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                if (response.result) {
                    setStats(response.result.stats || { totalClients: 0, openTicketsCount: 0 });
                    setRecentTickets(response.result.recentTickets || []);
                } else if (response.error) {
                    toast.error(`Erro no Dashboard: ${response.error}`);
                }
                setLoading(false);
                unsubscribe();
            }
        });

        const triggerFunction = async () => {
            try {
                await setDoc(doc(db, 'function_requests', requestId), {
                    type: 'GET_PROVIDER_DASHBOARD_DATA',
                    requesterUid: user.uid,
                    createdAt: serverTimestamp(),
                    payload: { providerId, requesterUid: user.uid }
                });
            } catch (error: any) {
                toast.error(`Falha ao solicitar dados: ${error.message}`);
                setLoading(false);
                unsubscribe();
            }
        };

        triggerFunction();
        return unsubscribe;
    }, [providerId, user]);

    useEffect(() => {
        const unsubscribe = fetchDashboardData();
        return () => {
            if (unsubscribe) unsubscribe();
        };
    }, [fetchDashboardData]);

    const getStatusVariant = (status: RecentTicket['status']) => {
        switch (status) {
            case 'Aberto': return 'default';
            case 'Em Andamento': return 'secondary';
            case 'Fechado': return 'outline';
            default: return 'default';
        }
    };

    if (loading) {
        return <ProviderDashboardSkeleton />;
    }

    return (
        <div className="flex flex-col gap-6">
            <h1 className="text-3xl font-bold tracking-tight">Dashboard do Provedor</h1>
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium">Clientes Ativos (Sincronizados)</CardTitle>
                        <Users className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold">{stats.totalClients}</div>
                    </CardContent>
                </Card>
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium">Tickets de Suporte Abertos</CardTitle>
                        <MessageSquare className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold">{stats.openTicketsCount}</div>
                    </CardContent>
                </Card>
            </div>
            <Card>
                <CardHeader>
                    <CardTitle>Atividade Recente de Tickets</CardTitle>
                    <CardDescription>Os seus 5 tickets de suporte mais recentes.</CardDescription>
                </CardHeader>
                <CardContent>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>Assunto</TableHead>
                                <TableHead>Status</TableHead>
                                <TableHead>Última Atualização</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {recentTickets.map((ticket) => (
                                <TableRow key={ticket.id} className="cursor-pointer" onClick={() => navigate(`/provedor/tickets/${ticket.id}`)}>
                                    <TableCell className="font-medium">{ticket.subject}</TableCell>
                                    <TableCell><Badge variant={getStatusVariant(ticket.status)}>{ticket.status}</Badge></TableCell>
                                    <TableCell>
                                        {ticket.updatedAt ? format(ticket.updatedAt.toDate(), "dd/MM/yyyy 'às' HH:mm", { locale: ptBR }) : 'N/A'}
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                </CardContent>
            </Card>
        </div>
    );
}
```

---

### `src/pages/provider/ProviderClientsPage.tsx`
> Clientes do provedor

```tsx
import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Loader2, UserX, Search, RefreshCw } from 'lucide-react';
import EmptyState from '@/components/EmptyState';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';

interface SgpClient {
    id: number;
    nome: string;
    cpfcnpj: string;
    contratos: { id: number; status: string }[];
}

const ITEMS_PER_PAGE = 25;

// Hook para "atrasar" a busca e não fazer uma requisição a cada tecla digitada
function useDebounce(value: string, delay: number) {
    const [debouncedValue, setDebouncedValue] = useState(value);
    useEffect(() => {
        const handler = setTimeout(() => {
            setDebouncedValue(value);
        }, delay);
        return () => {
            clearTimeout(handler);
        };
    }, [value, delay]);
    return debouncedValue;
}

export default function ProviderClientsPage() {
    const navigate = useNavigate();
    const { user, providerId } = useAuth();
    const [clients, setClients] = useState<SgpClient[]>([]);
    const [loading, setLoading] = useState(true);
    const [isSyncing, setIsSyncing] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentPage, setCurrentPage] = useState(1);
    const [totalClients, setTotalClients] = useState(0);

    const debouncedSearchTerm = useDebounce(searchTerm, 300); // Aguarda 300ms após o usuário parar de digitar
    const pageCount = Math.ceil(totalClients / ITEMS_PER_PAGE);

    const callProxy = useCallback(async (action: 'sync' | 'get', page = 1, search = '') => {
        if (!providerId || !user) return;

        const isSyncAction = action === 'sync';
        if (isSyncAction) {
            setIsSyncing(true);
            toast.info("Iniciando sincronização... Isso pode levar vários minutos. Por favor, aguarde.");
        } else {
            setLoading(true);
        }

        const offset = (page - 1) * ITEMS_PER_PAGE;
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                unsubscribe();
                const response = docSnap.data();

                if (response.error) {
                    toast.error(isSyncAction ? "Falha na sincronização" : "Falha ao carregar clientes", { description: response.error });
                } else if (response.result) {
                    if (isSyncAction) {
                        toast.success("Sincronização concluída!", { description: `${response.result.count} clientes foram salvos.` });
                        setSearchTerm(''); // Limpa a busca após sincronizar
                        setCurrentPage(1);
                        callProxy('get', 1, ''); // Recarrega a primeira página
                    } else {
                        setClients(response.result.clientes || []);
                        setTotalClients(response.result.paginacao?.total || 0);
                    }
                }
                setLoading(false);
                setIsSyncing(false);
            }
        });

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'SGP_API_PROXY',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: {
                    providerId,
                    requesterUid: user.uid,
                    action: action,
                    params: isSyncAction ? {
                        limit: 100,
                        offset: 0,
                        contrato_status: 1,
                        omitir_titulos: 1
                    } : {
                        limit: ITEMS_PER_PAGE,
                        offset: offset,
                        searchTerm: search
                    }
                }
            });
        } catch (error: any) {
            toast.error("Erro ao disparar a função.", { description: error.message });
            setLoading(false);
            setIsSyncing(false);
            unsubscribe();
        }
    }, [providerId, user]);

    // Efeito para buscar os clientes do cache ao carregar ou mudar de página/busca
    useEffect(() => {
        if (!isSyncing) {
            callProxy('get', currentPage, debouncedSearchTerm);
        }
    }, [currentPage, debouncedSearchTerm, callProxy, isSyncing]);

    // Handler para o input de busca
    const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        setSearchTerm(event.target.value);
        setCurrentPage(1); // Volta para a primeira página sempre que uma nova busca é feita
    };

    if (loading && clients.length === 0) {
        return (
            <div className="flex flex-col justify-center items-center h-full text-center">
                <Loader2 className="animate-spin h-8 w-8 mb-4" />
                <p className="text-lg font-semibold">Carregando clientes do cache...</p>
            </div>
        );
    }

    return (
        <Card>
            <CardHeader>
                <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
                    <div>
                        <CardTitle>Clientes Ativos (SGP)</CardTitle>
                        <CardDescription>
                            {totalClients > 0 ? `Encontrados ${totalClients} clientes no total.` : "Nenhum cliente sincronizado."}
                        </CardDescription>
                    </div>
                    <div className="flex w-full sm:w-auto items-center gap-4">
                        <div className="relative flex-grow sm:flex-grow-0 sm:w-64">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder={`Pesquisar em ${totalClients} clientes...`}
                                className="pl-8 w-full"
                                value={searchTerm}
                                onChange={handleSearchChange}
                            />
                        </div>
                        <Button onClick={() => callProxy('sync')} disabled={isSyncing} variant="outline">
                            {isSyncing ? <Loader2 className="mr-2 h-4 w-4 animate-spin"/> : <RefreshCw className="mr-2 h-4 w-4" />}
                            Sincronizar
                        </Button>
                    </div>
                </div>
            </CardHeader>
            <CardContent>
                {loading ? (
                    <div className="flex justify-center items-center h-64"><Loader2 className="animate-spin h-8 w-8" /></div>
                ) : clients.length === 0 ? (
                    <EmptyState
                        icon={UserX}
                        title={searchTerm ? "Nenhum resultado para sua busca" : "Nenhum Cliente no Cache"}
                        description={searchTerm ? `Não foram encontrados clientes com o termo "${searchTerm}". Limpe a busca para ver todos.` : "Clique em 'Sincronizar' para buscar os dados do SGP."}
                    />
                ) : (
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>ID</TableHead>
                                <TableHead>Nome</TableHead>
                                <TableHead>CPF/CNPJ</TableHead>
                                <TableHead>Contratos</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {clients.map((client) => (
                                <TableRow 
                                    key={client.id} 
                                    className="cursor-pointer hover:bg-muted" 
                                    // CORREÇÃO: Passa o CPF/CNPJ (ID do documento no Firestore)
                                    onClick={() => navigate(`/provedor/clientes/${client.cpfcnpj}`)}
                                >
                                    <TableCell>{client.id}</TableCell>
                                    <TableCell className="font-medium">{client.nome}</TableCell>
                                    <TableCell>{client.cpfcnpj}</TableCell>
                                    <TableCell>{client.contratos && client.contratos.map((c: any) => c.id).join(', ')}</TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                )}
            </CardContent>
            {pageCount > 1 && (
                <CardFooter className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">
                        Página {currentPage} de {pageCount}
                    </span>
                    <div className="flex items-center gap-2">
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1 || loading}>Anterior</Button>
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.min(pageCount, p + 1))} disabled={currentPage === pageCount || loading}>Próxima</Button>
                    </div>
                </CardFooter>
            )}
        </Card>
    );
}
```

---

### `src/pages/provider/ClientDetailPage.tsx`
> Detalhes do cliente

```tsx
import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useApi } from '@/hooks/useApi';
import { toast } from 'sonner';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Loader2, ArrowLeft, UserCircle, AlertTriangle } from 'lucide-react';

interface ClientData {
    id: string; // ID interno do SGP
    nome: string;
    cpfcnpj: string;
    userStatus: string; // Inferido do contrato retornado pelo proxy
    userPlan: string;
    providerId: string;
    contratos?: any[];
    [key: string]: any; 
}

export default function ClientDetailPage() {
    // Espera o ID interno do SGP na URL (ex: 407)
    const { clientId: sgpClientId } = useParams<{ clientId: string }>(); 
    const navigate = useNavigate();
    const { user, userRole, providerId } = useAuth();
    const { callFunction, loading } = useApi();
    const [client, setClient] = useState<ClientData | null>(null);
    const [isLoadingClient, setIsLoadingClient] = useState(true);

    // 1. Fetch Client Details (Via Proxy SGP, para obter detalhes do cache)
    useEffect(() => {
        // Se o painel não sabe de qual provedor é, ou o ID do cliente está faltando
        if (!sgpClientId || !providerId || !user) {
            setIsLoadingClient(false);
            return;
        }

        const fetchDetails = async () => {
            try {
                // Chamamos o proxy para buscar do CACHE SQLite usando o ID INTERNO do SGP
                const result = await callFunction('SGP_API_PROXY', {
                    providerId: providerId,
                    action: 'get_single', // Ação para buscar cliente único no cache (Proxy ROTA 3)
                    params: { 
                        clientId: sgpClientId // Passamos o ID interno do SGP
                    }
                });
                
                if (result && result.cpfcnpj) {
                    // O resultado do proxy é um objeto cliente (id, nome, cpfcnpj, contratos)
                    // Tentamos inferir status/plano do primeiro contrato, se disponível no cache.
                    const firstContract = result.contratos?.[0] || {};

                    setClient({
                         ...result,
                         id: sgpClientId, // ID SGP
                         providerId: providerId,
                         userStatus: firstContract.contratoStatusDisplay || 'N/A',
                         userPlan: firstContract.servico_plano || 'N/A',
                         // Garantir que a chave cpfcnpj está lá
                         cpfcnpj: result.cpfcnpj,
                         // O campo 'contratos' já vem no result.
                    });
                } else {
                    toast.error("Cliente não encontrado no cache.");
                }
            } catch (error: any) {
                toast.error(error.message || "Falha ao carregar detalhes do cliente do cache SGP.");
            } finally {
                setIsLoadingClient(false);
            }
        };

        fetchDetails();
    }, [sgpClientId, user, providerId, callFunction]);

    const handleDeleteClient = async () => {
        // A exclusão de cliente envolve a remoção do documento na coleção 'clientes' do Firestore,
        // cujo ID é o CPF/CNPJ (limpo), e não o ID SGP. 
        // O cliente.cpfcnpj está no formato que veio do cache SGP (pode ter formatação ou não).

        if (!client || !window.confirm(`Tem certeza que deseja apagar o cliente ${client.nome}? Isso só remove o registro do app/FCM/cache.`)) {
            return;
        }
        
        // CORREÇÃO DE SEGURANÇA: Limpar o CPF/CNPJ antes de tentar apagar o documento do Firestore
        const cleanCpfCnpj = client.cpfcnpj ? client.cpfcnpj.replace(/[^0-9]/g, '') : null;

        if (!cleanCpfCnpj) {
             toast.error("Não foi possível apagar: CPF/CNPJ inválido.");
             return;
        }

        try {
            await callFunction('DELETE_CLIENT', {
                // Ao apagar, passamos o CPF/CNPJ limpo (ID do documento no Firestore)
                clientId: cleanCpfCnpj, 
                providerId: client.providerId, 
            });
            
            navigate('/provedor/clientes');
        } catch (error: any) {
             // O toast de erro já é tratado no useApi
        }
    };
    

    if (isLoadingClient || loading) {
        return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin" /></div>;
    }

    if (!client) {
        return (
            <Card>
                <CardHeader><CardTitle>Cliente Não Encontrado</CardTitle></CardHeader>
                <CardContent className="flex flex-col items-center gap-4">
                    <AlertTriangle className="h-12 w-12 text-destructive" />
                    <p>O ID do cliente {sgpClientId} é inválido ou não foi encontrado no cache local.</p>
                    <Button onClick={() => navigate(-1)}>Voltar</Button>
                </CardContent>
            </Card>
        );
    }
    
    // O ID na URL é o ID SGP, mas o CPF/CNPJ formatado é exibido
    const clientCpfCnpjDisplay = client.cpfcnpj || 'N/A';
    const isSuperAdmin = userRole === 'superAdmin';

    return (
        <div className="flex flex-col gap-6">
            <div className="flex items-center justify-between">
                <Button variant="outline" onClick={() => navigate(-1)} className="gap-2">
                    <ArrowLeft className="h-4 w-4" /> Voltar
                </Button>
                <Button variant="destructive" onClick={handleDeleteClient} disabled={loading}>
                     {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : "Apagar Cliente (App/FCM)"}
                </Button>
            </div>

            <Card>
                <CardHeader className="flex flex-row items-center space-y-0 pb-2">
                    <UserCircle className="h-6 w-6 mr-3 text-primary" />
                    <CardTitle className="text-2xl">{client.nome}</CardTitle>
                </CardHeader>
                <CardContent className="grid gap-4 pt-4">
                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-1">
                            <p className="text-sm font-medium text-muted-foreground">CPF/CNPJ</p>
                            <p className="font-bold">{clientCpfCnpjDisplay}</p>
                        </div>
                        <div className="space-y-1">
                            <p className="text-sm font-medium text-muted-foreground">Status</p>
                            <p className={`font-bold ${client.userStatus === 'Ativo' ? 'text-green-500' : 'text-red-500'}`}>{client.userStatus}</p>
                        </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-1">
                            <p className="text-sm font-medium text-muted-foreground">Plano</p>
                            <p className="font-bold">{client.userPlan}</p>
                        </div>
                        <div className="space-y-1">
                            <p className="text-sm font-medium text-muted-foreground">ID SGP / Provedor</p>
                            <p className="font-bold">{client.id} / {client.providerId} {isSuperAdmin && `(${client.providerId})`}</p>
                        </div>
                    </div>

                    <h3 className="text-xl font-semibold mt-4 border-t pt-4">Dados Técnicos (Cache SGP)</h3>
                    
                    <Card className="bg-muted/50 p-4">
                        <pre className="text-xs overflow-auto max-h-[300px]">
                            {JSON.stringify(client.contratos || client, null, 2)}
                        </pre>
                    </Card>

                </CardContent>
            </Card>
        </div>
    );
}
```

---

### `src/pages/provider/ProviderTicketsPage.tsx`
> Tickets do provedor

```tsx
import { useState, useEffect, useMemo } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useApi } from '@/hooks/useApi';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from '@/components/ui/badge';
import { Loader2, MessageSquare, Search } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button'; // <--- IMPORT CORRIGIDO
import AddTicketDialog from '@/components/AddTicketDialog';
import EmptyState from '@/components/EmptyState';

interface Ticket {
    id: string;
    subject: string;
    createdBy: string; // Email do cliente ou CPF/CNPJ
    status: 'Aberto' | 'Em Andamento' | 'Fechado';
    updatedAt: { seconds: number; nanoseconds: number };
}

const ITEMS_PER_PAGE = 10;

export default function ProviderTicketsPage() {
    const navigate = useNavigate();
    // userRole e loading removidos daqui para resolver TS6133, pois são usados no useApi
    const { user, providerId } = useAuth(); 
    const { callFunction, loading: isApiLoading } = useApi();
    const [tickets, setTickets] = useState<Ticket[]>([]);
    const [isLoadingTickets, setIsLoadingTickets] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentPage, setCurrentPage] = useState(1);

    const fetchTickets = async () => {
        if (!providerId || !user) {
            setIsLoadingTickets(false);
            return;
        }
        setIsLoadingTickets(true);
        try {
            const result = await callFunction('GET_PROVIDER_TICKETS', { providerId });
            const formattedTickets: Ticket[] = (result?.tickets || []).map((t: any) => ({
                ...t,
                id: t.id,
                // Garantir o updatedAt no formato esperado
            }));
            setTickets(formattedTickets);
        } catch (error) {
            toast.error("Falha ao carregar a lista de tickets.");
        } finally {
            setIsLoadingTickets(false);
        }
    };

    useEffect(() => {
        fetchTickets();
    }, [providerId, user, callFunction]);

    const filteredTickets = useMemo(() => tickets.filter(t =>
        t.subject.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t.createdBy.toLowerCase().includes(searchTerm.toLowerCase())
    ), [tickets, searchTerm]);

    const pageCount = Math.ceil(filteredTickets.length / ITEMS_PER_PAGE);
    const paginatedTickets = filteredTickets.slice((currentPage - 1) * ITEMS_PER_PAGE, currentPage * ITEMS_PER_PAGE);

    const getStatusVariant = (status: Ticket['status']) => {
        switch (status) {
            case 'Aberto': return 'default';
            case 'Em Andamento': return 'secondary';
            case 'Fechado': return 'outline';
            default: return 'default';
        }
    };
    
    // Simulação da busca do nome do provedor (necessário para a prop providerName do AddTicketDialog)
    // Em um cenário real, você buscaria isso do Firestore ou do AuthContext.
    const mockProviderName = "Nome do Provedor"; 
    
    if (isLoadingTickets) {
        return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin" /></div>;
    }

    return (
        <Card>
            <CardHeader>
                <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                    <div>
                        <CardTitle>Tickets de Suporte</CardTitle>
                        <CardDescription>Gerencie as solicitações de suporte dos seus clientes.</CardDescription>
                    </div>
                    <div className="flex items-center gap-2 w-full sm:w-auto">
                        <div className="relative w-full sm:w-64">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder="Pesquisar por assunto ou cliente..."
                                className="pl-8 w-full"
                                value={searchTerm}
                                onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
                            />
                        </div>
                        {/* CORRIGIDO: Passando providerName e onTicketCreated */}
                        <AddTicketDialog 
                            providerName={mockProviderName} 
                            onTicketCreated={fetchTickets} 
                        />
                    </div>
                </div>
            </CardHeader>
            <CardContent>
                {filteredTickets.length === 0 ? (
                    <EmptyState
                        icon={MessageSquare}
                        title="Nenhum ticket encontrado"
                        description="Nenhum ticket corresponde à sua pesquisa ou a lista está vazia."
                    />
                ) : (
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>ID</TableHead>
                                <TableHead>Assunto</TableHead>
                                <TableHead>Cliente</TableHead>
                                <TableHead className="text-center">Status</TableHead>
                                <TableHead className="text-right">Última Atualização</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {paginatedTickets.map((ticket) => (
                                <TableRow 
                                    key={ticket.id} 
                                    className="cursor-pointer hover:bg-muted/50" 
                                    onClick={() => navigate(`/provedor/tickets/${ticket.id}`)}
                                >
                                    <TableCell className="font-medium text-xs text-muted-foreground">{ticket.id.substring(0, 8)}</TableCell>
                                    <TableCell className="font-medium">{ticket.subject}</TableCell>
                                    <TableCell>{ticket.createdBy}</TableCell>
                                    <TableCell className="text-center">
                                        <Badge variant={getStatusVariant(ticket.status)}>{ticket.status}</Badge>
                                    </TableCell>
                                    <TableCell className="text-right">
                                        {ticket.updatedAt ? new Date(ticket.updatedAt.seconds * 1000).toLocaleString('pt-BR') : 'N/A'}
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                )}
            </CardContent>
            {filteredTickets.length > 0 && (
                <div className="flex items-center justify-between px-6 py-4 border-t">
                    <span className="text-sm text-muted-foreground">A exibir {paginatedTickets.length} de {filteredTickets.length} tickets.</span>
                    <div className="flex items-center gap-2">
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}>Anterior</Button>
                        <span className="text-sm">Página {currentPage} de {pageCount > 0 ? pageCount : 1}</span>
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.min(pageCount, p + 1))} disabled={currentPage === pageCount || pageCount === 0}>Próxima</Button>
                    </div>
                </div>
            )}
        </Card>
    );
}
```

---

### `src/pages/provider/NotificationSenderPage.tsx`
> Envio de notificações push

```tsx
import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { useApi } from '@/hooks/useApi';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Send, Loader2 } from 'lucide-react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
// Import de useEffect removido - TS6133

// Tipos de Filtro (MOCK, na realidade deveriam vir de uma API de lista de planos/status)
const statusOptions = [
    { value: 'all', label: 'Todos os Status' },
    { value: 'Ativo', label: 'Ativos' },
    { value: 'Suspenso', label: 'Suspensos (Inadimplentes)' },
    { value: 'Ativo V. Reduzida', label: 'Ativos (Velocidade Reduzida)' },
    { value: 'Cancelado', label: 'Cancelados' },
];

const planOptions = [
    { value: 'all', label: 'Todos os Planos' },
    { value: 'VIBE 500 MEGA', label: 'VIBE 500 MEGA' },
    { value: 'VIBE 1 GIGA', label: 'VIBE 1 GIGA' },
    { value: 'ECONOMICO 100', label: 'ECONOMICO 100' },
];

export default function NotificationSenderPage() {
    const [title, setTitle] = useState('');
    const [body, setBody] = useState('');
    const [statusFilter, setStatusFilter] = useState('all');
    const [planFilter, setPlanFilter] = useState('all');

    const { callFunction, loading } = useApi();
    const { providerId, user } = useAuth();
    
    const handleSendNotification = async () => {
        if (!user) {
            toast.error("Erro de Autenticação", { description: "Usuário não autenticado." });
            return;
        }
        if (!title.trim() || !body.trim()) {
            toast.error("Erro de Validação", { description: "O título e a mensagem não podem estar vazios." });
            return;
        }

        try {
            await callFunction('SEND_SCOPED_NOTIFICATION_SEGMENTED', {
                // O providerId é incluído, mas o hook useApi o sobrescreverá com o ID do token para garantir segurança.
                providerId, 
                title,
                body,
                statusFilter: statusFilter,
                planFilter: planFilter,
            });
            
            // Limpa após o sucesso
            setTitle('');
            setBody('');
            setStatusFilter('all');
            setPlanFilter('all');
            
        } catch (error) {
            // O hook useApi já trata os erros com toast.
        }
    };

    return (
        <Card>
            <CardHeader>
                <CardTitle>Enviar Notificação Push Segmentada</CardTitle>
                <CardDescription>
                    Envie uma mensagem para clientes específicos do seu provedor que têm o aplicativo instalado.
                </CardDescription>
            </CardHeader>
            <CardContent>
                <div className="grid gap-6">
                    
                    <div className="grid gap-4 sm:grid-cols-2">
                        {/* Filtro por Status */}
                        <div className="grid gap-2">
                            <Label htmlFor="statusFilter">Filtrar por Status</Label>
                            <Select value={statusFilter} onValueChange={setStatusFilter} disabled={loading}>
                                <SelectTrigger id="statusFilter">
                                    <SelectValue placeholder="Selecione um status" />
                                </SelectTrigger>
                                <SelectContent>
                                    {statusOptions.map(option => (
                                        <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>
                        
                        {/* Filtro por Plano */}
                        <div className="grid gap-2">
                            <Label htmlFor="planFilter">Filtrar por Plano</Label>
                            <Select value={planFilter} onValueChange={setPlanFilter} disabled={loading}>
                                <SelectTrigger id="planFilter">
                                    <SelectValue placeholder="Selecione um plano" />
                                </SelectTrigger>
                                <SelectContent>
                                    {planOptions.map(option => (
                                        <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>
                    </div>
                    
                    <div className="grid gap-2">
                        <Label htmlFor="title">Título da Notificação</Label>
                        <Input
                            id="title"
                            placeholder="Ex: Aviso Importante (máx. 50 caracteres)"
                            value={title}
                            onChange={(e) => setTitle(e.target.value.substring(0, 50))}
                            disabled={loading}
                        />
                    </div>
                    <div className="grid gap-2">
                        <Label htmlFor="body">Mensagem</Label>
                        <Textarea
                            id="body"
                            placeholder="Digite sua mensagem aqui..."
                            value={body}
                            onChange={(e) => setBody(e.target.value)}
                            rows={5}
                            disabled={loading}
                        />
                    </div>
                    <Button onClick={handleSendNotification} disabled={loading}>
                        {loading ? (
                            <>
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                Enviando...
                            </>
                        ) : (
                            <>
                                <Send className="mr-2 h-4 w-4" />
                                Enviar Notificação
                            </>
                        )}
                    </Button>
                </div>
            </CardContent>
        </Card>
    );
}
```

---

### `src/pages/provider/MyCompanyPage.tsx`
> Dados da empresa

```tsx
import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { doc, setDoc, onSnapshot, serverTimestamp, collection, getDoc } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Loader2 } from 'lucide-react';

interface CompanyDetails {
    razaoSocial?: string;
    nomeFantasia?: string;
    cnpj?: string;
    email?: string;
    telefone?: string;
}

export default function MyCompanyPage() {
    const { user, providerId } = useAuth();
    const [details, setDetails] = useState<CompanyDetails>({});
    const [loading, setLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);

    useEffect(() => {
        if (!providerId) return;

        const providerRef = doc(db, 'provedores', providerId);
        const unsubscribe = onSnapshot(providerRef, (docSnap) => {
            if (docSnap.exists()) {
                setDetails(docSnap.data().details || {});
            }
            setLoading(false);
        });

        return () => unsubscribe();
    }, [providerId]);

    const handleDetailChange = (key: keyof CompanyDetails, value: string) => {
        setDetails(prev => ({ ...prev, [key]: value }));
    };

    const handleSave = useCallback(async () => {
        if (!providerId || !user) {
            toast.error("Não foi possível salvar. Tente fazer login novamente.");
            return;
        }

        setIsSaving(true);
        const toastId = toast.loading("Salvando alterações...");

        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                unsubscribe();
                const response = docSnap.data();
                if (response.result) {
                    toast.success("Dados da empresa atualizados com sucesso!", { id: toastId });
                } else if (response.error) {
                    toast.error(`Falha ao salvar: ${response.error}`, { id: toastId });
                }
                setIsSaving(false);
            }
        });

        try {
            const providerRef = doc(db, 'provedores', providerId);
            const currentDoc = await getDoc(providerRef);
            const existingDetails = currentDoc.exists() ? currentDoc.data().details : {};

            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'UPDATE_PROVIDER_DETAILS',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: {
                    providerId,
                    details: { ...existingDetails, ...details }
                }
            });
        } catch (error: any) {
            toast.error(`Erro ao solicitar a gravação: ${error.message}`, { id: toastId });
            setIsSaving(false);
            unsubscribe();
        }
    }, [providerId, user, details]);

    if (loading) {
        return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin h-8 w-8" /></div>;
    }

    return (
        <Card className="max-w-4xl mx-auto">
            <CardHeader>
                <CardTitle>Minha Empresa</CardTitle>
                <CardDescription>Gerencie as informações cadastrais do seu provedor.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                <div className="space-y-2">
                    <Label htmlFor="razaoSocial">Razão Social</Label>
                    <Input id="razaoSocial" value={details.razaoSocial || ''} onChange={(e) => handleDetailChange('razaoSocial', e.target.value)} />
                </div>
                <div className="space-y-2">
                    <Label htmlFor="nomeFantasia">Nome Fantasia</Label>
                    <Input id="nomeFantasia" value={details.nomeFantasia || ''} onChange={(e) => handleDetailChange('nomeFantasia', e.target.value)} />
                </div>
                <div className="space-y-2">
                    <Label htmlFor="cnpj">CNPJ</Label>
                    <Input id="cnpj" value={details.cnpj || ''} onChange={(e) => handleDetailChange('cnpj', e.target.value)} />
                </div>
                <div className="space-y-2">
                    <Label htmlFor="email">Email</Label>
                    <Input id="email" type="email" value={details.email || ''} onChange={(e) => handleDetailChange('email', e.target.value)} />
                </div>
                <div className="space-y-2">
                    <Label htmlFor="telefone">Telefone</Label>
                    <Input id="telefone" value={details.telefone || ''} onChange={(e) => handleDetailChange('telefone', e.target.value)} />
                </div>
                <div className="flex justify-end">
                    <Button onClick={handleSave} disabled={isSaving}>
                        {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Salvar Alterações
                    </Button>
                </div>
            </CardContent>
        </Card>
    );
}
```

## ⚙️ Configurações do Provedor

> Páginas de configuração do app mobile.


---

### `src/pages/provider-settings/AppearanceSettings.tsx`
> Configuração de cores e layouts

```tsx
import { useContext, useCallback, memo } from 'react';
import { SettingsContext } from '@/contexts/SettingsContext';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Palette, Type, CreditCard, Zap, Smartphone } from 'lucide-react';
import { toast } from 'sonner';
import MobilePreview from '@/components/MobilePreview';

interface ColorRowProps {
    label: string;
    id: string;
    value: string;
    icon: React.ComponentType<{ className?: string }>;
    onChange: (id: string, val: string) => void;
}

const ColorRow = memo(({ label, id, value, icon: Icon, onChange }: ColorRowProps) => {
    return (
        <div className="space-y-2">
            <Label className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                <Icon className="h-4 w-4" /> {label}
            </Label>
            <div className="flex items-center gap-2">
                <input
                    type="color"
                    className="w-12 h-10 p-1 cursor-pointer border rounded"
                    value={value || '#000000'}
                    onChange={e => onChange(id, e.target.value)}
                />
                <Input
                    value={value || ''}
                    onChange={e => onChange(id, e.target.value)}
                    className="uppercase font-mono flex-1"
                    maxLength={7}
                    placeholder="#000000"
                />
            </div>
        </div>
    );
});

ColorRow.displayName = 'ColorRow';

export default function AppearanceSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig } = context;

    // Persist colors per layout using config.strings.layoutThemes
    const updateLayoutThemes = useCallback((newConfig: any, layoutToUpdate: string, values: any) => {
        const currentStrings = newConfig.strings || {};
        const layoutThemes = currentStrings.layoutThemes ? JSON.parse(typeof currentStrings.layoutThemes === 'string' ? currentStrings.layoutThemes : JSON.stringify(currentStrings.layoutThemes)) : {};

        layoutThemes[layoutToUpdate] = {
            themeColor: values.themeColor,
            secondaryColor: values.secondaryColor,
            actionColor: values.actionColor,
            invoiceColor: values.invoiceColor,
            cardColor: values.cardColor,
            textColor: values.textColor,
            backgroundColor: values.backgroundColor,
            iconColor: values.iconColor, // [NEW] Icon Color
        };

        return {
            ...newConfig,
            strings: {
                ...currentStrings,
                layoutThemes: JSON.stringify(layoutThemes)
            }
        };
    }, []);

    const handleColorChange = useCallback((id: string, val: string) => {
        setConfig((p: any) => {
            const updated = { ...p, [id]: val };
            // Also update the store for current layout
            return updateLayoutThemes(updated, p.layoutType || 'layout_06', updated);
        });
    }, [setConfig, updateLayoutThemes]);

    // Default color presets per layout
    const layoutDefaults: Record<string, Record<string, string>> = {
        layout_01: {
            themeColor: '#6B46C1',
            secondaryColor: '#9F7AEA',
            backgroundColor: '#1A202C',
            cardColor: '#2D3748',
            textColor: '#FFFFFF',
            iconColor: '#9F7AEA',
        },
        layout_02: {
            themeColor: '#3182CE',
            secondaryColor: '#63B3ED',
            backgroundColor: '#F7FAFC',
            cardColor: '#FFFFFF',
            textColor: '#1A202C',
            iconColor: '#3182CE',
        },
        layout_03: {
            themeColor: '#00D4FF',
            secondaryColor: '#FF00FF',
            backgroundColor: '#0A0A0F',
            cardColor: '#1A1A2E',
            textColor: '#FFFFFF',
            iconColor: '#00D4FF',
        },
        layout_04: {
            themeColor: '#0891B2',
            secondaryColor: '#059669',
            backgroundColor: '#F5F7FA',
            cardColor: '#FFFFFF',
            textColor: '#1F2937',
            iconColor: '#0891B2',
        },
        layout_05: {
            themeColor: '#1A5276', // Ocean Blue
            secondaryColor: '#1D8348', // Forest Green
            backgroundColor: '#F0F4F8',
            cardColor: '#FFFFFF',
            textColor: '#2C3E50',
            iconColor: '#1A5276',
        },
        layout_06: {
            themeColor: '#00F3FF', // Cyan
            secondaryColor: '#BC13FE', // Neon Pink
            backgroundColor: '#050A14', // Very Dark
            cardColor: '#131B2C',
            textColor: '#FFFFFF',
            iconColor: '#00F3FF',
        },
    };


    const handleLayoutChange = useCallback((newLayout: string) => {
        setConfig((prev: any) => {
            // Maxwell's Demon: Save current state before switching
            let nextConfig = updateLayoutThemes(prev, prev.layoutType || 'layout_01', prev);

            // Access the store to retrieve new layout colors
            const layoutThemes = nextConfig.strings?.layoutThemes ? JSON.parse(nextConfig.strings.layoutThemes) : {};
            const savedTheme = layoutThemes[newLayout];

            if (savedTheme) {
                // Restore saved colors
                nextConfig = {
                    ...nextConfig,
                    ...savedTheme,
                    layoutType: newLayout
                };
            } else {
                // No saved theme - use layout DEFAULTS instead of inheriting
                const defaults = layoutDefaults[newLayout] || layoutDefaults['layout_01'];
                nextConfig = {
                    ...nextConfig,
                    ...defaults,
                    layoutType: newLayout
                };
            }
            return nextConfig;
        });
    }, [setConfig, updateLayoutThemes]);

    return (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Configurações */}
            <div className="lg:col-span-2">
                <Card>
                    <CardHeader><CardTitle>Aparência</CardTitle></CardHeader>
                    <CardContent className="space-y-8">
                        {/* Seletor de Layout do App */}
                        <div className="space-y-3 p-4 border rounded-lg bg-muted/30">
                            <Label className="flex items-center gap-2 text-sm font-medium">
                                <Smartphone className="h-4 w-4" /> Layout do App
                            </Label>
                            <Select
                                value={config.layoutType || 'layout_01'}
                                onValueChange={handleLayoutChange}
                            >
                                <SelectTrigger className="w-full">
                                    <SelectValue placeholder="Escolha o layout" />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="layout_01">Layout 01 - Clássico</SelectItem>
                                    <SelectItem value="layout_02">Layout 02 - Minimalista</SelectItem>
                                    <SelectItem value="layout_03">Layout 03 - Neo Digital</SelectItem>
                                    <SelectItem value="layout_04">Layout 04 - Premium Dark</SelectItem>
                                    <SelectItem value="layout_05">Layout 05 - Organic / Biomorphic</SelectItem>
                                    <SelectItem value="layout_06">Layout 06 - Cyberpunk / Neon</SelectItem>
                                </SelectContent>
                            </Select>
                            <p className="text-xs text-muted-foreground">Define a aparência visual do aplicativo do cliente</p>
                        </div>

                        {/* Cores Principais */}
                        <div className="space-y-4">
                            <h3 className="text-sm font-semibold">Cores do Tema</h3>
                            <div className="grid gap-6 sm:grid-cols-2">
                                <ColorRow
                                    label="Cor Principal"
                                    id="themeColor"
                                    value={config.themeColor}
                                    icon={Palette}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Cor Secundária"
                                    id="secondaryColor"
                                    value={config.secondaryColor}
                                    icon={Palette}
                                    onChange={handleColorChange}
                                />
                            </div>
                        </div>

                        {/* Outras Cores */}
                        <div className="space-y-4">
                            <h3 className="text-sm font-semibold">Outras Cores</h3>
                            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                                <ColorRow
                                    label="Botões (Ação)"
                                    id="actionColor"
                                    value={config.actionColor}
                                    icon={Zap}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Cards (Surface)"
                                    id="cardColor"
                                    value={config.cardColor}
                                    icon={CreditCard}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Fundo (Page)"
                                    id="backgroundColor"
                                    value={config.backgroundColor}
                                    icon={Palette}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Fatura"
                                    id="invoiceColor"
                                    value={config.invoiceColor}
                                    icon={CreditCard}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Texto"
                                    id="textColor"
                                    value={config.textColor}
                                    icon={Type}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Ícones"
                                    id="iconColor"
                                    value={config.iconColor}
                                    icon={Zap}
                                    onChange={handleColorChange}
                                />
                            </div>
                        </div>

                        {/* Outras opções */}
                        <div className="p-4 border rounded flex justify-between items-center">
                            <Label>Cabeçalho com Imagem?</Label>
                            <Switch
                                checked={config.other?.useBackgroundImage || false}
                                onCheckedChange={(c) => setConfig((p: any) => ({
                                    ...p,
                                    other: { ...(p.other || {}), useBackgroundImage: c }
                                }))}
                            />
                        </div>

                        <div className="flex gap-2">
                            <Input
                                value={config.logoUrl || ''}
                                onChange={e => setConfig((p: any) => ({ ...p, logoUrl: e.target.value }))}
                                placeholder="Logo URL"
                            />
                            <Button variant="secondary" onClick={() => toast.success('URL OK')}>Definir</Button>
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Preview do App */}
            <div className="lg:col-span-1">
                <MobilePreview />
            </div>
        </div>
    );
}
```

---

### `src/pages/provider-settings/IntegrationsSettings.tsx`
> Integrações com SGP

```tsx
import { useContext, useState, useEffect } from 'react';
import { SettingsContext } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Save, Loader2, Link } from 'lucide-react';
import { toast } from 'sonner';
// Import de { ProviderConfig } removido - TS6133

export default function IntegrationsSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    // Acessa as configurações aninhadas no contexto
    const [localApiToken, setLocalApiToken] = useState(config.integrations?.apiToken || '');
    const [localAppName, setLocalAppName] = useState(config.integrations?.appName || '');

    useEffect(() => {
        setLocalApiToken(config.integrations?.apiToken || '');
        setLocalAppName(config.integrations?.appName || '');
    }, [config]);

    const handleSaveIntegration = () => {
        const newIntegrations = {
            apiToken: localApiToken.trim(),
            appName: localAppName.trim(),
        };

        // Atualiza o contexto, aninhando a nova configuração de integrações
        // Isso será persistido no Firestore sob config.integrations quando o botão "Salvar Alterações" no ProviderDetailPage for pressionado.
        setConfig((prev: any) => ({
            ...prev,
            integrations: newIntegrations,
        }));
        
        toast.info("Configurações atualizadas localmente. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };

    return (
        <Card>
            <CardHeader>
                <CardTitle>Integrações SGP</CardTitle>
                <CardDescription>
                    Configure o token e o nome do aplicativo necessários para sincronizar clientes e acessar dados do SGP.
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                
                <div className="space-y-2">
                    <Label htmlFor="apiToken">Token da API do SGP</Label>
                    <Input
                        id="apiToken"
                        placeholder="Insira o seu token de API do SGP"
                        value={localApiToken}
                        onChange={(e) => setLocalApiToken(e.target.value)}
                        disabled={isSaving}
                    />
                    <p className="text-sm text-muted-foreground">Chave secreta fornecida pelo seu sistema SGP.</p>
                </div>

                <div className="space-y-2">
                    <Label htmlFor="appName">Nome do Aplicativo (App Name)</Label>
                    <Input
                        id="appName"
                        placeholder="Ex: VIBE_TELECOM"
                        value={localAppName}
                        onChange={(e) => setLocalAppName(e.target.value)}
                        disabled={isSaving}
                    />
                    <p className="text-sm text-muted-foreground">Nome da sua aplicação cadastrada no SGP.</p>
                </div>

                <Button onClick={handleSaveIntegration} disabled={isSaving}>
                    {isSaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
                    Aplicar Configurações
                </Button>
                
                <div className="flex items-center text-sm text-muted-foreground pt-4 border-t">
                    <Link className="h-4 w-4 mr-2" />
                    As integrações entrarão em vigor após salvar as alterações no painel.
                </div>
            </CardContent>
        </Card>
    );
}
```

---

### `src/pages/provider-settings/FeaturesSettings.tsx`
> Toggle de funcionalidades

```tsx
import { useContext, useState, useEffect } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Save, Loader2, Zap, MessageSquare, ScrollText, DollarSign, Gauge, Clock, Menu } from 'lucide-react';
import { toast } from 'sonner';

interface Feature {
    key: string;
    label: string;
    description: string;
    icon: React.ReactNode;
}

const defaultFeatures: Feature[] = [
    { key: 'consumption', label: 'Consumo de Internet', description: 'Permite que o cliente veja o extrato de uso de dados.', icon: <Gauge className="h-5 w-5" /> },
    { key: 'support', label: 'Suporte & Tickets', description: 'Ativa a abertura de tickets de suporte e contatos rápidos.', icon: <MessageSquare className="h-5 w-5" /> },
    { key: 'invoices', label: 'Faturas/Boletos', description: 'Permite ao cliente visualizar e baixar faturas em aberto.', icon: <DollarSign className="h-5 w-5" /> },
    { key: 'payment_promise', label: 'Promessa de Pagamento', description: 'Permite a liberação temporária de bloqueio por inadimplência.', icon: <Clock className="h-5 w-5" /> },
    { key: 'speed_test', label: 'Teste de Velocidade', description: 'Integração com teste de velocidade (necessita configuração).', icon: <Zap className="h-5 w-5" /> },
    { key: 'terms_of_use', label: 'Termos de Uso', description: 'Exibe os termos de serviço configurados no painel.', icon: <ScrollText className="h-5 w-5" /> },
    { key: 'custom_menu', label: 'Menu Lateral Personalizado', description: 'Permite a inclusão de links externos no menu lateral.', icon: <Menu className="h-5 w-5" /> },
];

export default function FeaturesSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    // Estado local para gerenciar as features ativas/inativas
    const [localFeatures, setLocalFeatures] = useState<Record<string, boolean>>(config.features || {});

    useEffect(() => {
        // Sincroniza o estado local com o estado global ao carregar a página
        setLocalFeatures(config.features || {});
    }, [config]);

    const handleToggle = (key: string, checked: boolean) => {
        setLocalFeatures(prev => ({ ...prev, [key]: checked }));

        // Atualiza o contexto, aninhando a nova configuração de features
        // CORRIGIDO: Tipagem do prevConfig para resolver TS7006
        setConfig((prevConfig: ProviderConfig) => ({
            ...prevConfig,
            features: {
                ...prevConfig.features,
                [key]: checked,
            }
        }));
        
        toast.info(`Funcionalidade '${defaultFeatures.find(f => f.key === key)?.label}' ${checked ? 'ativada' : 'desativada'} localmente.`);
    };

    const handleApplyFeatures = () => {
        // O setConfig já foi chamado em cada toggle, então esta função apenas notifica
        toast.success("Configurações de funcionalidades aplicadas. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };

    return (
        <Card>
            <CardHeader>
                <CardTitle>Funcionalidades do Aplicativo</CardTitle>
                <CardDescription>
                    Selecione quais módulos e recursos estarão visíveis e acessíveis no aplicativo.
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                
                {defaultFeatures.map((feature) => (
                    <div key={feature.key} className="flex items-center justify-between border-b pb-4 last:border-b-0">
                        <div className="flex items-start gap-3">
                            <div className="mt-1 text-primary flex-shrink-0">{feature.icon}</div>
                            <div>
                                <Label htmlFor={feature.key} className="font-semibold text-base">{feature.label}</Label>
                                <p className="text-sm text-muted-foreground">{feature.description}</p>
                            </div>
                        </div>
                        <Switch
                            id={feature.key}
                            checked={localFeatures[feature.key] ?? true} // Padrão: Ativo
                            onCheckedChange={(checked) => handleToggle(feature.key, checked)}
                            disabled={isSaving}
                        />
                    </div>
                ))}
                
                <Button onClick={handleApplyFeatures} disabled={isSaving}>
                    {isSaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
                    Aplicar Configurações de Recursos
                </Button>
                
            </CardContent>
        </Card>
    );
}
```

---

### `src/pages/provider-settings/SupportSettings.tsx`
> Configuração de suporte

```tsx
import { useContext, useState, useEffect, useCallback } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Loader2, Phone, Mail, MapPin, Trash2, MessageCircle } from 'lucide-react';
import { toast } from 'sonner';
import AddEditContactDialog from '@/components/dialogs/AddEditContactDialog';

interface SupportContact {
    id: string;
    name: string;
    type: 'phone' | 'email' | 'address' | 'whatsapp';
    value: string;
}

// ... (in component)

// Mapeia o tipo para um ícone
const getIcon = (type: 'phone' | 'email' | 'address' | 'whatsapp') => {
    switch (type) {
        case 'phone': return <Phone className="h-5 w-5 text-gray-600" />;
        case 'whatsapp': return <MessageCircle className="h-5 w-5 text-green-600" />;
        case 'email': return <Mail className="h-5 w-5 text-red-600" />;
        case 'address': return <MapPin className="h-5 w-5 text-blue-600" />;
        default: return null;
    }
};

export default function SupportSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    const [localContacts, setLocalContacts] = useState<SupportContact[]>(config.supportContacts || []);

    useEffect(() => {
        setLocalContacts(config.supportContacts || []);
    }, [config.supportContacts]);

    // Função interna para atualizar o contexto e o estado local
    const updateAndSave = (updatedContacts: SupportContact[]) => {
        setLocalContacts(updatedContacts);

        // Atualiza o contexto
        // CORRIGIDO: Tipagem do prev para resolver TS7006
        setConfig((prev: ProviderConfig) => ({ ...prev, supportContacts: updatedContacts }));
    };

    // CORRIGIDO: Assinatura da função para corresponder ao AddEditContactDialog
    const handleSaveContact = (contact: Omit<SupportContact, 'id'>, id?: string) => {
        if (id) {
            // Edição
            const updatedContacts = localContacts.map(c =>
                c.id === id ? { ...c, ...contact } : c
            );
            updateAndSave(updatedContacts);
            toast.success("Contato atualizado. Salve no topo para confirmar.");
        } else {
            // Adição
            const newContact: SupportContact = { id: `contact-${Date.now()}`, ...contact };
            const updatedContacts = [...localContacts, newContact];
            updateAndSave(updatedContacts);
            toast.success("Contato adicionado. Salve no topo para confirmar.");
        }
    };

    const handleRemoveContact = (id: string) => {
        const updatedContacts = localContacts.filter(c => c.id !== id);
        updateAndSave(updatedContacts);
        toast.warning("Contato removido. Salve no topo para confirmar.");
    };



    return (
        <Card>
            <CardHeader className="flex flex-row items-center justify-between">
                <div>
                    <CardTitle>Contatos de Suporte</CardTitle>
                    <CardDescription>
                        Gerencie os telefones, emails e endereços exibidos na tela de suporte do app.
                    </CardDescription>
                </div>
                {/* CORRIGIDO: O diálogo recebe a função de salvar com a tipagem correta */}
                <AddEditContactDialog onSave={handleSaveContact} />
            </CardHeader>
            <CardContent>
                {localContacts.length === 0 ? (
                    <p className="text-sm text-muted-foreground">Nenhum contato configurado ainda.</p>
                ) : (
                    <div className="space-y-4">
                        <Label className="text-base font-semibold">Lista de Contatos</Label>
                        <div className="grid gap-4">
                            {localContacts.map((contact) => (
                                <div key={contact.id} className="flex items-center justify-between p-3 border rounded-md">
                                    <div className="flex items-center gap-4">
                                        {getIcon(contact.type)}
                                        <div>
                                            <p className="font-medium">{contact.name}</p>
                                            <p className="text-sm text-muted-foreground">{contact.value}</p>
                                        </div>
                                    </div>
                                    <div className="flex gap-2">
                                        {/* Diálogo de Edição */}
                                        <AddEditContactDialog
                                            contact={contact}
                                            onSave={handleSaveContact}
                                            onDelete={handleRemoveContact}
                                        />
                                        <Button
                                            variant="destructive"
                                            size="icon"
                                            onClick={() => handleRemoveContact(contact.id)}
                                            disabled={isSaving}
                                        >
                                            <Trash2 className="h-4 w-4" />
                                        </Button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}
            </CardContent>
        </Card>
    );
}
```

---

### `src/pages/provider-settings/FaqSettings.tsx`
> Gerenciamento de FAQ

```tsx
import { useContext, useState, useEffect, useCallback } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Loader2, HelpCircle, PlusCircle, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';

export interface FaqItem {
    id: string;
    question: string;
    answer: string;
}

export default function FaqSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    // Converte o objeto/array de faqs para um estado local
    const [localFaqs, setLocalFaqs] = useState<FaqItem[]>(() => {
        // Assume que 'config.faq' é um array de { question: string, answer: string }
        return (config.faq || []).map((item: { question: string, answer: string }, index: number) => ({
            id: `faq-${index}-${Math.random()}`,
            question: item.question,
            answer: item.answer,
        }));
    });
    const [newQuestion, setNewQuestion] = useState('');
    const [newAnswer, setNewAnswer] = useState('');

    useEffect(() => {
        // Sincroniza o estado local com o estado global ao carregar a página
        setLocalFaqs((config.faq || []).map((item: { question: string, answer: string }, index: number) => ({
            id: `faq-${index}-${Math.random()}`,
            question: item.question,
            answer: item.answer,
        })));
    }, [config.faq]);

    // Função interna para atualizar o contexto e o estado local
    const updateAndSave = (updatedFaqs: FaqItem[]) => {
        setLocalFaqs(updatedFaqs);
        
        // Mapeia para o formato de salvamento (apenas question e answer)
        const contentArray = updatedFaqs.map(t => ({ question: t.question, answer: t.answer }));
        
        // Atualiza o contexto, aninhando a nova configuração de faqs
        // CORRIGIDO: Tipagem do prev para resolver TS7006
        setConfig((prev: ProviderConfig) => ({ ...prev, faq: contentArray }));
    };

    const handleAddFaq = () => {
        if (!newQuestion.trim() || !newAnswer.trim()) {
            toast.error("A pergunta e a resposta são obrigatórias.");
            return;
        }

        const newFaq: FaqItem = { id: `faq-${Date.now()}`, question: newQuestion.trim(), answer: newAnswer.trim() };
        const updatedFaqs = [...localFaqs, newFaq];

        updateAndSave(updatedFaqs);
        setNewQuestion('');
        setNewAnswer('');
        toast.success("FAQ adicionada. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };

    const handleRemoveFaq = (id: string) => {
        const updatedFaqs = localFaqs.filter(faq => faq.id !== id);
        updateAndSave(updatedFaqs);
        toast.warning("FAQ removida. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };
    
    // Função para aplicar as alterações (apenas notifica, pois o setConfig já foi chamado)
    const handleApplyChanges = useCallback(() => {
        toast.success("Configurações de FAQ aplicadas. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    }, []);

    return (
        <Card>
            <CardHeader>
                <CardTitle>Perguntas Frequentes (FAQ)</CardTitle>
                <CardDescription>
                    Gerencie a lista de perguntas e respostas exibidas na seção de ajuda do aplicativo.
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                
                {/* Adicionar Nova FAQ */}
                <div className="space-y-4 pt-4 pb-6 border-b">
                    <Label className="text-base font-semibold">Adicionar Nova FAQ</Label>
                    <Input
                        placeholder="Pergunta"
                        value={newQuestion}
                        onChange={(e) => setNewQuestion(e.target.value)}
                        disabled={isSaving}
                    />
                    <Input
                        placeholder="Resposta"
                        value={newAnswer}
                        onChange={(e) => setNewAnswer(e.target.value)}
                        disabled={isSaving}
                    />
                    <Button onClick={handleAddFaq} disabled={isSaving || !newQuestion.trim() || !newAnswer.trim()}>
                        <PlusCircle className="h-4 w-4 mr-2" /> Adicionar FAQ
                    </Button>
                </div>

                {/* Lista de FAQs Atuais */}
                {localFaqs.length > 0 && (
                    <div className="space-y-3 pt-4">
                        <Label className="text-base font-semibold">FAQs Atuais ({localFaqs.length})</Label>
                        <Accordion type="single" collapsible className="w-full">
                            {localFaqs.map((faq) => (
                                <AccordionItem key={faq.id} value={faq.id}>
                                    <AccordionTrigger className="font-medium text-left">
                                        <div className="flex items-center gap-2">
                                            <HelpCircle className="h-4 w-4 text-primary" />
                                            {faq.question}
                                        </div>
                                    </AccordionTrigger>
                                    <AccordionContent className="flex items-start gap-4">
                                        <p className="flex-1 text-sm text-muted-foreground pt-1">{faq.answer}</p>
                                        <Button 
                                            variant="destructive" 
                                            size="icon" 
                                            onClick={() => handleRemoveFaq(faq.id)} 
                                            disabled={isSaving}
                                            className="h-7 w-7 flex-shrink-0"
                                        >
                                            <Trash2 className="h-4 w-4" />
                                        </Button>
                                    </AccordionContent>
                                </AccordionItem>
                            ))}
                        </Accordion>
                    </div>
                )}
                
                {localFaqs.length === 0 && (
                    <p className="text-sm text-muted-foreground pt-4">Nenhuma FAQ configurada ainda.</p>
                )}
                
                <Button onClick={handleApplyChanges} disabled={isSaving}>
                    {isSaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : "Aplicar FAQ (Salvar Localmente)"}
                </Button>
            </CardContent>
        </Card>
    );
}
```

---

### `src/pages/provider-settings/TipsSettings.tsx`
> Dicas do app

```tsx
import { useContext, useState, useEffect, useCallback } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Loader2, Lightbulb, PlusCircle, Trash2 } from 'lucide-react';
import { toast } from 'sonner';

// CORREÇÃO: Interface compatível com o Dialog e o App Flutter
export interface TipItem {
    id: string;
    title: string;
    description: string;
}

export default function TipsSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    // Converte o array de tips para um estado local
    const [localTips, setLocalTips] = useState<TipItem[]>(() => {
        // O backend pode retornar strings simples (legado) ou objetos
        return (config.tips || []).map((item: any, index: number) => {
            if (typeof item === 'string') {
                return {
                    id: `tip-${index}-${Math.random()}`,
                    title: 'Dica',
                    description: item
                };
            }
            return {
                id: `tip-${index}-${Math.random()}`,
                title: item.title || 'Dica',
                description: item.description || ''
            };
        });
    });

    // Estados para nova dica
    const [newTitle, setNewTitle] = useState('');
    const [newDescription, setNewDescription] = useState('');

    useEffect(() => {
        setLocalTips((config.tips || []).map((item: any, index: number) => {
             if (typeof item === 'string') {
                return {
                    id: `tip-${index}-${Math.random()}`,
                    title: 'Dica',
                    description: item
                };
            }
            return {
                id: `tip-${index}-${Math.random()}`,
                title: item.title || 'Dica',
                description: item.description || ''
            };
        }));
    }, [config.tips]);

    const updateAndSave = (updatedTips: TipItem[]) => {
        setLocalTips(updatedTips);
        
        // Salva no formato de objeto para o App ler corretamente
        const contentArray = updatedTips.map(t => ({
            title: t.title,
            description: t.description
        }));
        
        setConfig((prev: ProviderConfig) => ({ ...prev, tips: contentArray }));
    };

    const handleAddTip = () => {
        if (!newDescription.trim()) {
            toast.error("A descrição da dica não pode estar vazia.");
            return;
        }

        const newTip: TipItem = { 
            id: `tip-${Date.now()}`, 
            title: newTitle.trim() || 'Dica Útil', 
            description: newDescription.trim() 
        };
        
        const updatedTips = [...localTips, newTip];

        updateAndSave(updatedTips);
        setNewTitle('');
        setNewDescription('');
        toast.success("Dica adicionada. Clique em 'Salvar Alterações' para confirmar.");
    };

    const handleRemoveTip = (id: string) => {
        const updatedTips = localTips.filter(tip => tip.id !== id);
        updateAndSave(updatedTips);
        toast.warning("Dica removida.");
    };
    
    const handleApplyChanges = useCallback(() => {
        toast.success("Alterações aplicadas localmente. Não esqueça de Salvar.");
    }, []);

    return (
        <Card>
            <CardHeader>
                <CardTitle>Dicas Úteis (Carrossel)</CardTitle>
                <CardDescription>
                    Gerencie as dicas exibidas no aplicativo.
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                
                {/* Adicionar Nova Dica */}
                <div className="grid gap-4 p-4 border rounded-lg bg-slate-50 dark:bg-slate-900">
                    <div className="grid gap-2">
                        <Label>Título</Label>
                        <Input
                            placeholder="Ex: Reinicie seus equipamentos"
                            value={newTitle}
                            onChange={(e) => setNewTitle(e.target.value)}
                            disabled={isSaving}
                        />
                    </div>
                    <div className="grid gap-2">
                        <Label>Descrição</Label>
                        <Input
                            placeholder="Ex: Desligue o modem por 10 segundos..."
                            value={newDescription}
                            onChange={(e) => setNewDescription(e.target.value)}
                            disabled={isSaving}
                        />
                    </div>
                    <Button onClick={handleAddTip} disabled={isSaving || !newDescription.trim()}>
                        <PlusCircle className="h-4 w-4 mr-2" /> Adicionar Dica
                    </Button>
                </div>

                {/* Lista de Dicas */}
                {localTips.length > 0 && (
                    <div className="space-y-3 pt-4 border-t">
                        <Label className="text-base font-semibold">Dicas Atuais ({localTips.length})</Label>
                        {localTips.map((tip) => (
                            <div key={tip.id} className="flex items-start gap-3 p-3 border rounded-md bg-card">
                                <Lightbulb className="h-5 w-5 mt-1 text-yellow-500 flex-shrink-0" />
                                <div className="flex-1">
                                    <p className="font-medium text-sm">{tip.title}</p>
                                    <p className="text-sm text-muted-foreground">{tip.description}</p>
                                </div>
                                <Button 
                                    variant="destructive" 
                                    size="icon" 
                                    onClick={() => handleRemoveTip(tip.id)} 
                                    disabled={isSaving}
                                    className="h-7 w-7"
                                >
                                    <Trash2 className="h-4 w-4" />
                                </Button>
                            </div>
                        ))}
                    </div>
                )}
                
                {localTips.length === 0 && (
                    <p className="text-sm text-muted-foreground text-center py-4">Nenhuma dica configurada.</p>
                )}
                
                <Button onClick={handleApplyChanges} disabled={isSaving} className="w-full">
                    {isSaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : "Confirmar Alterações"}
                </Button>
            </CardContent>
        </Card>
    );
}
```

---

### `src/pages/provider-settings/MenusSettingsPage.tsx`
> Configuração de menus

```tsx
import { useState, useContext, useEffect } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from '@/components/ui/button';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Input } from "@/components/ui/input";
import { GripVertical, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import { Switch } from "@/components/ui/switch";
import { DndContext, closestCenter, KeyboardSensor, PointerSensor, useSensor, useSensors, DragEndEvent } from '@dnd-kit/core';
import { arrayMove, SortableContext, sortableKeyboardCoordinates, verticalListSortingStrategy, useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import AddMenuItemDialog from '@/components/AddMenuItemDialog';

interface MenuItem {
  id: string;
  name: string;
  type: 'internal' | 'external_link';
  url?: string;
  color?: string; // Nova propriedade de cor individual
  enabled: boolean;
}

const defaultMenuItems: Omit<MenuItem, 'enabled'>[] = [
  { id: 'notifications', name: 'Notificações', type: 'internal', color: '#F59E0B' },
  { id: 'invoices', name: 'Faturas', type: 'internal', color: '#1E6FF8' },
  { id: 'payment_promise', name: 'Promessa de Pagamento', type: 'internal', color: '#10B981' },
  { id: 'speed_test', name: 'Teste de Velocidade', type: 'internal', color: '#8B5CF6' },
  { id: 'internet_usage', name: 'Consumo de Internet', type: 'internal', color: '#EC4899' },
  { id: 'support', name: 'Suporte', type: 'internal', color: '#06B6D4' },
  { id: 'contract', name: 'Contrato', type: 'internal', color: '#6366F1' },
  { id: 'my_ip', name: 'Meu IP', type: 'internal', color: '#F97316' },
];

function SortableRow({ item, index, onToggle, onRemove, onColorChange }: any) {
    const { attributes, listeners, setNodeRef, transform, transition } = useSortable({ id: item.id });
    const style = { transform: CSS.Transform.toString(transform), transition };

    return (
        <TableRow ref={setNodeRef} style={style}>
            <TableCell className="cursor-grab w-[50px]" {...attributes} {...listeners}>
                <GripVertical className="h-5 w-5 text-muted-foreground" />
            </TableCell>
            <TableCell className="w-[50px]">{index + 1}</TableCell>
            <TableCell className="font-medium">{item.name}</TableCell>
            
            {/* COLUNA DE COR INDIVIDUAL */}
            <TableCell>
                <div className="flex items-center gap-2">
                    <div 
                        className="w-6 h-6 rounded-full border shadow-sm" 
                        style={{ backgroundColor: item.color || '#673AB7' }}
                    />
                    <Input 
                        type="color" 
                        value={item.color || '#673AB7'} 
                        onChange={(e) => onColorChange(item.id, e.target.value)}
                        className="w-12 h-8 p-0 cursor-pointer border-none bg-transparent"
                    />
                </div>
            </TableCell>

            <TableCell>{item.type === 'external_link' ? `Link: ${item.url}` : 'Nativo'}</TableCell>
            
            <TableCell className="text-right w-[150px]">
                <div className="flex items-center justify-end gap-4">
                  {item.type === 'external_link' && (
                    <Button variant="ghost" size="icon" onClick={() => onRemove(item.id)}>
                        <Trash2 className="h-4 w-4 text-destructive" />
                    </Button>
                  )}
                  <Switch
                      checked={item.enabled}
                      onCheckedChange={(checked) => onToggle(item.id, checked)}
                  />
                </div>
            </TableCell>
        </TableRow>
    );
}

export default function MenusSettingsPage() {
    const context = useContext(SettingsContext);
    const [menuItems, setMenuItems] = useState<MenuItem[]>([]);
    const sensors = useSensors(useSensor(PointerSensor), useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }));

    useEffect(() => {
        const savedConfig = context?.config?.menuConfig as { order: string[], items: Record<string, MenuItem> } | undefined;

        if (savedConfig?.order && savedConfig?.items) {
            const allItems: MenuItem[] = savedConfig.order.map(id => {
                const savedItem = savedConfig.items[id];
                const defaultItem = defaultMenuItems.find(d => d.id === id);
                return {
                    id: id,
                    name: savedItem.name || defaultItem?.name || 'Item',
                    type: savedItem.type || defaultItem?.type || 'internal',
                    url: savedItem.url,
                    color: savedItem.color || defaultItem?.color || '#673AB7', // Recupera a cor salva
                    enabled: savedItem.enabled,
                };
            }).filter(item => defaultMenuItems.some(d => d.id === item.id) || item.type === 'external_link');
            
            defaultMenuItems.forEach(defaultItem => {
                if (!allItems.some(item => item.id === defaultItem.id)) {
                    allItems.push({ ...defaultItem, enabled: true });
                }
            });
            
            setMenuItems(allItems);
        } else {
            setMenuItems(defaultMenuItems.map(item => ({ ...item, enabled: true })));
        }
    }, [context?.config?.menuConfig]);
    
    const updateAndSave = (newItems: MenuItem[]) => {
      setMenuItems(newItems);
      if (context) {
          const newConfig = {
              order: newItems.map(item => item.id),
              items: newItems.reduce((acc, item) => {
                  const itemToSave: any = {
                      name: item.name,
                      type: item.type,
                      enabled: item.enabled,
                      color: item.color, // Salva a cor
                  };
                  if (item.type === 'external_link') itemToSave.url = item.url;
                  acc[item.id] = itemToSave;
                  return acc;
              }, {} as Record<string, Omit<MenuItem, 'id'>>)
          };
          context.setConfig((prev: ProviderConfig) => ({ ...prev, menuConfig: newConfig }));
      }
    };

    const handleAddItem = (name: string, url: string) => {
      const newItem: MenuItem = {
        id: `external_${Date.now()}`,
        name: name,
        type: 'external_link',
        url: url,
        color: '#673AB7', // Cor padrão para novos links
        enabled: true,
      };
      const updatedItems = [...menuItems, newItem];
      updateAndSave(updatedItems);
      toast.success(`'${name}' adicionado. Clique em 'Salvar Alterações'.`);
    };

    const handleRemoveItem = (id: string) => {
      const updatedItems = menuItems.filter(item => item.id !== id);
      updateAndSave(updatedItems);
    };

    const handleDragEnd = (event: DragEndEvent) => {
        const { active, over } = event;
        if (over && active.id !== over.id) {
            const oldIndex = menuItems.findIndex(item => item.id === active.id);
            const newIndex = menuItems.findIndex(item => item.id === over.id);
            const reorderedItems = arrayMove(menuItems, oldIndex, newIndex);
            updateAndSave(reorderedItems);
        }
    };

    const handleToggle = (id: string, enabled: boolean) => {
        const updatedItems = menuItems.map(item => item.id === id ? { ...item, enabled } : item);
        updateAndSave(updatedItems);
    };

    // Nova função para mudar a cor
    const handleColorChange = (id: string, color: string) => {
        const updatedItems = menuItems.map(item => item.id === id ? { ...item, color } : item);
        updateAndSave(updatedItems);
    };

    return (
        <Card>
            <CardHeader className="flex flex-row items-center justify-between">
                <div>
                    <CardTitle>Menus & Cores</CardTitle>
                    <CardDescription>Organize os menus e defina uma cor para cada cartão.</CardDescription>
                </div>
                <AddMenuItemDialog onAddItem={handleAddItem} />
            </CardHeader>
            <CardContent>
                <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead className="w-[50px]"></TableHead>
                                <TableHead className="w-[50px]">#</TableHead>
                                <TableHead>Nome</TableHead>
                                <TableHead>Cor do Card</TableHead>
                                <TableHead>Tipo</TableHead>
                                <TableHead className="text-right w-[150px]">Ações</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            <SortableContext items={menuItems.map(i => i.id)} strategy={verticalListSortingStrategy}>
                                {menuItems.map((item, index) => (
                                    <SortableRow 
                                        key={item.id} 
                                        item={item} 
                                        index={index} 
                                        onToggle={handleToggle} 
                                        onRemove={handleRemoveItem}
                                        onColorChange={handleColorChange} // Passa a função
                                    />
                                ))}
                            </SortableContext>
                        </TableBody>
                    </Table>
                </DndContext>
            </CardContent>
        </Card>
    );
}
```

---

### `src/pages/provider-settings/ImagesIconsSettings.tsx`
> Imagens e ícones

```tsx
import { useContext, useState, useEffect } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Upload, ImageIcon, Monitor, Loader2, Save } from 'lucide-react';
import { toast } from 'sonner';

interface ImageConfig {
    key: string;
    label: string;
    placeholder: string;
    previewSize: string;
}

const imageFields: ImageConfig[] = [
    { key: 'backgroundUrl', label: 'Imagem de Fundo (Login)', placeholder: 'URL da imagem de fundo...', previewSize: 'h-24 w-auto' },
    { key: 'logoUrl', label: 'Logo do Provedor', placeholder: 'URL da logo (PNG/SVG)...', previewSize: 'h-24 w-auto' },
    { key: 'iconUrl', label: 'Ícone da Aplicação', placeholder: 'URL do ícone...', previewSize: 'h-12 w-12' },
];

export default function ImagesIconsSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    // Estado local para gerenciar as URLs
    const [localUrls, setLocalUrls] = useState<Record<string, string>>(() => {
        const initial: Record<string, string> = {};
        imageFields.forEach(field => {
            initial[field.key] = config[field.key] || '';
        });
        return initial;
    });

    useEffect(() => {
        // Sincroniza o estado local com o estado global ao carregar a página
        const updatedUrls: Record<string, string> = {};
        imageFields.forEach(field => {
            updatedUrls[field.key] = config[field.key] || '';
        });
        setLocalUrls(updatedUrls);
    }, [config]);

    // Função para atualizar o estado local
    const handleLocalUpdate = (key: string, value: string) => {
        setLocalUrls(prev => ({ ...prev, [key]: value }));
    };

    // Função para salvar no contexto
    const handleSaveImage = (key: string) => {
        const url = localUrls[key]?.trim();
        if (!url || !url.startsWith('http')) {
            toast.error(`Por favor, insira uma URL válida para ${imageFields.find(f => f.key === key)?.label}.`);
            return;
        }

        // Atualiza o contexto global
        // CORRIGIDO: Tipagem do prev para resolver TS7006
        setConfig((prev: any) => ({ ...prev, [key]: url }));
        toast.success(`${imageFields.find(f => f.key === key)?.label} atualizada. Clique em 'Salvar Alterações' no topo.`);
    };

    return (
        <Card>
            <CardHeader>
                <CardTitle>Imagens e Ícones</CardTitle>
                <CardDescription>
                    Configure as URLs para imagens de fundo, ícones e outros elementos visuais do aplicativo.
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-8">
                {imageFields.map((field) => (
                    <div key={field.key} className="space-y-4 pt-4 border-t first:border-t-0">
                        <Label htmlFor={field.key} className="text-base font-semibold flex items-center gap-2">
                            {field.key === 'backgroundUrl' ? <Monitor className="h-5 w-5" /> : <ImageIcon className="h-5 w-5" />}
                            {field.label}
                        </Label>

                        <div className="flex gap-2">
                            <Input
                                id={field.key}
                                placeholder={field.placeholder}
                                value={localUrls[field.key] || ''}
                                onChange={(e) => handleLocalUpdate(field.key, e.target.value)}
                                disabled={isSaving}
                            />
                            <Button onClick={() => handleSaveImage(field.key)} disabled={isSaving || !localUrls[field.key]?.trim()}>
                                <Upload className="h-4 w-4 mr-2" /> Aplicar
                            </Button>
                        </div>

                        {/* Pré-visualização */}
                        {localUrls[field.key] && (
                            <div className="mt-4 p-4 border rounded-md bg-muted/50">
                                <p className="text-sm font-medium mb-2">Pré-visualização:</p>
                                <img
                                    src={localUrls[field.key]}
                                    alt={`${field.label} Preview`}
                                    className={`${field.previewSize} object-contain`}
                                    onError={(e) => (e.currentTarget.style.display = 'none')}
                                />
                            </div>
                        )}
                    </div>
                ))}
            </CardContent>
        </Card>
    );
}
```

---

### `src/pages/provider-settings/SplashLoginConfig.tsx`
> Tela de splash e login

```tsx
import { useState } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Slider } from '@/components/ui/slider';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { Sparkles, LogIn, Save } from 'lucide-react';

export default function SplashLoginConfig() {
  const { config, setConfig, saveConfig, isSaving } = useSettings();
  
  const [splash, setSplash] = useState(config.splash || {
    enabled: true,
    logoUrl: '',
    backgroundColor: '#1E293B',
    animation: 'fade',
    duration: 2000,
    showProgressBar: true,
    progressBarColor: '#673AB7',
  });

  const [login, setLogin] = useState(config.login || {
    style: 'modern',
    showLogo: true,
    backgroundType: 'gradient',
    quote: 'Bem-vindo!',
  });

  const handleSave = async () => {
    setConfig({ ...config, splash, login });
    await saveConfig();
    toast.success('Configurações salvas!');
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold flex items-center gap-2">
            <Sparkles className="h-8 w-8" />
            Splash & Login
          </h2>
          <p className="text-muted-foreground">Configure a primeira impressão do app</p>
        </div>
        <Button onClick={handleSave} disabled={isSaving}>
          <Save className="h-4 w-4 mr-2" />
          {isSaving ? 'Salvando...' : 'Salvar'}
        </Button>
      </div>

      <Tabs defaultValue="splash">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="splash">Splash Screen</TabsTrigger>
          <TabsTrigger value="login">Login Screen</TabsTrigger>
        </TabsList>

        <TabsContent value="splash" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Splash Screen</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <Label>Habilitar Splash</Label>
                <Switch
                  checked={splash.enabled}
                  onCheckedChange={(c) => setSplash({ ...splash, enabled: c })}
                />
              </div>

              {splash.enabled && (
                <>
                  <div>
                    <Label>URL do Logo</Label>
                    <Input
                      value={splash.logoUrl}
                      onChange={(e) => setSplash({ ...splash, logoUrl: e.target.value })}
                      placeholder="https://..."
                    />
                  </div>

                  <div>
                    <Label>Cor de Fundo</Label>
                    <div className="flex gap-2">
                      <Input
                        type="color"
                        value={splash.backgroundColor}
                        onChange={(e) => setSplash({ ...splash, backgroundColor: e.target.value })}
                        className="w-16"
                      />
                      <Input
                        value={splash.backgroundColor}
                        onChange={(e) => setSplash({ ...splash, backgroundColor: e.target.value })}
                        className="flex-1"
                      />
                    </div>
                  </div>

                  <div>
                    <Label>Animação</Label>
                    <Select
                      value={splash.animation}
                      onValueChange={(v) => setSplash({ ...splash, animation: v })}
                    >
                      <SelectTrigger><SelectValue /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="fade">Fade In</SelectItem>
                        <SelectItem value="scale">Scale Up</SelectItem>
                        <SelectItem value="slide">Slide Up</SelectItem>
                        <SelectItem value="bounce">Bounce</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div>
                    <div className="flex justify-between items-center mb-2">
                      <Label>Duração</Label>
                      <Badge>{splash.duration}ms</Badge>
                    </div>
                    <Slider
                      value={[splash.duration]}
                      onValueChange={([v]) => setSplash({ ...splash, duration: v })}
                      min={500}
                      max={5000}
                      step={100}
                    />
                  </div>

                  <div className="flex items-center justify-between">
                    <Label>Mostrar Barra de Progresso</Label>
                    <Switch
                      checked={splash.showProgressBar}
                      onCheckedChange={(c) => setSplash({ ...splash, showProgressBar: c })}
                    />
                  </div>
                </>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="login" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Login Screen</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label>Estilo</Label>
                <Select
                  value={login.style}
                  onValueChange={(v) => setLogin({ ...login, style: v })}
                >
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="classic">Classic</SelectItem>
                    <SelectItem value="modern">Modern (com carousel)</SelectItem>
                    <SelectItem value="minimal">Minimal</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <Label>Tipo de Fundo</Label>
                <Select
                  value={login.backgroundType}
                  onValueChange={(v) => setLogin({ ...login, backgroundType: v })}
                >
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="solid">Cor Sólida</SelectItem>
                    <SelectItem value="gradient">Gradiente</SelectItem>
                    <SelectItem value="image">Imagem</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <Label>Slogan/Quote</Label>
                <Input
                  value={login.quote}
                  onChange={(e) => setLogin({ ...login, quote: e.target.value })}
                  placeholder="Ex: Bem-vindo ao futuro!"
                />
              </div>

              <div className="flex items-center justify-between">
                <Label>Mostrar Logo</Label>
                <Switch
                  checked={login.showLogo}
                  onCheckedChange={(c) => setLogin({ ...login, showLogo: c })}
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
```

---

### `src/pages/provider-settings/NotificationsManager.tsx`
> Gerenciador de notificações

```tsx
import { useState } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { Bell, Plus, Send, Trash2, Users, Filter } from 'lucide-react';

export default function NotificationsManager() {
  const { config, setConfig, saveConfig, isSaving } = useSettings();
  const [notifications, setNotifications] = useState(config.notifications?.list || []);
  const [newNotif, setNewNotif] = useState({ title: '', message: '', category: 'info', targetAll: true });
  const [filter, setFilter] = useState('all');

  const categories = [
    { value: 'urgent', label: 'Urgente', color: 'destructive' },
    { value: 'info', label: 'Informação', color: 'default' },
    { value: 'promo', label: 'Promoção', color: 'secondary' },
  ];

  const createNotification = () => {
    if (!newNotif.title || !newNotif.message) {
      toast.error('Preencha título e mensagem');
      return;
    }
    const notif = {
      id: `notif_${Date.now()}`,
      ...newNotif,
      createdAt: new Date().toISOString(),
      read: false,
      dismissible: newNotif.category !== 'urgent',
    };
    setNotifications([notif, ...notifications]);
    setNewNotif({ title: '', message: '', category: 'info', targetAll: true });
    toast.success('Notificação criada!');
  };

  const deleteNotification = (id: string) => {
    if (confirm('Deletar notificação?')) {
      setNotifications(notifications.filter((n: any) => n.id !== id));
      toast.success('Deletada!');
    }
  };

  const sendToAll = () => {
    toast.success(`Enviando ${notifications.filter((n: any) => !n.read).length} notificações para todos os clientes!`);
  };

  const handleSave = async () => {
    setConfig({ ...config, notifications: { ...config.notifications, list: notifications } });
    await saveConfig();
    toast.success('Notificações salvas!');
  };

  const filteredNotifications = filter === 'all' 
    ? notifications 
    : notifications.filter((n: any) => n.category === filter);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold flex items-center gap-2">
            <Bell className="h-8 w-8" />
            Gerenciador de Notificações
          </h2>
          <p className="text-muted-foreground">Envie avisos e promoções para seus clientes</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={sendToAll}>
            <Send className="h-4 w-4 mr-2" />
            Enviar Todas
          </Button>
          <Button onClick={handleSave} disabled={isSaving}>
            {isSaving ? 'Salvando...' : 'Salvar Alterações'}
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Nova Notificação</CardTitle>
            <CardDescription>Crie um aviso para enviar aos clientes</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label>Título *</Label>
              <Input
                value={newNotif.title}
                onChange={(e) => setNewNotif({ ...newNotif, title: e.target.value })}
                placeholder="Ex: Manutenção Programada"
                maxLength={100}
              />
              <p className="text-xs text-muted-foreground mt-1">{newNotif.title.length}/100</p>
            </div>

            <div>
              <Label>Mensagem *</Label>
              <Textarea
                value={newNotif.message}
                onChange={(e) => setNewNotif({ ...newNotif, message: e.target.value })}
                placeholder="Digite a mensagem completa..."
                rows={5}
                maxLength={500}
              />
              <p className="text-xs text-muted-foreground mt-1">{newNotif.message.length}/500</p>
            </div>

            <div>
              <Label>Categoria</Label>
              <Select value={newNotif.category} onValueChange={(v) => setNewNotif({ ...newNotif, category: v })}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {categories.map((cat) => (
                    <SelectItem key={cat.value} value={cat.value}>{cat.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="flex items-center justify-between p-4 border rounded-lg">
              <div className="flex items-center gap-2">
                <Users className="h-4 w-4" />
                <Label>Enviar para todos os clientes</Label>
              </div>
              <Switch
                checked={newNotif.targetAll}
                onCheckedChange={(checked) => setNewNotif({ ...newNotif, targetAll: checked })}
              />
            </div>

            <Button onClick={createNotification} className="w-full" size="lg">
              <Plus className="h-4 w-4 mr-2" />
              Criar Notificação
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>Notificações Ativas ({filteredNotifications.length})</CardTitle>
              <Select value={filter} onValueChange={setFilter}>
                <SelectTrigger className="w-32">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todas</SelectItem>
                  {categories.map(cat => (
                    <SelectItem key={cat.value} value={cat.value}>{cat.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </CardHeader>
          <CardContent>
            <div className="space-y-3 max-h-[600px] overflow-auto">
              {filteredNotifications.length === 0 ? (
                <div className="text-center py-12">
                  <Bell className="h-12 w-12 mx-auto text-muted-foreground opacity-20 mb-4" />
                  <p className="text-muted-foreground">Nenhuma notificação</p>
                </div>
              ) : (
                filteredNotifications.map((notif: any) => {
                  const cat = categories.find((c) => c.value === notif.category);
                  return (
                    <div key={notif.id} className="p-4 border rounded-lg space-y-2 hover:bg-accent transition-colors">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-1">
                            <p className="font-semibold">{notif.title}</p>
                            <Badge variant={cat?.color as any}>{cat?.label}</Badge>
                            {!notif.dismissible && <Badge variant="outline">Não dispensável</Badge>}
                          </div>
                          <p className="text-sm text-muted-foreground line-clamp-2">{notif.message}</p>
                          <div className="flex items-center gap-4 mt-2 text-xs text-muted-foreground">
                            <span>{new Date(notif.createdAt).toLocaleString('pt-BR')}</span>
                            {notif.targetAll && (
                              <span className="flex items-center gap-1">
                                <Users className="h-3 w-3" />
                                Todos
                              </span>
                            )}
                          </div>
                        </div>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => deleteNotification(notif.id)}
                        >
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
```

---

### `src/pages/provider-settings/BackupSettings.tsx`
> Backup de configurações

```tsx
// admin-painel/src/pages/provider-settings/BackupSettings.tsx - VERSÃO ATUALIZADA
import { useState, useEffect, useContext, useCallback } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from '@/components/ui/button';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog";
import { Loader2, HardDriveUpload, History, Trash2, DatabaseZap } from 'lucide-react';
import { toast } from 'sonner';
import { SettingsContext } from '@/contexts/SettingsContext.tsx';
import { useAuth } from '@/contexts/AuthContext';
import { db } from '@/firebase/config';
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";
import EmptyState from '@/components/EmptyState.tsx';

interface Backup {
    id: string;
    createdAt: string;
}

// Função auxiliar para criar requisições e aguardar respostas
const makeRequest = (userUid: string, type: string, payload: object): Promise<any> => {
    return new Promise((resolve, reject) => {
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                unsubscribe();
                if (response.result) {
                    resolve(response.result);
                } else {
                    reject(new Error(response.error || "Ocorreu um erro desconhecido na função."));
                }
            }
        });

        setDoc(doc(db, 'function_requests', requestId), {
            type,
            requesterUid: userUid,
            createdAt: serverTimestamp(),
            payload,
        }).catch(err => {
            unsubscribe();
            reject(err);
        });
    });
};

export default function BackupSettings() {
    const context = useContext(SettingsContext);
    const { user } = useAuth();
    const [backups, setBackups] = useState<Backup[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [isActioning, setIsActioning] = useState<string | boolean>(false); // string para ID, boolean para geral
    const providerId = context?.providerId;

    const fetchBackups = useCallback(async () => {
        if (!providerId || !user) return;
        setIsLoading(true);
        try {
            const result = await makeRequest(user.uid, 'LIST_PROVIDER_BACKUPS', { providerId, requesterUid: user.uid });
            setBackups(result.backups || []);
        } catch (error: any) {
            toast.error(`Erro ao listar backups: ${error.message}`);
            setBackups([]); // Limpa em caso de erro
        } finally {
            setIsLoading(false);
        }
    }, [providerId, user]);

    useEffect(() => {
        if(providerId) {
            fetchBackups();
        } else {
            setIsLoading(false);
        }
    }, [providerId, fetchBackups]);

    const handleCreateBackup = async () => {
        if (!providerId || !user) return;
        setIsActioning(true);
        const toastId = toast.loading("A criar novo backup...");
        try {
            await makeRequest(user.uid, 'BACKUP_PROVIDER_CONFIG', { providerId, requesterUid: user.uid });
            toast.success("Backup criado com sucesso!", { id: toastId });
            fetchBackups();
        } catch (error: any) {
            toast.error(`Erro ao criar backup: ${error.message}`, { id: toastId });
        } finally {
            setIsActioning(false);
        }
    };

    const handleRestore = async (backupId: string) => {
        if (!providerId || !user) return;
        setIsActioning(backupId);
        const toastId = toast.loading(`A restaurar backup...`);
        try {
            await makeRequest(user.uid, 'RESTORE_PROVIDER_CONFIG', { providerId, backupId, requesterUid: user.uid });
            toast.success("Configurações restauradas! A página será recarregada.", { id: toastId });
            setTimeout(() => window.location.reload(), 2000);
        } catch (error: any) {
            toast.error(`Erro ao restaurar: ${error.message}`, { id: toastId });
        } finally {
            setIsActioning(false);
        }
    };
    
    const handleDelete = async (backupId: string) => {
        if (!providerId || !user) return;
        setIsActioning(backupId);
        const toastId = toast.loading(`Apagando backup...`);
        try {
            await makeRequest(user.uid, 'DELETE_PROVIDER_BACKUP', { providerId, backupId, requesterUid: user.uid });
            toast.success("Backup apagado.", { id: toastId });
            fetchBackups(); // Recarrega a lista
        } catch (error: any) {
            toast.error(`Erro ao apagar: ${error.message}`, { id: toastId });
        } finally {
            setIsActioning(false);
        }
    };

    return (
        <Card>
            <CardHeader>
                <div className="flex justify-between items-start">
                    <div>
                        <CardTitle>Backup e Restauração</CardTitle>
                        <CardDescription>Crie cópias de segurança das configurações de personalização ou restaure uma versão anterior.</CardDescription>
                    </div>
                    <Button onClick={handleCreateBackup} disabled={!!isActioning || isLoading}>
                        {isActioning === true ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <HardDriveUpload className="mr-2 h-4 w-4" />}
                        Criar Novo Backup
                    </Button>
                </div>
            </CardHeader>
            <CardContent>
                {isLoading ? (
                    <div className="flex justify-center items-center py-10"><Loader2 className="h-8 w-8 animate-spin" /></div>
                ) : backups.length === 0 ? (
                    <EmptyState 
                        icon={DatabaseZap}
                        title="Nenhum backup encontrado"
                        description="Crie um novo backup para guardar uma cópia das configurações atuais."
                    />
                ) : (
                    <Table>
                        <TableHeader><TableRow><TableHead>Data do Backup</TableHead><TableHead>ID do Backup</TableHead><TableHead className="text-right">Ações</TableHead></TableRow></TableHeader>
                        <TableBody>
                            {backups.map(backup => (
                                <TableRow key={backup.id}>
                                    <TableCell>{new Date(backup.createdAt).toLocaleString('pt-BR')}</TableCell>
                                    <TableCell className="font-mono">{backup.id}</TableCell>
                                    <TableCell className="text-right space-x-2">
                                        <AlertDialog>
                                            <AlertDialogTrigger asChild><Button variant="outline" size="sm" disabled={!!isActioning}><History className="mr-2 h-4 w-4" />Restaurar</Button></AlertDialogTrigger>
                                            <AlertDialogContent>
                                                <AlertDialogHeader><AlertDialogTitle>Restaurar este backup?</AlertDialogTitle><AlertDialogDescription>Todas as configurações de personalização atuais serão substituídas pelas do backup de {new Date(backup.createdAt).toLocaleString('pt-BR')}. Esta ação não pode ser desfeita.</AlertDialogDescription></AlertDialogHeader>
                                                <AlertDialogFooter><AlertDialogCancel>Cancelar</AlertDialogCancel><AlertDialogAction onClick={() => handleRestore(backup.id)}>Sim, restaurar</AlertDialogAction></AlertDialogFooter>
                                            </AlertDialogContent>
                                        </AlertDialog>
                                        <AlertDialog>
                                            <AlertDialogTrigger asChild><Button variant="destructive" size="sm" disabled={!!isActioning}><Trash2 className="h-4 w-4" /></Button></AlertDialogTrigger>
                                            <AlertDialogContent>
                                                <AlertDialogHeader><AlertDialogTitle>Apagar este backup?</AlertDialogTitle><AlertDialogDescription>Esta ação é permanente e não pode ser desfeita.</AlertDialogDescription></AlertDialogHeader>
                                                <AlertDialogFooter><AlertDialogCancel>Cancelar</AlertDialogCancel><AlertDialogAction onClick={() => handleDelete(backup.id)}>Sim, apagar</AlertDialogAction></AlertDialogFooter>
                                            </AlertDialogContent>
                                        </AlertDialog>
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                )}
            </CardContent>
        </Card>
    );
}
```

---

# 📊 Estatísticas Finais

- **Total de arquivos:** 87
- **Total de linhas:** 128
- **Componentes UI:** 21 (shadcn/ui)

