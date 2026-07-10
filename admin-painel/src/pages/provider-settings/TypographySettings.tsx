import { useContext, useCallback, memo } from 'react';
import { SettingsContext } from '@/contexts/SettingsContext';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Type, Save, Loader2, ALargeSmall, Weight } from 'lucide-react';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

// Google Fonts disponíveis
const GOOGLE_FONTS = [
    { value: 'Inter', label: 'Inter (Moderno)' },
    { value: 'Roboto', label: 'Roboto (Material)' },
    { value: 'Outfit', label: 'Outfit (Elegante)' },
    { value: 'Poppins', label: 'Poppins (Arredondado)' },
    { value: 'Open Sans', label: 'Open Sans (Legível)' },
    { value: 'Montserrat', label: 'Montserrat (Premium)' },
    { value: 'Nunito', label: 'Nunito (Amigável)' },
    { value: 'Lato', label: 'Lato (Neutro)' },
];

const FONT_SIZES = [
    { value: 'small', label: 'Pequeno' },
    { value: 'medium', label: 'Médio (Padrão)' },
    { value: 'large', label: 'Grande' },
];

const FONT_WEIGHTS = [
    { value: 'regular', label: 'Regular (400)' },
    { value: 'medium', label: 'Medium (500)' },
    { value: 'semibold', label: 'Semibold (600)' },
    { value: 'bold', label: 'Bold (700)' },
];

interface TypographyRowProps {
    label: string;
    icon: React.ComponentType<{ className?: string }>;
    value: string;
    options: { value: string; label: string }[];
    onChange: (val: string) => void;
}

const TypographyRow = memo(({ label, icon: Icon, value, options, onChange }: TypographyRowProps) => (
    <div className="space-y-2 rounded-lg border border-[#EEF0F4] bg-white p-3">
        <Label className="flex items-center gap-2 text-[12.5px] font-semibold text-[#39414F]">
            <Icon className="h-4 w-4 text-[#98A1B1]" /> {label}
        </Label>
        <Select value={value} onValueChange={onChange}>
            <SelectTrigger className="w-full">
                <SelectValue placeholder="Selecione..." />
            </SelectTrigger>
            <SelectContent>
                {options.map((opt) => (
                    <SelectItem key={opt.value} value={opt.value}>
                        {opt.label}
                    </SelectItem>
                ))}
            </SelectContent>
        </Select>
    </div>
));

TypographyRow.displayName = 'TypographyRow';

export default function TypographySettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, saveConfig, isSaving } = context;

    // Valores atuais ou defaults
    const typography = config.typography || {
        fontFamily: 'Inter',
        titleSize: 'medium',
        bodySize: 'medium',
        fontWeight: 'medium',
    };

    const updateTypography = useCallback((key: string, value: string) => {
        setConfig((prev: any) => ({
            ...prev,
            typography: {
                ...prev.typography,
                [key]: value,
            },
        }));
    }, [setConfig]);

    return (
        <SettingsPage
            title="Tipografia"
            description="Configure fontes, pesos e tamanhos de texto do aplicativo."
            icon={Type}
            footer={(
                <>
                    <SettingsFooterNote>As fontes serão aplicadas no próximo build do aplicativo.</SettingsFooterNote>
                    <Button onClick={saveConfig} disabled={isSaving} className="gap-2">
                        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                        {isSaving ? "Salvando..." : "Salvar alterações"}
                    </Button>
                </>
            )}
        >
                <SettingsSection title="Preview da fonte" description="Visualize a família selecionada antes de salvar.">
                <div
                    className="rounded-lg border border-[#EEF0F4] bg-white p-6 text-center"
                    style={{ fontFamily: typography.fontFamily }}
                >
                    <p className="text-2xl font-bold mb-2">Exemplo de Título</p>
                    <p className="text-base text-muted-foreground">
                        Texto de exemplo para visualizar a fonte selecionada.
                    </p>
                    <p className="text-sm mt-2 text-muted-foreground/70">
                        ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789
                    </p>
                </div>
                </SettingsSection>

                <SettingsSection title="Seletores" description="Ajustes de família, peso e escala de leitura.">
                <div className="grid gap-6 sm:grid-cols-2">
                    <TypographyRow
                        label="Família da Fonte"
                        icon={Type}
                        value={typography.fontFamily}
                        options={GOOGLE_FONTS}
                        onChange={(val) => updateTypography('fontFamily', val)}
                    />
                    <TypographyRow
                        label="Peso da Fonte"
                        icon={Weight}
                        value={typography.fontWeight}
                        options={FONT_WEIGHTS}
                        onChange={(val) => updateTypography('fontWeight', val)}
                    />
                </div>

                <div className="grid gap-6 sm:grid-cols-2">
                    <TypographyRow
                        label="Tamanho dos Títulos"
                        icon={ALargeSmall}
                        value={typography.titleSize}
                        options={FONT_SIZES}
                        onChange={(val) => updateTypography('titleSize', val)}
                    />
                    <TypographyRow
                        label="Tamanho do Corpo"
                        icon={ALargeSmall}
                        value={typography.bodySize}
                        options={FONT_SIZES}
                        onChange={(val) => updateTypography('bodySize', val)}
                    />
                </div>
                </SettingsSection>
        </SettingsPage>
    );
}
