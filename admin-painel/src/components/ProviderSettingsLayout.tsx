import { NavLink, Outlet, useParams, useLocation } from "react-router-dom";
import { cn } from "@/lib/utils";
import { Button } from "./ui/button";
import { useAuth } from "@/contexts/AuthContext";

const menuItems = [
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
  { name: "Outros", path: "other" },
  { name: "Backup/Restore", path: "backup" },
];

const superAdminItems = [
  ...menuItems,
  { name: "Gerar app", path: "app-build" },
];

const groups = [
  { label: "Identidade visual", items: ["appearance", "typography", "icon-pack", "images", "splash-login"] },
  { label: "Conteúdo", items: ["menus", "dashboard-builder", "carousel", "promotions", "notifications", "tips", "faq", "messages", "texts"] },
  { label: "Configuração", items: ["features", "integrations", "support", "social", "other", "backup"] },
  { label: "Distribuição", items: ["app-build"] },
];

export default function ProviderSettingsLayout() {
  const { providerId: providerIdFromParams } = useParams();
  const { userRole, providerId: providerIdFromAuth } = useAuth();
  const location = useLocation();

  const providerId = userRole === 'superAdmin' ? providerIdFromParams : providerIdFromAuth;
  const basePath = userRole === 'superAdmin' ? `/provedores/${providerId}` : '/provedor/personalizacao';

  const items = userRole === 'superAdmin' ? superAdminItems : menuItems;
  const groupedItems = groups
    .map(group => ({
      ...group,
      items: group.items
        .map(path => items.find(item => item.path === path))
        .filter(Boolean) as typeof items,
    }))
    .filter(group => group.items.length > 0);

  const navLinkClass = (path: string) =>
    cn(
      "h-8 w-full justify-start rounded-lg px-2.5 text-[12.5px] font-medium",
      location.pathname.endsWith(path)
        ? "bg-primary/10 text-primary hover:bg-primary/10"
        : "text-[#4A5364] hover:bg-[#F2F4F8] hover:text-[#0E1320]"
    );

  return (
    <div className="grid grid-cols-1 gap-[22px] lg:grid-cols-[210px_1fr]">
      <aside>
        <nav className="lg:sticky lg:top-5">
          {groupedItems.map((group) => (
            <div key={group.label} className="mb-4 last:mb-0">
              <div className="px-2.5 pb-1.5 text-[10.5px] font-semibold uppercase tracking-[0.09em] text-[#98A1B1]">
                {group.label}
              </div>
              <div className="space-y-0.5">
                {group.items.map(item => (
                  <NavLink key={item.path} to={`${basePath}/${item.path}`}>
                    <Button variant="ghost" className={navLinkClass(item.path)}>
                      {item.name}
                    </Button>
                  </NavLink>
                ))}
              </div>
            </div>
          ))}
        </nav>
      </aside>
      <main className="min-w-0 pb-10">
        <Outlet />
      </main>
    </div>
  );
}
