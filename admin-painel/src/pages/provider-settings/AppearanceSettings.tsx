import { useCallback, useMemo, memo } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { cn } from '@/lib/utils';
import { Check, CreditCard, Loader2, MonitorSmartphone, Palette, RotateCcw, Save, Smartphone, Type, Zap } from 'lucide-react';
import { toast } from 'sonner';

interface ColorRowProps {
    label: string;
    description: string;
    id: string;
    value: string;
    icon: React.ComponentType<{ className?: string }>;
    swatches: string[];
    onChange: (id: string, val: string) => void;
}

const safeColor = (value?: string, fallback = '#000000') => /^#[0-9A-Fa-f]{6}$/.test(value || '') ? value! : fallback;

const ColorRow = memo(({ label, description, id, value, icon: Icon, swatches, onChange }: ColorRowProps) => {
    const current = safeColor(value);

    return (
        <div className="grid gap-3 rounded-lg border border-[#EEF0F4] bg-white p-3 sm:grid-cols-[1fr_auto] sm:items-center">
            <div className="flex min-w-0 items-center gap-3">
                <div className="grid h-[34px] w-[34px] shrink-0 place-items-center rounded-lg border border-[#E6E9EF]" style={{ backgroundColor: current }}>
                    <Icon className="h-4 w-4 text-white drop-shadow" />
                </div>
                <div className="min-w-0">
                    <Label htmlFor={id} className="text-[12.5px] font-semibold text-[#39414F]">{label}</Label>
                    <p className="mt-0.5 text-[11.5px] text-[#98A1B1]">{description}</p>
                </div>
            </div>

            <div className="flex flex-wrap items-center gap-2 sm:justify-end">
                <input
                    id={id}
                    type="color"
                    className="h-8 w-8 cursor-pointer rounded-lg border border-[#D6DBE4] bg-white p-1"
                    value={current}
                    onChange={event => onChange(id, event.target.value)}
                    aria-label={label}
                />
                <Input
                    value={value || ''}
                    onChange={event => onChange(id, event.target.value)}
                    className="h-8 w-[94px] font-mono text-[11.5px] uppercase"
                    maxLength={7}
                    placeholder="#000000"
                />
                <div className="flex items-center gap-1.5">
                    {swatches.map((swatch) => {
                        const selected = swatch.toLowerCase() === current.toLowerCase();
                        return (
                            <button
                                key={swatch}
                                type="button"
                                className="h-6 w-6 rounded-full border border-white transition-transform hover:scale-105"
                                style={{
                                    backgroundColor: swatch,
                                    boxShadow: selected ? '0 0 0 2px #fff, 0 0 0 4px var(--brand,#2F55D4)' : 'inset 0 0 0 1px rgba(0,0,0,.14)'
                                }}
                                onClick={() => onChange(id, swatch)}
                                aria-label={`Usar ${swatch} em ${label}`}
                            />
                        );
                    })}
                </div>
            </div>
        </div>
    );
});

ColorRow.displayName = 'ColorRow';

const layoutOptions = [
    { value: 'layout_01', title: 'Padrão original', desc: 'Base clássica do app', variant: 'grid' },
    { value: 'layout_02', title: 'NetLink Premium', desc: 'Claro com destaque comercial', variant: 'cards' },
    { value: 'layout_03', title: 'Vibe Modern', desc: 'Neumorphic e leve', variant: 'cards' },
    { value: 'layout_04', title: 'Clean Light', desc: 'Operacional e claro', variant: 'list' },
    { value: 'layout_05', title: 'Cyber Neon', desc: 'Escuro com contraste alto', variant: 'list' },
    { value: 'layout_06', title: 'Clean Dark', desc: 'Escuro e minimalista', variant: 'grid' },
];

const diagnosticOptions = [
    { value: 'default', label: 'Padrão', desc: 'Baseado no layout atual' },
    { value: 'diagnostic_02', label: 'Cyberpunk Dark', desc: 'Gráficos em tempo real' },
    { value: 'diagnostic_03', label: 'Elegant Dark', desc: 'Gauge animado' },
    { value: 'diagnostic_05', label: 'Clean Light', desc: 'Neumorphic' },
    { value: 'diagnostic_06', label: 'Minimal Light', desc: 'Timeline' },
    { value: 'diagnostic_07', label: 'Zenith Premium', desc: 'Mesh particles' },
];

const colorGroups = [
    {
        title: 'Cores da marca',
        description: 'Base principal usada no app e no preview.',
        items: [
            { id: 'themeColor', label: 'Cor principal', description: 'Header, botões e estados ativos.', icon: Palette, swatches: ['#0E7AFE', '#2F55D4', '#0F9D6E', '#7C3AED', '#E2543E'] },
            { id: 'secondaryColor', label: 'Cor secundária', description: 'Gradientes e apoios visuais.', icon: Palette, swatches: ['#12B5A5', '#F5A623', '#4C5FD5', '#DB4C77', '#00E676'] },
            { id: 'backgroundColor', label: 'Fundo do app', description: 'Cor de fundo da área principal.', icon: Smartphone, swatches: ['#F4F6FA', '#FFFFFF', '#FFF6EA', '#0A0E21', '#050810'] },
        ],
    },
    {
        title: 'Superfícies e ações',
        description: 'Controles que definem cards, botões e blocos de cobrança.',
        items: [
            { id: 'actionColor', label: 'Botões de ação', description: 'Chamadas principais do cliente.', icon: Zap, swatches: ['#2F55D4', '#157347', '#F5A623', '#E2543E', '#7C3AED'] },
            { id: 'cardColor', label: 'Cards principais', description: 'Fatura, avisos e containers.', icon: CreditCard, swatches: ['#FFFFFF', '#F8FAFC', '#0F1225', '#161B22', '#2D0A4E'] },
            { id: 'invoiceColor', label: 'Fatura', description: 'Bloco financeiro em destaque.', icon: CreditCard, swatches: ['#2F55D4', '#157347', '#9A5B0B', '#B3372B', '#0E1320'] },
            { id: 'textColor', label: 'Texto', description: 'Cor principal de leitura.', icon: Type, swatches: ['#0E1320', '#1F2937', '#FFFFFF', '#39414F', '#111827'] },
            { id: 'iconColor', label: 'Ícones', description: 'Ícones do app e atalhos.', icon: Zap, swatches: ['#2F55D4', '#00BCD4', '#00E676', '#F5A623', '#FFFFFF'] },
        ],
    },
    {
        title: 'Cards avançados',
        description: 'Ajustes específicos de atalhos e demais cards da tela inicial.',
        items: [
            { id: 'quickActionsCardColor', label: 'Fundo ações rápidas', description: 'Cards de atalhos principais.', icon: CreditCard, swatches: ['#FFFFFF', '#F8FAFC', '#0F1225', '#161B22', '#2D0A4E'] },
            { id: 'quickActionsTextColor', label: 'Texto ações rápidas', description: 'Labels dentro dos atalhos.', icon: Type, swatches: ['#0E1320', '#39414F', '#FFFFFF', '#2F55D4', '#00E676'] },
            { id: 'otherCardsColor', label: 'Fundo outros cards', description: 'Blocos secundários do app.', icon: CreditCard, swatches: ['#FFFFFF', '#F8FAFC', '#0F1225', '#161B22', '#2D0A4E'] },
            { id: 'otherCardsTextColor', label: 'Texto outros cards', description: 'Textos de cards secundários.', icon: Type, swatches: ['#0E1320', '#39414F', '#FFFFFF', '#2F55D4', '#00E676'] },
        ],
    },
];

function LayoutThumbnail({ variant, active, primary }: { variant: string; active: boolean; primary: string }) {
    return (
        <div className={cn("rounded-lg border bg-white p-2", active ? "border-primary" : "border-[#E6E9EF]")}>
            <div className="mb-2 h-5 rounded-md" style={{ backgroundColor: primary }} />
            {variant === 'list' ? (
                <div className="space-y-1.5">
                    {[0, 1, 2].map(item => <div key={item} className="h-3 rounded bg-[#EEF0F4]" />)}
                </div>
            ) : variant === 'cards' ? (
                <div className="space-y-1.5">
                    <div className="h-7 rounded bg-[#EEF0F4]" />
                    <div className="grid grid-cols-2 gap-1.5">
                        <div className="h-4 rounded bg-[#F2F4F7]" />
                        <div className="h-4 rounded bg-[#F2F4F7]" />
                    </div>
                </div>
            ) : (
                <div className="grid grid-cols-3 gap-1.5">
                    {[0, 1, 2, 3, 4, 5].map(item => <div key={item} className="h-4 rounded bg-[#EEF0F4]" />)}
                </div>
            )}
        </div>
    );
}

function AppearancePreview({ config }: { config: any }) {
    const primary = safeColor(config.themeColor, '#2F55D4');
    const secondary = safeColor(config.secondaryColor, '#12B5A5');
    const background = safeColor(config.backgroundColor, '#F4F6FA');
    const card = safeColor(config.cardColor, '#FFFFFF');
    const text = safeColor(config.textColor, '#0E1320');
    const icon = safeColor(config.iconColor, primary);
    const quickCard = safeColor(config.quickActionsCardColor, card);
    const quickText = safeColor(config.quickActionsTextColor, text);
    const otherCard = safeColor(config.otherCardsColor, card);
    const otherText = safeColor(config.otherCardsTextColor, text);
    const layout = layoutOptions.find(item => item.value === (config.layoutType || 'layout_06')) || layoutOptions[5];
    const useBackgroundImage = config.other?.useBackgroundImage || false;

    return (
        <Card className="xl:sticky xl:top-5">
            <CardHeader>
                <CardTitle>Preview do app</CardTitle>
                <CardDescription>Atualiza em tempo real conforme a personalização.</CardDescription>
            </CardHeader>
            <CardContent className="flex justify-center p-[18px]">
                <div className="h-[438px] w-[214px] overflow-hidden rounded-[30px] border-[6px] border-[#10182B] bg-[#10182B] shadow-xl">
                    <div className="flex h-full flex-col overflow-hidden rounded-[24px]" style={{ backgroundColor: background, color: text }}>
                        <div className="flex h-7 items-end justify-between px-4 pb-1 text-[9px] font-semibold" style={{ color: useBackgroundImage ? '#FFFFFF' : text }}>
                            <span>12:30</span>
                            <span>5G 82%</span>
                        </div>
                        <div
                            className="px-4 pb-5 pt-3"
                            style={{ background: useBackgroundImage ? `linear-gradient(135deg, ${primary}, ${secondary})` : `linear-gradient(145deg, ${primary}, ${secondary})` }}
                        >
                            <div className="mb-5 flex items-center justify-between text-white">
                                <div>
                                    <div className="mb-1 h-2 w-16 rounded-full bg-white/55" />
                                    <div className="h-2 w-10 rounded-full bg-white/35" />
                                </div>
                                <div className="grid h-7 w-7 place-items-center rounded-full bg-white/20 text-[10px] font-bold">U</div>
                            </div>
                            <div className="rounded-2xl bg-white/18 p-3 text-white ring-1 ring-white/20">
                                <div className="mb-3 flex items-center justify-between">
                                    <div className="h-2 w-14 rounded-full bg-white/55" />
                                    <div className="h-4 w-12 rounded-full bg-emerald-400/60" />
                                </div>
                                <div className="mb-2 h-5 w-24 rounded-md bg-white/90" />
                                <div className="h-2 w-20 rounded-full bg-white/35" />
                            </div>
                        </div>
                        <div className="flex-1 overflow-hidden px-4 py-4">
                            {layout.variant === 'list' ? (
                                <div className="space-y-2">
                                    {['Faturas', 'Consumo', 'Suporte', 'Diagnóstico'].map(item => (
                                        <div key={item} className="flex items-center gap-2 rounded-xl p-2.5" style={{ backgroundColor: card }}>
                                            <span className="h-6 w-6 rounded-lg" style={{ backgroundColor: `${icon}24` }} />
                                            <span className="text-[10px] font-semibold" style={{ color: text }}>{item}</span>
                                            <span className="ml-auto text-[10px]" style={{ color: icon }}>›</span>
                                        </div>
                                    ))}
                                </div>
                            ) : layout.variant === 'cards' ? (
                                <div className="space-y-2.5">
                                    <div className="rounded-2xl p-3" style={{ backgroundColor: card }}>
                                        <div className="mb-2 h-2 w-16 rounded-full" style={{ backgroundColor: `${text}2A` }} />
                                        <div className="h-5 w-24 rounded" style={{ backgroundColor: primary }} />
                                    </div>
                                    <div className="rounded-2xl p-3" style={{ backgroundColor: quickCard, color: quickText }}>
                                        <div className="mb-2 h-2 w-20 rounded-full opacity-40" style={{ backgroundColor: quickText }} />
                                        <div className="grid grid-cols-3 gap-2">
                                            {[0, 1, 2].map(item => <span key={item} className="h-8 rounded-lg" style={{ backgroundColor: `${icon}22` }} />)}
                                        </div>
                                    </div>
                                    <div className="rounded-2xl p-3" style={{ backgroundColor: otherCard, color: otherText }}>
                                        <div className="h-2 w-24 rounded-full opacity-40" style={{ backgroundColor: otherText }} />
                                    </div>
                                </div>
                            ) : (
                                <>
                                    <div className="mb-3 grid grid-cols-3 gap-2">
                                        {['2ª', 'Pix', 'Wi-Fi', 'Chat', 'Uso', 'FAQ'].map(item => (
                                            <div key={item} className="grid h-14 place-items-center rounded-xl text-[9px] font-semibold" style={{ backgroundColor: quickCard, color: quickText }}>
                                                <span className="h-5 w-5 rounded-lg" style={{ backgroundColor: `${icon}24` }} />
                                                {item}
                                            </div>
                                        ))}
                                    </div>
                                    <div className="rounded-2xl p-3" style={{ backgroundColor: otherCard, color: otherText }}>
                                        <div className="mb-2 h-2 w-20 rounded-full opacity-40" style={{ backgroundColor: otherText }} />
                                        <div className="h-14 rounded-xl" style={{ backgroundColor: `${primary}18` }} />
                                    </div>
                                </>
                            )}
                        </div>
                    </div>
                </div>
            </CardContent>
        </Card>
    );
}

export default function AppearanceSettings() {
    const { config, setConfig, saveConfig, isSaving } = useSettings();

    const updateLayoutThemes = useCallback((newConfig: any, layoutToUpdate: string, values: any) => {
        const currentStrings = newConfig.strings || {};
        const layoutThemes = currentStrings.layoutThemes ? JSON.parse(typeof currentStrings.layoutThemes === 'string' ? currentStrings.layoutThemes : JSON.stringify(currentStrings.layoutThemes)) : {};

        layoutThemes[layoutToUpdate] = {
            themeColor: values.themeColor,
            secondaryColor: values.secondaryColor,
            actionColor: values.actionColor,
            invoiceColor: values.invoiceColor,
            cardColor: values.cardColor,
            textColor: values.textColor,
            backgroundColor: values.backgroundColor,
            iconColor: values.iconColor,
            quickActionsCardColor: values.quickActionsCardColor,
            quickActionsTextColor: values.quickActionsTextColor,
            otherCardsColor: values.otherCardsColor,
            otherCardsTextColor: values.otherCardsTextColor,
        };

        return {
            ...newConfig,
            strings: {
                ...currentStrings,
                layoutThemes: JSON.stringify(layoutThemes)
            }
        };
    }, []);

    const handleColorChange = useCallback((id: string, val: string) => {
        setConfig((previous: any) => {
            const updated = { ...previous, [id]: val };
            return updateLayoutThemes(updated, previous.layoutType || 'layout_06', updated);
        });
    }, [setConfig, updateLayoutThemes]);

    const layoutDefaults: Record<string, Record<string, string>> = useMemo(() => ({
        layout_01: {
            themeColor: '#673AB7',
            secondaryColor: '#9575CD',
            backgroundColor: '#F4F6FA',
            cardColor: '#FFFFFF',
            textColor: '#1F2937',
            iconColor: '#673AB7',
            quickActionsCardColor: '#FFFFFF',
            quickActionsTextColor: '#1F2937',
            otherCardsColor: '#FFFFFF',
            otherCardsTextColor: '#1F2937',
        },
        layout_02: {
            themeColor: '#E91E63',
            secondaryColor: '#6A1B9A',
            backgroundColor: '#1A0533',
            cardColor: '#2D0A4E',
            textColor: '#FFFFFF',
            iconColor: '#FFD600',
            quickActionsCardColor: '#2D0A4E',
            quickActionsTextColor: '#FFFFFF',
            otherCardsColor: '#2D0A4E',
            otherCardsTextColor: '#FFFFFF',
        },
        layout_03: {
            themeColor: '#00D4FF',
            secondaryColor: '#FF00FF',
            backgroundColor: '#0A0A0F',
            cardColor: '#1A1A2E',
            textColor: '#FFFFFF',
            iconColor: '#00D4FF',
            quickActionsCardColor: '#1A1A2E',
            quickActionsTextColor: '#FFFFFF',
            otherCardsColor: '#1A1A2E',
            otherCardsTextColor: '#FFFFFF',
        },
        layout_04: {
            themeColor: '#0891B2',
            secondaryColor: '#059669',
            backgroundColor: '#F5F7FA',
            cardColor: '#FFFFFF',
            textColor: '#1F2937',
            iconColor: '#0891B2',
            quickActionsCardColor: '#FFFFFF',
            quickActionsTextColor: '#1F2937',
            otherCardsColor: '#FFFFFF',
            otherCardsTextColor: '#1F2937',
        },
        layout_05: {
            themeColor: '#00E5FF',
            secondaryColor: '#7C4DFF',
            backgroundColor: '#050810',
            cardColor: '#161B22',
            textColor: '#FFFFFF',
            iconColor: '#00E5FF',
            quickActionsCardColor: '#161B22',
            quickActionsTextColor: '#FFFFFF',
            otherCardsColor: '#161B22',
            otherCardsTextColor: '#FFFFFF',
        },
        layout_06: {
            themeColor: '#00BCD4',
            secondaryColor: '#00E676',
            backgroundColor: '#0A0E21',
            cardColor: '#0F1225',
            textColor: '#FFFFFF',
            iconColor: '#00BCD4',
            quickActionsCardColor: '#0F1225',
            quickActionsTextColor: '#FFFFFF',
            otherCardsColor: '#0F1225',
            otherCardsTextColor: '#FFFFFF',
        },
    }), []);

    const handleLayoutChange = useCallback((newLayout: string) => {
        setConfig((prev: any) => {
            const nextConfig = updateLayoutThemes(prev, prev.layoutType || 'layout_01', prev);
            const layoutThemes = nextConfig.strings?.layoutThemes ? JSON.parse(nextConfig.strings.layoutThemes) : {};
            const savedTheme = layoutThemes[newLayout];
            const defaults = layoutDefaults[newLayout] || layoutDefaults.layout_01;

            return {
                ...nextConfig,
                ...defaults,
                ...(savedTheme || {}),
                layoutType: newLayout
            };
        });
    }, [layoutDefaults, setConfig, updateLayoutThemes]);

    const restoreLayoutDefaults = () => {
        const currentLayout = config.layoutType || 'layout_01';
        const defaults = layoutDefaults[currentLayout] || layoutDefaults.layout_01;
        setConfig((prev: any) => updateLayoutThemes({ ...prev, ...defaults }, currentLayout, defaults));
        toast.success('Cores padrão restauradas!');
    };

    const activeLayout = config.layoutType || 'layout_06';
    const primary = safeColor(config.themeColor, '#2F55D4');

    return (
        <div className="grid gap-4 xl:grid-cols-[1fr_290px]">
            <Card className="overflow-hidden">
                <CardHeader className="flex-row flex-wrap items-center justify-between gap-3">
                    <div>
                        <CardTitle>Aparência</CardTitle>
                        <CardDescription>Personalize o visual do app sem perder as configurações avançadas por layout.</CardDescription>
                    </div>
                    <Button variant="outline" size="sm" onClick={restoreLayoutDefaults} className="gap-2">
                        <RotateCcw className="h-4 w-4" />
                        Restaurar padrão
                    </Button>
                </CardHeader>

                <CardContent className="space-y-6">
                    <section className="space-y-3">
                        <div className="flex items-end justify-between gap-3">
                            <div>
                                <h3 className="text-[13px] font-semibold text-[#1A2233]">Layout do app</h3>
                                <p className="mt-0.5 text-[12px] text-[#687181]">Escolha o template visual. As cores salvas de cada layout são preservadas.</p>
                            </div>
                            <Select value={activeLayout} onValueChange={handleLayoutChange}>
                                <SelectTrigger className="hidden w-[210px] sm:flex">
                                    <SelectValue placeholder="Escolha o layout" />
                                </SelectTrigger>
                                <SelectContent>
                                    {layoutOptions.map(option => (
                                        <SelectItem key={option.value} value={option.value}>{option.title}</SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>

                        <div className="grid gap-3 sm:grid-cols-2 2xl:grid-cols-3">
                            {layoutOptions.map(option => {
                                const active = activeLayout === option.value;
                                return (
                                    <button
                                        key={option.value}
                                        type="button"
                                        className={cn(
                                            "rounded-xl border p-3 text-left transition-colors",
                                            active ? "border-primary bg-primary/5" : "border-[#E6E9EF] bg-white hover:bg-[#F8FAFC]"
                                        )}
                                        onClick={() => handleLayoutChange(option.value)}
                                    >
                                        <LayoutThumbnail variant={option.variant} active={active} primary={active ? primary : '#CBD2DD'} />
                                        <div className="mt-3 flex items-center justify-between gap-2">
                                            <div>
                                                <p className={cn("text-[12.5px] font-semibold", active ? "text-primary" : "text-[#1A2233]")}>{option.title}</p>
                                                <p className="mt-0.5 text-[11.5px] text-[#98A1B1]">{option.desc}</p>
                                            </div>
                                            {active && <Check className="h-4 w-4 text-primary" />}
                                        </div>
                                    </button>
                                );
                            })}
                        </div>
                    </section>

                    <section className="grid gap-4 lg:grid-cols-[1fr_1fr]">
                        <div className="rounded-xl border border-[#EEF0F4] bg-[#FAFBFC] p-4">
                            <Label className="mb-3 flex items-center gap-2 text-[12.5px] font-semibold text-[#39414F]">
                                <MonitorSmartphone className="h-4 w-4" />
                                Estilo do diagnóstico
                            </Label>
                            <Select value={config.diagnosticStyle || 'default'} onValueChange={(val) => setConfig((p: any) => ({ ...p, diagnosticStyle: val }))}>
                                <SelectTrigger className="w-full">
                                    <SelectValue placeholder="Escolha o estilo do diagnóstico" />
                                </SelectTrigger>
                                <SelectContent>
                                    {diagnosticOptions.map(option => (
                                        <SelectItem key={option.value} value={option.value}>{option.label} - {option.desc}</SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>

                        <div className="rounded-xl border border-[#EEF0F4] bg-[#FAFBFC] p-4">
                            <Label className="mb-3 flex items-center gap-2 text-[12.5px] font-semibold text-[#39414F]">
                                <Smartphone className="h-4 w-4" />
                                Cabeçalho e serviços
                            </Label>
                            <div className="space-y-3">
                                <div className="flex items-center justify-between gap-3">
                                    <span className="text-[12.5px] text-[#4A5364]">Cabeçalho com imagem</span>
                                    <Switch checked={config.other?.useBackgroundImage || false} onCheckedChange={(checked) => setConfig((p: any) => ({ ...p, other: { ...(p.other || {}), useBackgroundImage: checked } }))} />
                                </div>
                                <div className="flex items-center justify-between gap-3">
                                    <span className="text-[12.5px] text-[#4A5364]">Mostrar serviço de TV</span>
                                    <Switch checked={config.other?.showTvService ?? true} onCheckedChange={(checked) => setConfig((p: any) => ({ ...p, other: { ...(p.other || {}), showTvService: checked } }))} />
                                </div>
                                <div className="flex items-center justify-between gap-3">
                                    <span className="text-[12.5px] text-[#4A5364]">Mostrar serviço de Telefone</span>
                                    <Switch checked={config.other?.showPhoneService ?? true} onCheckedChange={(checked) => setConfig((p: any) => ({ ...p, other: { ...(p.other || {}), showPhoneService: checked } }))} />
                                </div>
                            </div>
                        </div>
                    </section>

                    {colorGroups.map(group => (
                        <section key={group.title} className="space-y-3">
                            <div>
                                <h3 className="text-[13px] font-semibold text-[#1A2233]">{group.title}</h3>
                                <p className="mt-0.5 text-[12px] text-[#687181]">{group.description}</p>
                            </div>
                            <div className="grid gap-3">
                                {group.items.map(item => (
                                    <ColorRow
                                        key={item.id}
                                        label={item.label}
                                        description={item.description}
                                        id={item.id}
                                        value={config[item.id]}
                                        icon={item.icon}
                                        swatches={item.swatches}
                                        onChange={handleColorChange}
                                    />
                                ))}
                            </div>
                        </section>
                    ))}
                </CardContent>

                <CardFooter className="flex flex-col items-stretch justify-between gap-3 sm:flex-row sm:items-center">
                    <p className="text-[12px] text-[#98A1B1]">As alterações são aplicadas ao preview imediatamente e gravadas ao salvar.</p>
                    <Button onClick={() => void saveConfig()} disabled={isSaving} className="gap-2">
                        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                        {isSaving ? "Salvando..." : "Salvar alterações"}
                    </Button>
                </CardFooter>
            </Card>

            <AppearancePreview config={config} />
        </div>
    );
}
