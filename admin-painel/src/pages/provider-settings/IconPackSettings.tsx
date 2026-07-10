import { useCallback } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Save, Loader2, Check, Circle, Square, Hexagon, Diamond } from 'lucide-react';
import { toast } from 'sonner';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

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
        <SettingsPage
            title="Pack de Ícones"
            description="Escolha o estilo dos ícones do aplicativo."
            icon={Hexagon}
            footer={(
                <>
                    <SettingsFooterNote>A mudança do pack de ícones requer rebuild para ser aplicada no app.</SettingsFooterNote>
                    <Button onClick={handleSave} disabled={isSaving} className="gap-2">
                        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                        {isSaving ? "Salvando..." : "Salvar alterações"}
                    </Button>
                </>
            )}
        >
            <SettingsSection title="Estilo de ícones" description="O pack selecionado será usado em todo o aplicativo.">
                <div className="grid gap-3">
                    {ICON_PACKS.map((pack) => (
                        <div
                            key={pack.id}
                            onClick={() => handlePackChange(pack.id)}
                            className={`flex cursor-pointer items-center gap-4 rounded-lg border p-4 transition-all
                                ${currentPack === pack.id
                                    ? 'border-primary bg-primary/5'
                                    : 'border-[#EEF0F4] bg-white hover:bg-[#F8FAFC]'}`}
                        >
                            {/* Preview icons grid */}
                            <div className="grid min-w-[70px] grid-cols-2 gap-1 rounded-lg bg-[#F2F4F7] p-3">
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
                </div>
            </SettingsSection>
        </SettingsPage>
    );
}
