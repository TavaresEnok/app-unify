import {
  Bell,
  Brush,
  Building2,
  LayoutDashboard,
  MessageSquare,
  Server,
  Users,
  Smartphone,
  type LucideIcon,
} from "lucide-react";

export interface NavigationItem {
  to: string;
  label: string;
  icon: LucideIcon;
  badge?: string;
  match?: string;
}

export const SUPER_ADMIN_NAVIGATION: NavigationItem[] = [
  { to: "/dashboard", label: "Visão geral", icon: LayoutDashboard },
  { to: "/provedores", label: "Provedores", icon: Server },
  { to: "/usuarios", label: "Equipe", icon: Users },
  { to: "/tickets", label: "Suporte", icon: MessageSquare },
];

export const PROVIDER_NAVIGATION: NavigationItem[] = [
  { to: "/provedor/dashboard", label: "Visão geral", icon: LayoutDashboard },
  { to: "/provedor/clientes", label: "Clientes", icon: Users },
  { to: "/provedor/atendimento", label: "Atendimento", icon: MessageSquare },
  { to: "/provedor/comunicados", label: "Comunicados", icon: Bell },
  { to: "/provedor/personalizacao", label: "Personalização", icon: Brush },
  { to: "/provedor/minha-empresa", label: "Minha empresa", icon: Building2 },
  { to: "/provedor/aplicativo", label: "Aplicativo", icon: Smartphone },
];

export interface SettingsNavigationItem {
  name: string;
  path: string;
  superAdminOnly?: boolean;
  /** O aplicativo ainda não lê esta configuração: a tela fica marcada como "Em breve". */
  comingSoon?: boolean;
}

export const SETTINGS_NAVIGATION: SettingsNavigationItem[] = [
  { name: "Aparência", path: "appearance" },
  { name: "Tipografia", path: "typography", comingSoon: true },
  { name: "Pack de Ícones", path: "icon-pack", comingSoon: true },
  { name: "Imagens & Ícones", path: "images" },
  { name: "Splash/Login", path: "splash-login", comingSoon: true },
  { name: "Menus", path: "menus" },
  { name: "Dashboard", path: "dashboard-builder", comingSoon: true },
  { name: "Promoções", path: "promotions" },
  { name: "Módulos", path: "features" },
  { name: "Integrações", path: "integrations", superAdminOnly: true },
  { name: "Contato & Suporte", path: "support" },
  { name: "Carrossel", path: "carousel" },
  { name: "Redes Sociais", path: "social", comingSoon: true },
  { name: "Dicas", path: "tips" },
  { name: "FAQ", path: "faq" },
  { name: "Mensagens", path: "messages", comingSoon: true },
  { name: "Textos", path: "texts" },
  { name: "Termos de uso", path: "terms", comingSoon: true },
  { name: "Privacidade", path: "privacy" },
  { name: "Versão do app", path: "force-update" },
  { name: "Configurações do aplicativo", path: "application-settings" },
  { name: "Backup/Restore", path: "backup" },
  { name: "Gerar app", path: "app-build", superAdminOnly: true },
];

export const SETTINGS_GROUPS = [
  { label: "Identidade visual", items: ["appearance", "images", "typography", "icon-pack", "splash-login"] },
  { label: "Tela inicial e navegação", items: ["menus", "features", "dashboard-builder"] },
  { label: "Conteúdo", items: ["carousel", "promotions", "tips", "faq", "texts", "messages"] },
  { label: "Contato e informações legais", items: ["support", "privacy", "social", "terms"] },
  { label: "Configurações", items: ["application-settings", "force-update", "backup"] },
  { label: "Operação técnica", items: ["integrations", "app-build"] },
] as const;

export function titleForPath(pathname: string, isProvider: boolean): string {
  if (pathname.startsWith("/provedores/")) return "Configuração do provedor";
  if (pathname.startsWith("/tickets/") || pathname.startsWith("/provedor/tickets/") || pathname.startsWith("/provedor/atendimento/chamados/")) return "Ticket";
  if (pathname === "/conta/senha") return "Minha conta";
  const items = isProvider ? PROVIDER_NAVIGATION : SUPER_ADMIN_NAVIGATION;
  const match = items.find((item) => pathname === item.to || pathname.startsWith(`${item.to}/`));
  return match?.label || (isProvider ? "Painel" : "Unify");
}

export const COMING_SOON_MESSAGE = "Em breve no app: esta configuração ainda não aparece no aplicativo do assinante. Você pode preparar o conteúdo, mas ele não muda nada por enquanto.";

export function settingsItemForPath(pathname: string): SettingsNavigationItem | undefined {
  return SETTINGS_NAVIGATION.find((item) => pathname.endsWith(`/${item.path}`));
}
