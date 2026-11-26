import { useSettings } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Type, Save, Loader2, Check } from 'lucide-react';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';
import { cn } from '@/lib/utils';

// Só as fontes que já vêm dentro do app (app-flutter/unified/pubspec.yaml):
// o app não baixa fontes da internet. "layout" mantém a fonte do layout.
const APP_FONTS = [
    { value: 'layout', label: 'Padrão do layout', description: 'A fonte desenhada para o layout escolhido em Aparência.', css: 'inherit' },
    { value: 'PlusJakartaSans', label: 'Plus Jakarta Sans', description: 'Moderna e amigável.', css: '"Plus Jakarta Sans", sans-serif' },
    { value: 'Sora', label: 'Sora', description: 'Geométrica, com personalidade.', css: 'Sora, sans-serif' },
    { value: 'Inter', label: 'Inter', description: 'Neutra e muito legível.', css: 'Inter, sans-serif' },
] as const;

const TEXT_SCALES = [
    { value: 'small', label: 'Menor', factor: 0.94 },
    { value: 'medium', label: 'Padrão', factor: 1 },
    { value: 'large', label: 'Maior', factor: 1.08 },
] as const;

type AppFont = typeof APP_FONTS[number]['value'];
type TextScale = typeof TEXT_SCALES[number]['value'];

export default function TypographySettings() {
    const { config, setConfig, saveConfig, isSaving } = useSettings();
    const typography = (config.typography ?? {}) as Record<string, string | undefined>;
    const appFont = (APP_FONTS.some(f => f.value === typography.appFont) ? typography.appFont : 'layout') as AppFont;
    const textScale = (TEXT_SCALES.some(s => s.value === typography.textScale) ? typography.textScale : 'medium') as TextScale;
    const font = APP_FONTS.find(f => f.value === appFont)!;
    const factor = TEXT_SCALES.find(s => s.value === textScale)!.factor;

    const update = (patch: { appFont?: AppFont; textScale?: TextScale }) => {
        setConfig((prev) => {
            const current = (prev.typography ?? {}) as Record<string, string | undefined>;
            const next: Record<string, string | undefined> = { ...current, ...patch };
            if (next.appFont === 'layout') delete next.appFont;
            return { ...prev, typography: next as typeof prev.typography };
        });
    };

    return (
        <SettingsPage
            title="Tipografia"
            description="Fonte e tamanho do texto do aplicativo."
            icon={Type}
            footer={(
                <>
                    <SettingsFooterNote>Vale para apps a partir da versão 1.0.22: o app aplica ao abrir, sem gerar um app novo.</SettingsFooterNote>
                    <Button onClick={() => void saveConfig()} disabled={isSaving} className="gap-2">
                        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                        {isSaving ? "Salvando..." : "Salvar alterações"}
                    </Button>
                </>
            )}
        >
            <SettingsSection title="Fonte do aplicativo" description="Usada em todos os textos do app.">
                <div className="grid gap-3 sm:grid-cols-2">
                    {APP_FONTS.map((option) => (
                        <button
                            key={option.value}
                            type="button"
                            onClick={() => update({ appFont: option.value })}
                            aria-pressed={appFont === option.value}
                            className={cn(
                                'relative rounded-lg border bg-white p-4 text-left transition-colors',
                                appFont === option.value ? 'border-primary ring-2 ring-primary/20' : 'border-[#EEF0F4] hover:border-[#D5DAE3]',
                            )}
                        >
                            {appFont === option.value && <Check className="absolute right-3 top-3 h-4 w-4 text-primary" />}
                            <span className="block text-lg font-bold text-[#18202C]" style={{ fontFamily: option.css }}>{option.label}</span>
                            <span className="mt-1 block text-xs text-muted-foreground">{option.description}</span>
                        </button>
                    ))}
                </div>
            </SettingsSection>

            <SettingsSection title="Tamanho do texto" description="Soma-se ao tamanho que o assinante já usa no celular.">
                <div className="inline-flex rounded-lg border border-[#EEF0F4] bg-white p-1" role="radiogroup" aria-label="Tamanho do texto">
                    {TEXT_SCALES.map((option) => (
                        <button
                            key={option.value}
                            type="button"
                            role="radio"
                            aria-checked={textScale === option.value}
                            onClick={() => update({ textScale: option.value })}
                            className={cn(
                                'rounded-md px-4 py-2 text-sm font-medium transition-colors',
                                textScale === option.value ? 'bg-primary text-primary-foreground' : 'text-[#596577] hover:bg-[#F5F6F9]',
                            )}
                        >
                            {option.label}
                        </button>
                    ))}
                </div>
            </SettingsSection>

            <SettingsSection title="Prévia" description="Aproximação de como o texto aparece no app.">
                <div className="rounded-lg border border-[#EEF0F4] bg-white p-6" style={{ fontFamily: font.css }}>
                    <p className="font-extrabold text-[#18202C]" style={{ fontSize: 22 * factor }}>Olá, Maria</p>
                    <p className="mt-1 text-[#596577]" style={{ fontSize: 14 * factor }}>Sua fatura de dezembro vence dia 10.</p>
                    <p className="mt-3 font-bold text-[#18202C]" style={{ fontSize: 26 * factor }}>R$ 99,90</p>
                </div>
            </SettingsSection>
        </SettingsPage>
    );
}
