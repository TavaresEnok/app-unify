import { NavLink, Outlet, useParams, useLocation } from "react-router-dom";
import { cn } from "@/lib/utils";
import { useAuth } from "@/contexts/AuthContext";
import { SETTINGS_GROUPS, SETTINGS_NAVIGATION } from "@/app/navigation";
import { TabNavigation } from "@/components/WorkspaceTabs";

export default function ProviderSettingsLayout() {
  const { providerId: providerIdFromParams } = useParams();
  const { userRole, providerId: providerIdFromAuth } = useAuth();
  const location = useLocation();

  const providerId = userRole === 'superAdmin' ? providerIdFromParams : providerIdFromAuth;
  const basePath = userRole === 'superAdmin' ? `/provedores/${providerId}` : '/provedor/personalizacao';

  const items = SETTINGS_NAVIGATION.filter((item) => userRole === 'superAdmin' || !item.superAdminOnly);
  const groupedItems = SETTINGS_GROUPS
    .map(group => ({
      ...group,
      items: group.items
        .map(path => items.find(item => item.path === path))
        .filter(Boolean) as typeof items,
    }))
    .filter(group => group.items.length > 0);

  const activeGroup = groupedItems.find(group => group.items.some(item => location.pathname.endsWith(`/${item.path}`)));

  return (
    <div className="grid grid-cols-1 gap-[22px] lg:grid-cols-[210px_1fr]">
      <aside>
        <nav aria-label="Áreas de personalização" className="lg:sticky lg:top-5">
          <div className="space-y-1">
            {groupedItems.map(group => (
              <NavLink key={group.label} to={`${basePath}/${group.items[0].path}`} className={cn(
                  "flex min-h-9 w-full items-center justify-start whitespace-normal rounded-lg px-2.5 py-2 text-left text-[12.5px] font-medium",
                  activeGroup === group ? "bg-primary/10 text-primary" : "text-[#4A5364] hover:bg-muted",
                )}>{group.label}</NavLink>
            ))}
          </div>
        </nav>
      </aside>
      <main className="min-w-0 space-y-5 pb-10">
        {activeGroup && <TabNavigation label={`Seções de ${activeGroup.label}`} tabs={activeGroup.items.map(item => ({ label: item.name, to: `${basePath}/${item.path}` }))} />}
        <Outlet />
      </main>
    </div>
  );
}
