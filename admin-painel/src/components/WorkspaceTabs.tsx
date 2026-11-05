import { NavLink, Outlet } from "react-router-dom";
import { cn } from "@/lib/utils";

export interface WorkspaceTab { label: string; to: string; }

export function TabNavigation({ tabs, label }: { tabs: WorkspaceTab[]; label: string }) {
  return <nav aria-label={label} className="flex flex-wrap gap-1 border-b border-[#E6E9EF] pb-2">
    {tabs.map(tab => <NavLink key={tab.to} to={tab.to} className={({ isActive }) => cn(
      "rounded-lg px-3 py-2 text-sm font-medium transition-colors",
      isActive ? "bg-primary/10 text-primary" : "text-muted-foreground hover:bg-muted hover:text-foreground",
    )}>{tab.label}</NavLink>)}
  </nav>;
}

export default function WorkspaceTabs({ title, description, tabs }: { title: string; description: string; tabs: WorkspaceTab[] }) {
  return <div className="space-y-5">
    <div><h2 className="text-xl font-bold">{title}</h2><p className="mt-1 text-sm text-muted-foreground">{description}</p></div>
    <TabNavigation tabs={tabs} label={`Seções de ${title}`} />
    <Outlet />
  </div>;
}
