import { NavLink, Outlet, useParams, useLocation } from "react-router-dom";
import { cn } from "@/lib/utils";
import { Button } from "./ui/button";
import { useAuth } from "@/contexts/AuthContext";

const menuItems = [
  { name: "Aparência", path: "theme" },
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
