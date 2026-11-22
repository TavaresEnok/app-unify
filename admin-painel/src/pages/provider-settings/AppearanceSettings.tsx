import { useState } from 'react';
import { useSettings, type ProviderConfig } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { cn } from '@/lib/utils';
import { Check, Loader2, Palette, RotateCcw, Save } from 'lucide-react';
import { toast } from 'sonner';

const defaultBrand = '#2456C9';
const brandPresets = [
    { color: '#FC46AA', name: 'Rosa', asset: 'rosa' },
    { color: defaultBrand, name: 'Azul', asset: 'azul' },
    { color: '#137650', name: 'Verde', asset: 'verde' },
];
const isHexColor = (value: unknown): value is string => typeof value === 'string' && /^#[0-9a-f]{6}$/i.test(value);

const layoutOptions = [
    { value: 'layout_02', title: 'Histórico na folha', desc: 'Fatura no topo e atalhos na folha' },
    { value: 'layout_03', title: 'Dock de serviços', desc: 'Fatura e dock de serviços' },
    { value: 'layout_04', title: 'Blocos escuros', desc: 'Cartões e serviços em blocos' },
    { value: 'layout_05', title: 'Faixa e fatura', desc: 'Fatura em destaque na faixa' },
    { value: 'layout_06', title: 'Topo centralizado', desc: 'Valor centralizado no topo' },
];

function previewAsset(layout: string, color: string, dark = false) {
    const preset = brandPresets.find(item => item.color === color.toUpperCase());
    return `/assets/layout-previews/preview-${layout.slice(-2)}-${preset?.asset ?? 'azul'}-${dark ? 'dark' : 'light'}.webp`;
}

export function AppearancePreview({ config }: { config: Pick<ProviderConfig, 'layoutType' | 'themeColor'> }) {
    const [dark, setDark] = useState(false);
    const layout = effectiveLayout(config.layoutType);
    const color = isHexColor(config.themeColor) ? config.themeColor.toUpperCase() : defaultBrand;
    const custom = !brandPresets.some(preset => preset.color === color);
    const title = layoutOptions.find(option => option.value === layout)!.title;

    return (
        <Card className="xl:sticky xl:top-5">
            <CardHeader>
                <CardTitle>Prévia do app</CardTitle>
                <CardDescription>{title}</CardDescription>
                <div className="flex gap-2 pt-2">
                    <Button type="button" variant={dark ? 'outline' : 'default'} size="sm" aria-pressed={!dark} onClick={() => setDark(false)}>Claro</Button>
                    <Button type="button" variant={dark ? 'default' : 'outline'} size="sm" aria-pressed={dark} onClick={() => setDark(true)}>Escuro</Button>
                </div>
            </CardHeader>
            <CardContent className="flex justify-center p-[18px]">
                <figure className="w-[214px]">
                    <img src={previewAsset(layout, color, dark)} alt={`Prévia de ${title} no modo ${dark ? 'escuro' : 'claro'}`}
                        className="w-full rounded-[24px] border-[6px] border-[#10182b]" />
                    <figcaption className="mt-2 text-center text-xs text-muted-foreground">
                        {custom ? <>
                            <span className="mb-1 flex items-center justify-center gap-2">
                                <span aria-hidden="true" className="h-4 w-4 rounded-full border" style={{ backgroundColor: color }} />
                                Sua cor no app <strong>{color}</strong>
                            </span>
                            Exemplo do layout em azul com dados fictícios.
                        </> : 'Exemplo do layout com dados fictícios.'}
                    </figcaption>
                </figure>
            </CardContent>
        </Card>
    );
}

function effectiveLayout(value: unknown): string {
    return typeof value === 'string' && layoutOptions.some(option => option.value === value)
        ? value : 'layout_06';
}

function parseLayoutThemes(value: unknown): Record<string, Record<string, string>> {
    try {
        const parsed = typeof value === 'string' ? JSON.parse(value) : value;
        return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? { ...parsed } : {};
    } catch {
        return {};
    }
}

function withBrand(config: ProviderConfig, layout: string, color: string): ProviderConfig {
    const themes = parseLayoutThemes(config.strings?.layoutThemes);
    themes[layout] = { ...themes[layout], themeColor: color };
    return { ...config, themeColor: color, strings: { ...config.strings, layoutThemes: JSON.stringify(themes) } };
}

export default function AppearanceSettings() {
    const { config, setConfig, saveConfig, isSaving } = useSettings();
    const activeLayout = effectiveLayout(config.layoutType);
    const primary = isHexColor(config.themeColor) ? config.themeColor : defaultBrand;
    const savedThemes = parseLayoutThemes(config.strings?.layoutThemes);
    const [draftColor, setDraftColor] = useState<string | null>(null);

    function handleColorChange(color: string) {
        if (!isHexColor(color)) {
            setDraftColor(color);
            return;
        }
        setDraftColor(null);
        setConfig(previous => withBrand(previous, effectiveLayout(previous.layoutType), color));
    }

    function handleLayoutChange(newLayout: string) {
        if (activeLayout === newLayout || effectiveLayout(newLayout) !== newLayout) return;
        setDraftColor(null);
        setConfig(previous => {
            const oldColor = isHexColor(previous.themeColor) ? previous.themeColor : defaultBrand;
            const retained = withBrand(previous, effectiveLayout(previous.layoutType), oldColor);
            const saved = parseLayoutThemes(retained.strings?.layoutThemes)[newLayout]?.themeColor;
            return { ...retained, layoutType: newLayout as ProviderConfig['layoutType'], themeColor: isHexColor(saved) ? saved : defaultBrand };
        });
    }

    function restoreLayoutDefaults() {
        handleColorChange(defaultBrand);
        toast.success('Azul padrão restaurado para este layout.');
    }

    return (
        <div className="grid gap-4 xl:grid-cols-[1fr_290px]">
            <Card className="overflow-hidden">
                <CardHeader className="flex-row flex-wrap items-center justify-between gap-3">
                    <div>
                        <CardTitle>Aparência</CardTitle>
                        <CardDescription>Escolha o layout e a cor da marca que o assinante verá no app.</CardDescription>
                    </div>
                    <Button variant="outline" size="sm" onClick={restoreLayoutDefaults} className="gap-2">
                        <RotateCcw className="h-4 w-4" />
                        Restaurar cores padrão
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
                                const savedColor = savedThemes[option.value]?.themeColor;
                                const sampleColor = active ? primary : isHexColor(savedColor) ? savedColor : defaultBrand;
                                return (
                                    <button
                                        key={option.value}
                                        type="button"
                                        className={cn(
                                            "rounded-xl border p-3 text-left transition-colors",
                                            active ? "border-primary bg-primary/5" : "border-[#E6E9EF] bg-white hover:bg-[#F8FAFC]"
                                        )}
                                        aria-pressed={active}
                                        onClick={() => handleLayoutChange(option.value)}
                                    >
                                        <img src={previewAsset(option.value, sampleColor)} alt="" loading="lazy"
                                            className="h-40 w-full rounded-lg bg-muted object-contain" />
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

                    <section className="space-y-3">
                        <Label htmlFor="theme-color" className="flex items-center gap-2 font-semibold">
                            <Palette className="h-4 w-4" /> Cor principal
                        </Label>
                        <div className="flex flex-wrap gap-2">
                            {brandPresets.map(preset => (
                                <Button key={preset.color} type="button" variant="outline" size="sm"
                                    aria-pressed={draftColor === null && primary.toUpperCase() === preset.color}
                                    onClick={() => handleColorChange(preset.color)}>
                                    <span aria-hidden="true" className="mr-2 h-4 w-4 rounded-full border" style={{ backgroundColor: preset.color }} />
                                    {preset.name}
                                </Button>
                            ))}
                        </div>
                        <div className="flex items-center gap-2">
                            <input id="theme-color" type="color" value={primary} onChange={event => handleColorChange(event.target.value)}
                                className="h-9 w-10 cursor-pointer rounded border bg-white p-1" />
                            <Input value={draftColor ?? primary} onChange={event => handleColorChange(event.target.value)}
                                aria-label="Cor personalizada em hexadecimal" aria-invalid={draftColor !== null}
                                aria-describedby={draftColor !== null ? 'theme-color-error' : undefined}
                                className="h-9 w-28 font-mono uppercase" maxLength={7} />
                        </div>
                        {draftColor !== null && <p id="theme-color-error" className="text-xs text-destructive">Use # seguido de seis dígitos hexadecimais.</p>}
                    </section>
                </CardContent>

                <CardFooter className="flex flex-col items-stretch justify-between gap-3 sm:flex-row sm:items-center">
                    <p className="text-[12px] text-[#98A1B1]">Salve para aplicar as alterações ao app do provedor.</p>
                    <Button onClick={() => void saveConfig().catch(() => undefined)} disabled={isSaving || draftColor !== null} className="gap-2">
                        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                        {isSaving ? "Salvando..." : "Salvar alterações"}
                    </Button>
                </CardFooter>
            </Card>

            <AppearancePreview config={config} />
        </div>
    );
}
