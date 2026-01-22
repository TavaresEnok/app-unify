import { NavLink, Outlet, useLocation, useNavigate } from "react-router-dom";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";
import { LayoutDashboard, Server, Users, Brush, Bell, MessageSquare, ShieldCheck, Menu, X, Activity } from "lucide-react";
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
            <NavLink to="/provedor/diagnosticos" onClick={onNavigate}><Button variant="ghost" className={getNavLinkClass("/provedor/diagnosticos")}><Activity className="mr-4 h-5 w-5" />Diagnósticos</Button></NavLink>
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
