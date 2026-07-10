import { NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { useState } from "react";
import {
  Activity,
  Bell,
  Brush,
  Building2,
  LayoutDashboard,
  LogOut,
  Menu,
  MessageSquare,
  Search,
  Server,
  ShieldCheck,
  Users,
} from "lucide-react";
import { signOut, getIdTokenResult } from "firebase/auth";
import { auth } from "@/firebase/config";
import { useAuth } from "@/contexts/AuthContext";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";

type NavItem = {
  to: string;
  label: string;
  icon: typeof LayoutDashboard;
  badge?: string;
  match?: string;
};

const superAdminNav: NavItem[] = [
  { to: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { to: "/provedores", label: "Provedores", icon: Server },
  { to: "/utilizadores", label: "Utilizadores", icon: Users },
  { to: "/tickets", label: "Tickets", icon: MessageSquare },
];

const providerNav: NavItem[] = [
  { to: "/provedor/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { to: "/provedor/clientes", label: "Clientes", icon: Users },
  { to: "/provedor/notificacoes", label: "Notificações", icon: Bell },
  { to: "/provedor/minha-empresa", label: "Minha empresa", icon: Building2 },
  { to: "/provedor/personalizacao", label: "Personalização", icon: Brush },
  { to: "/provedor/tickets", label: "Suporte", icon: MessageSquare },
  { to: "/provedor/diagnosticos", label: "Diagnósticos", icon: Activity },
];

function Logo() {
  return (
    <div className="flex items-center gap-2.5">
      <div className="grid h-[27px] w-[27px] place-items-center rounded-[7px] bg-gradient-to-br from-primary to-[#16265D] text-[13.5px] font-bold text-white">
        U
      </div>
      <span className="text-[15.5px] font-bold tracking-normal text-[var(--sidebar-title)]">Unify</span>
    </div>
  );
}

function getInitials(email: string | null | undefined) {
  if (!email) return "?";
  const name = email.split("@")[0] || email;
  return name.slice(0, 2).toUpperCase();
}

function getDisplayName(email: string | null | undefined) {
  if (!email) return "Usuário";
  return email.split("@")[0].replace(/[._-]+/g, " ");
}

function titleForPath(pathname: string, isProvider: boolean) {
  if (pathname.startsWith("/provedores/")) return "Configuração do provedor";
  if (pathname.startsWith("/tickets/") || pathname.startsWith("/provedor/tickets/")) return "Ticket";
  if (pathname.startsWith("/provedor/clientes/")) return "Cliente";

  const titles: Record<string, string> = {
    "/dashboard": "Dashboard",
    "/provedores": "Provedores",
    "/utilizadores": "Utilizadores",
    "/tickets": "Tickets",
    "/provedor/dashboard": "Dashboard",
    "/provedor/clientes": "Clientes",
    "/provedor/notificacoes": "Notificações",
    "/provedor/minha-empresa": "Minha empresa",
    "/provedor/personalizacao": "Personalização do app",
    "/provedor/tickets": "Suporte",
    "/provedor/diagnosticos": "Diagnósticos",
  };

  return titles[pathname] || (isProvider ? "Painel" : "Unify");
}

export default function MainLayout() {
  const { user, userRole } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const isProvider = userRole !== "superAdmin";
  const navItems = isProvider ? providerNav : superAdminNav;
  const pageTitle = titleForPath(location.pathname, isProvider);
  const userInitials = getInitials(user?.email);
  const userName = getDisplayName(user?.email);
  const userRoleLabel = isProvider ? "Painel do provedor" : "Super Admin";

  const hasNotification = true;

  const handleLogout = async () => {
    await signOut(auth);
    navigate("/login");
  };

  const handleIdentityCheck = async () => {
    if (!user) {
      alert("Usuário não está logado.");
      return;
    }

    console.log("--- INICIANDO TESTE DE IDENTIDADE ---");
    const tokenResult = await getIdTokenResult(user, true);
    console.log("Email do Usuário:", tokenResult.claims.email);
    console.log("É Super Admin?", tokenResult.claims.superAdmin === true);
    console.log("ID do Provedor:", tokenResult.claims.providerId || "Nenhum");
    console.log("Todas as permissões (claims):", tokenResult.claims);
    alert("Verifique o console (F12) para ver suas permissões.");
  };

  const isActive = (item: NavItem) => {
    const match = item.match || item.to;
    return location.pathname === match || location.pathname.startsWith(`${match}/`);
  };

  const NavContent = ({ onNavigate }: { onNavigate?: () => void }) => (
    <div className="flex h-full flex-col bg-[var(--sidebar-bg)]">
      <div className="flex items-center gap-2.5 px-[18px] pb-3.5 pt-[18px]">
        <Logo />
        <span className="ml-auto rounded-[5px] border border-white/10 px-1.5 py-0.5 text-[9.5px] font-semibold uppercase tracking-[0.08em] text-[var(--sidebar-muted)]">
          {isProvider ? "PAINEL" : "ADMIN"}
        </span>
      </div>

      <nav className="flex-1 overflow-y-auto px-2.5 py-2">
        <div className="px-2.5 pb-1.5 pt-2 text-[10.5px] font-semibold uppercase tracking-[0.09em] text-[var(--sidebar-muted)]">
          {isProvider ? "Provedor" : "Plataforma"}
        </div>
        <div className="space-y-0.5">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = isActive(item);

            return (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={onNavigate}
                className={cn(
                  "flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-[13.5px] font-medium transition-colors",
                  active
                    ? "bg-[var(--sidebar-active-bg)] text-[var(--sidebar-title)]"
                    : "text-[var(--sidebar-item)] hover:bg-white/10 hover:text-[var(--sidebar-title)]"
                )}
              >
                <Icon className="h-4 w-4 shrink-0" strokeWidth={1.8} />
                <span className="min-w-0 flex-1 truncate">{item.label}</span>
                {item.badge && !active && (
                  <span className="rounded-full bg-primary px-1.5 py-0.5 text-[10.5px] font-semibold text-white">{item.badge}</span>
                )}
              </NavLink>
            );
          })}
        </div>
      </nav>

      <div className="border-t border-[var(--sidebar-border)] p-3">
        <div className="flex items-center gap-2.5">
          <Avatar className="h-[30px] w-[30px]">
            <AvatarFallback className="bg-primary/30 text-[11.5px] font-semibold text-white">{userInitials}</AvatarFallback>
          </Avatar>
          <div className="min-w-0 flex-1">
            <div className="truncate text-[12.5px] font-semibold text-[var(--sidebar-title)]">{userName}</div>
            <div className="truncate text-[11px] text-[var(--sidebar-muted)]">{userRoleLabel}</div>
          </div>
          <Button
            variant="ghost"
            size="icon"
            title="Sair"
            onClick={handleLogout}
            className="h-7 w-7 text-[var(--sidebar-muted)] hover:bg-white/10 hover:text-[var(--sidebar-title)]"
          >
            <LogOut className="h-[15px] w-[15px]" />
          </Button>
        </div>
        <Button
          variant="ghost"
          size="sm"
          onClick={handleIdentityCheck}
          className="mt-3 h-8 w-full justify-start gap-2 text-[12px] text-[var(--sidebar-item)] hover:bg-white/10 hover:text-[var(--sidebar-title)]"
        >
          <ShieldCheck className="h-3.5 w-3.5" />
          Testar identidade
        </Button>
      </div>
    </div>
  );

  return (
    <div className="flex h-screen w-full overflow-hidden bg-background text-foreground">
      <aside className="hidden w-[234px] shrink-0 border-r border-[var(--sidebar-border)] bg-[var(--sidebar-bg)] md:flex">
        <NavContent />
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex h-[58px] shrink-0 items-center gap-4 border-b border-[#E8EBF0] bg-white px-4 md:px-6">
          <Sheet open={mobileMenuOpen} onOpenChange={setMobileMenuOpen}>
            <SheetTrigger asChild className="md:hidden">
              <Button variant="ghost" size="icon" aria-label="Abrir menu">
                <Menu className="h-4 w-4" />
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="w-[234px] border-0 bg-[var(--sidebar-bg)] p-0 text-white sm:max-w-none">
              <NavContent onNavigate={() => setMobileMenuOpen(false)} />
            </SheetContent>
          </Sheet>

          <div className="min-w-0">
            <h1 className="truncate text-[15px] font-semibold tracking-normal text-[#0E1320]">{pageTitle}</h1>
          </div>

          <div className="flex-1" />

          <div className="relative hidden w-[260px] sm:block">
            <Search className="absolute left-[11px] top-[9px] h-3.5 w-3.5 text-[#98A1B1]" strokeWidth={2} />
            <input
              placeholder="Pesquisar..."
              className="h-8 w-full rounded-lg border border-[#E0E4EC] bg-[#F7F8FA] py-[7px] pl-8 pr-3 text-[12.5px] text-[#1A2233] outline-none placeholder:text-[#98A1B1] focus:border-primary focus:ring-2 focus:ring-primary/15"
            />
          </div>

          <Button
            variant="ghost"
            size="icon"
            aria-label="Notificações"
            className="relative h-8 w-8 text-[#5B6472] hover:bg-[#F2F4F8]"
          >
            <Bell className="h-4 w-4" strokeWidth={1.8} />
            {hasNotification && <span className="absolute right-[7px] top-1.5 h-[7px] w-[7px] rounded-full border border-white bg-[#C2362B]" />}
          </Button>

          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <button className="grid h-[30px] w-[30px] place-items-center rounded-full bg-primary/10 text-[11.5px] font-bold text-primary outline-none ring-offset-background focus-visible:ring-2 focus-visible:ring-ring">
                {userInitials}
              </button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-48">
              <DropdownMenuItem onClick={handleIdentityCheck}>Testar identidade</DropdownMenuItem>
              <DropdownMenuItem onClick={handleLogout}>Sair</DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </header>

        <main className="flex-1 overflow-y-auto">
          <div className="mx-auto w-full max-w-[1180px] px-4 py-5 sm:px-7 sm:py-[26px]">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}
