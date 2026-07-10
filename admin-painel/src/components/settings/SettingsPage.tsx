import { ReactNode } from 'react';
import { LucideIcon } from 'lucide-react';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { cn } from '@/lib/utils';

interface SettingsPageProps {
  title: string;
  description?: string;
  icon?: LucideIcon;
  actions?: ReactNode;
  children: ReactNode;
  footer?: ReactNode;
  className?: string;
  contentClassName?: string;
}

export function SettingsPage({ title, description, icon: Icon, actions, children, footer, className, contentClassName }: SettingsPageProps) {
  return (
    <Card className={cn('overflow-hidden', className)}>
      <CardHeader className="flex-row flex-wrap items-center justify-between gap-3">
        <div className="min-w-0">
          <CardTitle className="flex items-center gap-2">
            {Icon && <Icon className="h-4 w-4 text-[#98A1B1]" />}
            {title}
          </CardTitle>
          {description && <CardDescription>{description}</CardDescription>}
        </div>
        {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
      </CardHeader>
      <CardContent className={cn('space-y-4', contentClassName)}>{children}</CardContent>
      {footer && <CardFooter className="flex flex-col items-stretch justify-between gap-3 sm:flex-row sm:items-center">{footer}</CardFooter>}
    </Card>
  );
}

interface SettingsSectionProps {
  title?: string;
  description?: string;
  children: ReactNode;
  className?: string;
  actions?: ReactNode;
}

export function SettingsSection({ title, description, children, className, actions }: SettingsSectionProps) {
  return (
    <section className={cn('rounded-xl border border-[#EEF0F4] bg-[#FAFBFC] p-4', className)}>
      {(title || description || actions) && (
        <div className="mb-4 flex flex-wrap items-start justify-between gap-3">
          <div>
            {title && <h3 className="text-[13px] font-semibold text-[#1A2233]">{title}</h3>}
            {description && <p className="mt-0.5 text-[12px] text-[#687181]">{description}</p>}
          </div>
          {actions}
        </div>
      )}
      {children}
    </section>
  );
}

interface SettingRowProps {
  icon?: LucideIcon;
  title: ReactNode;
  description?: ReactNode;
  children?: ReactNode;
  className?: string;
}

export function SettingRow({ icon: Icon, title, description, children, className }: SettingRowProps) {
  return (
    <div className={cn('flex flex-col gap-3 rounded-lg border border-[#EEF0F4] bg-white p-3 sm:flex-row sm:items-center sm:justify-between', className)}>
      <div className="flex min-w-0 items-start gap-3">
        {Icon && (
          <span className="grid h-8 w-8 shrink-0 place-items-center rounded-lg bg-primary/10 text-primary">
            <Icon className="h-4 w-4" />
          </span>
        )}
        <div className="min-w-0">
          <div className="text-[12.5px] font-semibold text-[#1A2233]">{title}</div>
          {description && <div className="mt-0.5 text-[12px] leading-5 text-[#687181]">{description}</div>}
        </div>
      </div>
      {children && <div className="flex shrink-0 items-center gap-2 sm:justify-end">{children}</div>}
    </div>
  );
}

export function SettingsFooterNote({ children }: { children: ReactNode }) {
  return <p className="text-[12px] leading-5 text-[#98A1B1]">{children}</p>;
}
