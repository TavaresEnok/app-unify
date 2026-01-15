import { useCallback } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Save, Loader2, Check, Circle, Square, Hexagon, Diamond } from 'lucide-react';
import { toast } from 'sonner';

// Icon pack options
const ICON_PACKS = [
    {
        id: 'material',
        name: 'Material Design',
        description: 'Ícones padrão do Material Design',
        style: 'Preenchido',
    },
    {
        id: 'outlined',
        name: 'Outlined',
        description: 'Ícones com borda, sem preenchimento',
        style: 'Contorno',
    },
    {
        id: 'rounded',
        name: 'Rounded',
        description: 'Ícones com cantos suaves e arredondados',
        style: 'Arredondado',
    },
    {
        id: 'phosphor',
        name: 'Phosphor',
        description: 'Pack de ícones moderno e elegante',
        style: 'Moderno',
    },
];

export default function IconPackSettings() {
    const { config, setConfig, saveConfig, isSaving } = useSettings();

    const currentPack = config.iconPack || 'material';

    const handlePackChange = useCallback((pack: string) => {
        setConfig((prev: any) => ({
            ...prev,
            iconPack: pack,
        }));
    }, [setConfig]);

    const handleSave = async () => {
        await saveConfig();
        toast.success('Pack de ícones salvo!');
    };

    const renderPreviewIcons = (packId: string) => {
        const baseClass = "h-6 w-6 text-primary";
        switch (packId) {
            case 'material':
                return (
                    <>
                        <Circle className={`${baseClass} fill-current`} />
                        <Square className={`${baseClass} fill-current`} />
                        <Hexagon className={`${baseClass} fill-current`} />
                        <Diamond className={`${baseClass} fill-current`} />
                    </>
                );
            case 'outlined':
                return (
                    <>
                        <Circle className={baseClass} />
                        <Square className={baseClass} />
                        <Hexagon className={baseClass} />
                        <Diamond className={baseClass} />
                    </>
                );
            case 'rounded':
                return (
                    <>
                        <Circle className={`${baseClass} stroke-[3]`} />
                        <Square className={`${baseClass} stroke-[3]`} />
                        <Hexagon className={`${baseClass} stroke-[3]`} />
                        <Diamond className={`${baseClass} stroke-[3]`} />
                    </>
                );
            case 'phosphor':
                return (
                    <>
                        <Circle className={`${baseClass} fill-current stroke-[1.5]`} />
                        <Square className={`${baseClass} fill-current stroke-[1.5]`} />
                        <Hexagon className={`${baseClass} fill-current stroke-[1.5]`} />
                        <Diamond className={`${baseClass} fill-current stroke-[1.5]`} />
                    </>
                );
            default:
                return null;
        }
    };

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-3xl font-bold flex items-center gap-2">
                        <Hexagon className="h-8 w-8" />
                        Pack de Ícones
                    </h2>
                    <p className="text-muted-foreground">Escolha o estilo dos ícones do aplicativo</p>
                </div>
                <Button onClick={handleSave} disabled={isSaving}>
                    {isSaving ? (
                        <><Loader2 className="animate-spin mr-2 h-4 w-4" />Salvando...</>
                    ) : (
                        <><Save className="mr-2 h-4 w-4" />Salvar</>
                    )}
                </Button>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Estilo de Ícones</CardTitle>
                    <CardDescription>
                        O pack selecionado será usado em todo o aplicativo.
                    </CardDescription>
                </CardHeader>
                <CardContent className="grid gap-4">
                    {ICON_PACKS.map((pack) => (
                        <div
                            key={pack.id}
                            onClick={() => handlePackChange(pack.id)}
                            className={`flex items-center gap-4 p-4 rounded-lg border-2 cursor-pointer transition-all
                                ${currentPack === pack.id
                                    ? 'border-primary bg-primary/5'
                                    : 'border-muted hover:bg-muted/50'}`}
                        >
                            {/* Preview icons grid */}
                            <div className="grid grid-cols-2 gap-1 p-3 rounded-lg bg-muted/50 min-w-[70px]">
                                {renderPreviewIcons(pack.id)}
                            </div>

                            <div className="flex-1">
                                <div className="flex items-center gap-2">
                                    <span className="font-semibold">{pack.name}</span>
                                    <span className="text-xs px-2 py-0.5 rounded-full bg-muted text-muted-foreground">
                                        {pack.style}
                                    </span>
                                </div>
                                <p className="text-sm text-muted-foreground mt-1">
                                    {pack.description}
                                </p>
                            </div>

                            {currentPack === pack.id && (
                                <Check className="h-5 w-5 text-primary" />
                            )}
                        </div>
                    ))}
                </CardContent>
            </Card>

            {/* Nota informativa */}
            <div className="p-4 bg-amber-500/10 border border-amber-500/20 rounded-lg">
                <p className="text-sm text-amber-600 dark:text-amber-400">
                    <strong>Nota:</strong> A mudança do pack de ícones requer rebuild do aplicativo
                    para ser aplicada. As alterações são salvas imediatamente na configuração.
                </p>
            </div>
        </div>
    );
}
