import { useContext, useCallback, memo } from 'react';
import { SettingsContext } from '@/contexts/SettingsContext';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Palette, Type, CreditCard, Zap, Smartphone, Loader2, Save } from 'lucide-react';
import { toast } from 'sonner';
import MobilePreview from '@/components/MobilePreview';

interface ColorRowProps {
    label: string;
    id: string;
    value: string;
    icon: React.ComponentType<{ className?: string }>;
    onChange: (id: string, val: string) => void;
}

const ColorRow = memo(({ label, id, value, icon: Icon, onChange }: ColorRowProps) => {
    return (
        <div className="space-y-2">
            <Label className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                <Icon className="h-4 w-4" /> {label}
            </Label>
            <div className="flex items-center gap-2">
                <input
                    type="color"
                    className="w-12 h-10 p-1 cursor-pointer border rounded"
                    value={value || '#000000'}
                    onChange={e => onChange(id, e.target.value)}
                />
                <Input
                    value={value || ''}
                    onChange={e => onChange(id, e.target.value)}
                    className="uppercase font-mono flex-1"
                    maxLength={7}
                    placeholder="#000000"
                />
            </div>
        </div>
    );
});

ColorRow.displayName = 'ColorRow';

export default function AppearanceSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, saveConfig, isSaving } = context;

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
            quickActionsCardColor: values.quickActionsCardColor, // [NEW] Quick Actions Card Color
            quickActionsTextColor: values.quickActionsTextColor, // [NEW] Quick Actions Text Color
            otherCardsColor: values.otherCardsColor, // [NEW] Other Cards Color
            otherCardsTextColor: values.otherCardsTextColor, // [NEW] Other Cards Text Color
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
        setConfig((p: any) => {
            const updated = { ...p, [id]: val };
            // Also update the store for current layout
            return updateLayoutThemes(updated, p.layoutType || 'layout_06', updated);
        });
    }, [setConfig, updateLayoutThemes]);

    // Default color presets per layout
    const layoutDefaults: Record<string, Record<string, string>> = {
        layout_02: {
            themeColor: '#E91E63', // Vibe Magenta/Hot Pink
            secondaryColor: '#6A1B9A', // Vibe Deep Purple
            backgroundColor: '#1A0533', // Dark Purple Background
            cardColor: '#2D0A4E', // Dark Purple Cards
            textColor: '#FFFFFF', // White Text
            iconColor: '#FFD600', // Electric Yellow Icons (CTA color)
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
    };


    const handleLayoutChange = useCallback((newLayout: string) => {
        setConfig((prev: any) => {
            // Maxwell's Demon: Save current state before switching
            let nextConfig = updateLayoutThemes(prev, prev.layoutType || 'layout_01', prev);

            // Access the store to retrieve new layout colors
            const layoutThemes = nextConfig.strings?.layoutThemes ? JSON.parse(nextConfig.strings.layoutThemes) : {};
            const savedTheme = layoutThemes[newLayout];

            if (savedTheme) {
                // Restore saved colors, merging with defaults to ensure new fields (like new card colors) are populated
                const defaults = layoutDefaults[newLayout] || layoutDefaults['layout_01'];
                nextConfig = {
                    ...nextConfig,
                    ...defaults,
                    ...savedTheme,
                    layoutType: newLayout
                };
            } else {
                // No saved theme - use layout DEFAULTS instead of inheriting
                const defaults = layoutDefaults[newLayout] || layoutDefaults['layout_01'];
                nextConfig = {
                    ...nextConfig,
                    ...defaults,
                    layoutType: newLayout
                };
            }
            return nextConfig;
        });
    }, [setConfig, updateLayoutThemes]);

    return (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Configurações */}
            <div className="lg:col-span-2">
                <Card>
                    <CardHeader><CardTitle>Aparência</CardTitle></CardHeader>
                    <CardContent className="space-y-8">
                        {/* Seletor de Layout do App */}
                        <div className="space-y-3 p-4 border rounded-lg bg-muted/30">
                            <Label className="flex items-center gap-2 text-sm font-medium">
                                <Smartphone className="h-4 w-4" /> Layout do App
                            </Label>
                            <Select
                                value={config.layoutType || 'layout_01'}
                                onValueChange={handleLayoutChange}
                            >
                                <SelectTrigger className="w-full">
                                    <SelectValue placeholder="Escolha o layout" />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="layout_01">Layout 01 - Padrão Original</SelectItem>
                                    <SelectItem value="layout_02">Layout 02 - NetLink Premium</SelectItem>
                                    <SelectItem value="layout_03">Layout 03 - Vibe Modern</SelectItem>
                                    <SelectItem value="layout_04">Layout 04 - Clean Light</SelectItem>
                                    <SelectItem value="layout_05">Layout 05 - Cyber Neon</SelectItem>
                                    <SelectItem value="layout_06">Layout 06 - Clean Dark</SelectItem>
                                </SelectContent>
                            </Select>
                            <div className="flex justify-between items-center mt-2">
                                <p className="text-xs text-muted-foreground">Define a aparência visual do aplicativo do cliente</p>
                                <Button
                                    variant="ghost"
                                    size="sm"
                                    onClick={() => {
                                        if (confirm('Deseja restaurar as cores padrão deste layout? Isso substituirá suas configurações atuais.')) {
                                            const currentLayout = config.layoutType || 'layout_01';
                                            const defaults = layoutDefaults[currentLayout] || layoutDefaults['layout_01'];
                                            setConfig((prev: any) => updateLayoutThemes({ ...prev, ...defaults }, currentLayout, defaults));
                                            toast.success('Cores padrão restauradas!');
                                        }
                                    }}
                                    className="h-6 text-xs text-blue-500 hover:text-blue-700"
                                >
                                    Restaurar Cores Padrão
                                </Button>
                            </div>
                        </div>

                        {/* Seletor de Estilo de Diagnóstico */}
                        <div className="space-y-3 p-4 border rounded-lg bg-muted/30">
                            <Label className="flex items-center gap-2 text-sm font-medium">
                                <Zap className="h-4 w-4" /> Estilo do Diagnóstico
                            </Label>
                            <Select
                                value={config.diagnosticStyle || 'default'}
                                onValueChange={(val) => setConfig((p: any) => ({ ...p, diagnosticStyle: val }))}
                            >
                                <SelectTrigger className="w-full">
                                    <SelectValue placeholder="Escolha o estilo do diagnóstico" />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="default">Padrão (baseado no layout)</SelectItem>
                                    <SelectItem value="diagnostic_02">Cyberpunk Dark (gráficos em tempo real)</SelectItem>
                                    <SelectItem value="diagnostic_03">Elegant Dark (gauge animado)</SelectItem>
                                    <SelectItem value="diagnostic_05">Clean Light (neumorphic)</SelectItem>
                                    <SelectItem value="diagnostic_06">Minimal Light (timeline)</SelectItem>
                                    <SelectItem value="diagnostic_07">Zenith Premium (mesh particles)</SelectItem>
                                </SelectContent>
                            </Select>
                            <p className="text-xs text-muted-foreground">Define a aparência da página de diagnóstico de rede</p>
                        </div>

                        {/* Cores Principais */}
                        <div className="space-y-4">
                            <h3 className="text-sm font-semibold">Cores do Tema</h3>
                            <div className="grid gap-6 sm:grid-cols-2">
                                <ColorRow
                                    label="Cor Principal"
                                    id="themeColor"
                                    value={config.themeColor}
                                    icon={Palette}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Cor Secundária"
                                    id="secondaryColor"
                                    value={config.secondaryColor}
                                    icon={Palette}
                                    onChange={handleColorChange}
                                />
                            </div>
                        </div>

                        {/* Outras Cores */}
                        <div className="space-y-4">
                            <h3 className="text-sm font-semibold">Outras Cores</h3>
                            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                                <ColorRow
                                    label="Botões (Ação)"
                                    id="actionColor"
                                    value={config.actionColor}
                                    icon={Zap}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Cards (Surface)"
                                    id="cardColor"
                                    value={config.cardColor}
                                    icon={CreditCard}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Fundo (Page)"
                                    id="backgroundColor"
                                    value={config.backgroundColor}
                                    icon={Palette}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Fatura"
                                    id="invoiceColor"
                                    value={config.invoiceColor}
                                    icon={CreditCard}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Texto"
                                    id="textColor"
                                    value={config.textColor}
                                    icon={Type}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Ícones"
                                    id="iconColor"
                                    value={config.iconColor}
                                    icon={Zap}
                                    onChange={handleColorChange}
                                />
                            </div>
                        </div>

                        {/* Cores Específicas de Cards */}
                        <div className="space-y-4">
                            <h3 className="text-sm font-semibold">Cores Avançadas de Cards</h3>
                            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                                <ColorRow
                                    label="Fundo Ações Rápidas"
                                    id="quickActionsCardColor"
                                    value={config.quickActionsCardColor}
                                    icon={CreditCard}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Texto Ações Rápidas"
                                    id="quickActionsTextColor"
                                    value={config.quickActionsTextColor}
                                    icon={Type}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Fundo Outros Cards"
                                    id="otherCardsColor"
                                    value={config.otherCardsColor}
                                    icon={CreditCard}
                                    onChange={handleColorChange}
                                />
                                <ColorRow
                                    label="Texto Outros Cards"
                                    id="otherCardsTextColor"
                                    value={config.otherCardsTextColor}
                                    icon={Type}
                                    onChange={handleColorChange}
                                />
                            </div>
                        </div>

                        {/* Outras opções */}
                        <div className="p-4 border rounded flex justify-between items-center">
                            <Label>Cabeçalho com Imagem?</Label>
                            <Switch
                                checked={config.other?.useBackgroundImage || false}
                                onCheckedChange={(c) => setConfig((p: any) => ({
                                    ...p,
                                    other: { ...(p.other || {}), useBackgroundImage: c }
                                }))}
                            />
                        </div>

                        {/* Configurações de Serviços (Layout 06) */}
                        <div className="space-y-3 p-4 border rounded-lg bg-muted/30">
                            <Label className="text-sm font-medium">Serviços Exibidos (Layout 06)</Label>
                            <p className="text-xs text-muted-foreground mb-3">
                                Controle quais serviços aparecem na seção "Status dos Serviços"
                            </p>
                            <div className="flex justify-between items-center py-2">
                                <Label className="text-sm">Mostrar serviço de TV</Label>
                                <Switch
                                    checked={config.other?.showTvService ?? true}
                                    onCheckedChange={(c) => setConfig((p: any) => ({
                                        ...p,
                                        other: { ...(p.other || {}), showTvService: c }
                                    }))}
                                />
                            </div>
                            <div className="flex justify-between items-center py-2">
                                <Label className="text-sm">Mostrar serviço de Telefone</Label>
                                <Switch
                                    checked={config.other?.showPhoneService ?? true}
                                    onCheckedChange={(c) => setConfig((p: any) => ({
                                        ...p,
                                        other: { ...(p.other || {}), showPhoneService: c }
                                    }))}
                                />
                            </div>
                        </div>

                        {/* Nota: Logo URL está em Imagens & Ícones */}

                        {/* Botão Salvar */}
                        <div className="pt-4 border-t">
                            <Button
                                onClick={saveConfig}
                                disabled={isSaving}
                                className="w-full"
                            >
                                {isSaving ? (
                                    <><Loader2 className="animate-spin mr-2 h-4 w-4" />Salvando...</>
                                ) : (
                                    <><Save className="mr-2 h-4 w-4" />Salvar Alterações</>
                                )}
                            </Button>
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Preview do App */}
            <div className="lg:col-span-1">
                <MobilePreview />
            </div>
        </div>
    );
}
