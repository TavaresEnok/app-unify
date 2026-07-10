import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

export function Toolbar({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={cn("flex flex-wrap items-center gap-2", className)}>{children}</div>;
}

export function SectionHeader({ title, description, actions }: { title: string; description?: string; actions?: ReactNode }) {
  return (
    <div className="flex flex-col gap-2 border-b border-[#EEF0F4] pb-3 sm:flex-row sm:items-start sm:justify-between">
      <div><h3 className="text-sm font-semibold text-[#1A2233]">{title}</h3>{description && <p className="mt-1 text-xs text-[#687181]">{description}</p>}</div>
      {actions && <Toolbar>{actions}</Toolbar>}
    </div>
  );
}
