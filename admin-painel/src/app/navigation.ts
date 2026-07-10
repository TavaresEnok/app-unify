import {
  Activity,
  Bell,
  Brush,
  Building2,
  LayoutDashboard,
  MessageSquare,
  Server,
  Users,
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
  { to: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { to: "/provedores", label: "Provedores", icon: Server },
  { to: "/utilizadores", label: "Utilizadores", icon: Users },
  { to: "/tickets", label: "Tickets", icon: MessageSquare },
];

export const PROVIDER_NAVIGATION: NavigationItem[] = [
  { to: "/provedor/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { to: "/provedor/clientes", label: "Clientes", icon: Users },
  { to: "/provedor/notificacoes", label: "Notificações", icon: Bell },
  { to: "/provedor/minha-empresa", label: "Minha empresa", icon: Building2 },
  { to: "/provedor/personalizacao", label: "Personalização", icon: Brush },
  { to: "/provedor/tickets", label: "Suporte", icon: MessageSquare },
  { to: "/provedor/diagnosticos", label: "Diagnósticos", icon: Activity },
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
  { name: "Notificações", path: "notifications" },
  { name: "Promoções", path: "promotions" },
  { name: "Módulos", path: "features" },
  { name: "Integrações", path: "integrations" },
  { name: "Contato & Suporte", path: "support" },
  { name: "Carrossel", path: "carousel" },
  { name: "Redes Sociais", path: "social" },
  { name: "Dicas", path: "tips" },
  { name: "FAQ", path: "faq" },
  { name: "Mensagens", path: "messages" },
  { name: "Textos", path: "texts" },
  { name: "Termos de uso", path: "terms" },
  { name: "Atualização do app", path: "force-update" },
  { name: "Outros", path: "other" },
  { name: "Backup/Restore", path: "backup" },
  { name: "Gerar app", path: "app-build", superAdminOnly: true },
];

export const SETTINGS_GROUPS = [
  { label: "Identidade visual", items: ["appearance", "typography", "icon-pack", "images", "splash-login"] },
  { label: "Conteúdo", items: ["menus", "dashboard-builder", "carousel", "promotions", "notifications", "tips", "faq", "messages", "texts", "terms"] },
  { label: "Configuração", items: ["features", "integrations", "support", "social", "force-update", "other", "backup"] },
  { label: "Distribuição", items: ["app-build"] },
] as const;

export function titleForPath(pathname: string, isProvider: boolean): string {
  if (pathname.startsWith("/provedores/")) return "Configuração do provedor";
  if (pathname.startsWith("/tickets/") || pathname.startsWith("/provedor/tickets/")) return "Ticket";
  if (pathname.startsWith("/provedor/clientes/")) return "Cliente";
  const items = isProvider ? PROVIDER_NAVIGATION : SUPER_ADMIN_NAVIGATION;
  const match = items.find((item) => pathname === item.to || pathname.startsWith(`${item.to}/`));
  return match?.label || (isProvider ? "Painel" : "Unify");
}
