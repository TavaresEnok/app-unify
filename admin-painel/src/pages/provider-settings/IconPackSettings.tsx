import { useSettings } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Save, Loader2, Check, Shapes } from 'lucide-react';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';
import { cn } from '@/lib/utils';

// O app desenha os próprios ícones de traço (layout aprovado); o que muda
// por provedor é a espessura do traço. Fatores iguais aos do app
// (provider_config.dart: thin 0,8 · regular 1 · bold 1,25 sobre 1,8).
const ICON_STYLES = [
    { value: 'thin', label: 'Fino', description: 'Leve e delicado.', stroke: 1.45 },
    { value: 'regular', label: 'Padrão', description: 'O traço do layout.', stroke: 1.8 },
    { value: 'bold', label: 'Forte', description: 'Mais presença e contraste.', stroke: 2.25 },
] as const;

type IconStyle = typeof ICON_STYLES[number]['value'];

function PreviewIcons({ stroke }: { stroke: number }) {
    const common = { width: 26, height: 26, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: stroke, strokeLinecap: 'round' as const, strokeLinejoin: 'round' as const };
    return (
        <div className="flex gap-4 text-primary">
            {/* fatura, wi-fi, chat e casa no mesmo desenho de traço do app */}
            <svg {...common}><path d="M7 3h7l4 4v14H7z" /><path d="M14 3v4h4M10 12h5M10 16h5" /></svg>
            <svg {...common}><path d="M2.5 9a14 14 0 0 1 19 0M5.5 12.5a9.5 9.5 0 0 1 13 0M9 16a4.5 4.5 0 0 1 6 0" /><circle cx="12" cy="19.5" r=".8" /></svg>
            <svg {...common}><path d="M20 15a2 2 0 0 1-2 2H8l-4 4V5a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2z" /></svg>
            <svg {...common}><path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z" /></svg>
        </div>
    );
}

export default function IconPackSettings() {
    const { config, setConfig, saveConfig, isSaving } = useSettings();
    const current = (ICON_STYLES.some(s => s.value === config.iconStyle) ? config.iconStyle : 'regular') as IconStyle;

    return (
        <SettingsPage
            title="Ícones"
            description="Espessura do traço dos ícones do aplicativo."
            icon={Shapes}
            footer={(
                <>
                    <SettingsFooterNote>Vale para apps a partir da versão 1.0.22: o app aplica ao abrir, sem gerar um app novo.</SettingsFooterNote>
                    <Button onClick={() => void saveConfig()} disabled={isSaving} className="gap-2">
                        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                        {isSaving ? 'Salvando...' : 'Salvar alterações'}
                    </Button>
                </>
            )}
        >
            <SettingsSection title="Estilo do traço" description="Os ícones usam a cor da marca; aqui muda só a espessura.">
                <div className="grid gap-3 sm:grid-cols-3">
                    {ICON_STYLES.map((style) => (
                        <button
                            key={style.value}
                            type="button"
                            aria-pressed={current === style.value}
                            onClick={() => setConfig((prev) => ({ ...prev, iconStyle: style.value }))}
                            className={cn(
                                'relative rounded-lg border bg-white p-4 text-left transition-colors',
                                current === style.value ? 'border-primary ring-2 ring-primary/20' : 'border-[#EEF0F4] hover:border-[#D5DAE3]',
                            )}
                        >
                            {current === style.value && <Check className="absolute right-3 top-3 h-4 w-4 text-primary" />}
                            <PreviewIcons stroke={style.stroke} />
                            <span className="mt-3 block font-semibold text-[#18202C]">{style.label}</span>
                            <span className="block text-xs text-muted-foreground">{style.description}</span>
                        </button>
                    ))}
                </div>
            </SettingsSection>
        </SettingsPage>
    );
}
