import type { ReactNode } from "react";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";

export function FormField({ id, label, description, error, children }: { id: string; label: string; description?: string; error?: string; children: ReactNode }) {
  return <div className="space-y-1.5"><Label htmlFor={id}>{label}</Label>{children}{error ? <p className="text-xs text-destructive">{error}</p> : description ? <p className="text-xs text-muted-foreground">{description}</p> : null}</div>;
}

export function ColorField({ id, label, value, onChange }: { id: string; label: string; value: string; onChange: (value: string) => void }) {
  return (
    <FormField id={id} label={label}>
      <div className="flex items-center gap-2">
        <input id={`${id}-swatch`} type="color" value={value} onChange={(event) => onChange(event.target.value)} className="h-9 w-10 cursor-pointer rounded border border-input bg-transparent p-1" aria-label={`${label} - seletor`} />
        <Input id={id} value={value} onChange={(event) => onChange(event.target.value)} className="font-mono" />
      </div>
    </FormField>
  );
}
