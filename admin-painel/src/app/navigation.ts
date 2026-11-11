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
  { to: "/utilizadores", label: "Equipe", icon: Users },
  { to: "/tickets", label: "Suporte", icon: MessageSquare },
];

export const PROVIDER_NAVIGATION: NavigationItem[] = [
  { to: "/provedor/dashboard", label: "Visão geral", icon: LayoutDashboard },
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
}

export const SETTINGS_NAVIGATION: SettingsNavigationItem[] = [
  { name: "Aparência", path: "appearance" },
  { name: "Tipografia", path: "typography" },
  { name: "Pack de Ícones", path: "icon-pack" },
  { name: "Imagens & Ícones", path: "images" },
  { name: "Splash/Login", path: "splash-login" },
  { name: "Menus", path: "menus" },
  { name: "Dashboard", path: "dashboard-builder" },
  { name: "Promoções", path: "promotions" },
  { name: "Módulos", path: "features" },
  { name: "Integrações", path: "integrations", superAdminOnly: true },
  { name: "Contato & Suporte", path: "support" },
  { name: "Carrossel", path: "carousel" },
  { name: "Redes Sociais", path: "social" },
  { name: "Dicas", path: "tips" },
  { name: "FAQ", path: "faq" },
  { name: "Mensagens", path: "messages" },
  { name: "Textos", path: "texts" },
  { name: "Termos de uso", path: "terms" },
  { name: "Privacidade", path: "privacy" },
  { name: "Atualização do app", path: "force-update" },
  { name: "Configurações do aplicativo", path: "application-settings" },
  { name: "Backup/Restore", path: "backup" },
  { name: "Gerar app", path: "app-build", superAdminOnly: true },
];

export const SETTINGS_GROUPS = [
  { label: "Identidade visual", items: ["appearance", "typography", "icon-pack", "images", "splash-login"] },
  { label: "Tela inicial e navegação", items: ["dashboard-builder", "menus", "features"] },
  { label: "Conteúdo", items: ["carousel", "promotions", "tips", "faq", "messages", "texts"] },
  { label: "Contato e informações legais", items: ["support", "social", "terms", "privacy"] },
  { label: "Configurações", items: ["application-settings", "force-update", "backup"] },
  { label: "Operação técnica", items: ["integrations", "app-build"] },
] as const;

export function titleForPath(pathname: string, isProvider: boolean): string {
  if (pathname.startsWith("/provedores/")) return "Configuração do provedor";
  if (pathname.startsWith("/tickets/") || pathname.startsWith("/provedor/tickets/") || pathname.startsWith("/provedor/atendimento/chamados/")) return "Ticket";
  const items = isProvider ? PROVIDER_NAVIGATION : SUPER_ADMIN_NAVIGATION;
  const match = items.find((item) => pathname === item.to || pathname.startsWith(`${item.to}/`));
  return match?.label || (isProvider ? "Painel" : "Unify");
}
