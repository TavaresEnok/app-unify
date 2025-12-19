import { useContext, useCallback, memo } from 'react';
import { SettingsContext } from '@/contexts/SettingsContext';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Palette, Type, CreditCard, Zap, Smartphone } from 'lucide-react';
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

    const { config, setConfig } = context;

    // Persist colors per layout using config.strings.layoutThemes
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
            iconColor: values.iconColor, // [NEW] Icon Color
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
            themeColor: '#6B46C1',
            secondaryColor: '#9F7AEA',
            backgroundColor: '#1A202C',
            cardColor: '#2D3748',
            textColor: '#FFFFFF',
            iconColor: '#9F7AEA',
        },
        layout_03: {
            themeColor: '#3182CE',
            secondaryColor: '#63B3ED',
            backgroundColor: '#F7FAFC',
            cardColor: '#FFFFFF',
            textColor: '#1A202C',
            iconColor: '#3182CE',
        },
        layout_05: {
            themeColor: '#00D4FF',
            secondaryColor: '#FF00FF',
            backgroundColor: '#0A0A0F',
            cardColor: '#1A1A2E',
            textColor: '#FFFFFF',
            iconColor: '#00D4FF',
        },
        layout_06: {
            themeColor: '#0891B2',
            secondaryColor: '#059669',
            backgroundColor: '#F5F7FA',
            cardColor: '#FFFFFF',
            textColor: '#1F2937',
            iconColor: '#0891B2',
        },
        layout_07: {
            themeColor: '#4F46E5',
            secondaryColor: '#7C3AED',
            backgroundColor: '#FAFAFA',
            cardColor: '#FFFFFF',
            textColor: '#171717',
            iconColor: '#4F46E5',
        },
        layout_08: {
            themeColor: '#22D3EE',
            secondaryColor: '#A78BFA',
            backgroundColor: '#0F172A',
            cardColor: '#1E293B',
            textColor: '#F1F5F9',
            iconColor: '#22D3EE',
        },
        layout_09: {
            themeColor: '#EC4899',
            secondaryColor: '#8B5CF6',
            backgroundColor: '#0C0C1E',
            cardColor: '#16162A',
            textColor: '#FAFAFA',
            iconColor: '#EC4899',
        },
        layout_10: {
            themeColor: '#8B5CF6',
            secondaryColor: '#06B6D4',
            backgroundColor: '#0D0D1A',
            cardColor: '#1A1A2E',
            textColor: '#FFFFFF',
            iconColor: '#8B5CF6',
        },
    };

    const handleLayoutChange = useCallback((newLayout: string) => {
        setConfig((prev: any) => {
            // Maxwell's Demon: Save current state before switching
            let nextConfig = updateLayoutThemes(prev, prev.layoutType || 'layout_06', prev);

            // Access the store to retrieve new layout colors
            const layoutThemes = nextConfig.strings?.layoutThemes ? JSON.parse(nextConfig.strings.layoutThemes) : {};
            const savedTheme = layoutThemes[newLayout];

            if (savedTheme) {
                // Restore saved colors
                nextConfig = {
                    ...nextConfig,
                    ...savedTheme,
                    layoutType: newLayout
                };
            } else {
                // No saved theme - use layout DEFAULTS instead of inheriting
                const defaults = layoutDefaults[newLayout] || layoutDefaults['layout_06'];
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
                                value={config.layoutType || 'layout_06'}
                                onValueChange={handleLayoutChange}
                            >
                                <SelectTrigger className="w-full">
                                    <SelectValue placeholder="Escolha o layout" />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="layout_02">Layout 02 - Clássico (Gradiente Roxo)</SelectItem>
                                    <SelectItem value="layout_03">Layout 03 - Minimalista</SelectItem>
                                    <SelectItem value="layout_05">Layout 05 - Neo Digital</SelectItem>
                                    <SelectItem value="layout_06">Layout 06 - Premium Dark</SelectItem>
                                    <SelectItem value="layout_07">Layout 07 - Clean Light</SelectItem>
                                    <SelectItem value="layout_08">Layout 08 - Warm Premium</SelectItem>
                                    <SelectItem value="layout_09">Layout 09 - Bento Glass</SelectItem>
                                    <SelectItem value="layout_10">Layout 10 - Deep Purple</SelectItem>
                                </SelectContent>
                            </Select>
                            <p className="text-xs text-muted-foreground">Define a aparência visual do aplicativo do cliente</p>
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

                        <div className="flex gap-2">
                            <Input
                                value={config.logoUrl || ''}
                                onChange={e => setConfig((p: any) => ({ ...p, logoUrl: e.target.value }))}
                                placeholder="Logo URL"
                            />
                            <Button variant="secondary" onClick={() => toast.success('URL OK')}>Definir</Button>
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
