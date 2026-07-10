import { useState, useEffect } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Upload, ImageIcon, Monitor } from 'lucide-react';
import { toast } from 'sonner';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

interface ImageConfig {
    key: string;
    label: string;
    placeholder: string;
    previewSize: string;
}

const imageFields: ImageConfig[] = [
    { key: 'backgroundUrl', label: 'Imagem de Fundo (Login)', placeholder: 'URL da imagem de fundo...', previewSize: 'h-24 w-auto' },
    { key: 'logoUrl', label: 'Logo do Provedor', placeholder: 'URL da logo (PNG/SVG)...', previewSize: 'h-24 w-auto' },
    { key: 'iconUrl', label: 'Ícone da Aplicação', placeholder: 'URL do ícone...', previewSize: 'h-12 w-12' },
];

export default function ImagesIconsSettings() {
    const { config, setConfig, isSaving } = useSettings();

    // Estado local para gerenciar as URLs
    const [localUrls, setLocalUrls] = useState<Record<string, string>>(() => {
        const initial: Record<string, string> = {};
        imageFields.forEach(field => {
            initial[field.key] = config[field.key] || '';
        });
        return initial;
    });

    useEffect(() => {
        // Sincroniza o estado local com o estado global ao carregar a página
        const updatedUrls: Record<string, string> = {};
        imageFields.forEach(field => {
            updatedUrls[field.key] = config[field.key] || '';
        });
        setLocalUrls(updatedUrls);
    }, [config]);

    // Função para atualizar o estado local
    const handleLocalUpdate = (key: string, value: string) => {
        setLocalUrls(prev => ({ ...prev, [key]: value }));
    };

    // Função para salvar no contexto
    const handleSaveImage = (key: string) => {
        const url = localUrls[key]?.trim();
        if (!url || !url.startsWith('http')) {
            toast.error(`Por favor, insira uma URL válida para ${imageFields.find(f => f.key === key)?.label}.`);
            return;
        }

        // Atualiza o contexto global
        // CORRIGIDO: Tipagem do prev para resolver TS7006
        setConfig((prev: any) => ({ ...prev, [key]: url }));
        toast.success(`${imageFields.find(f => f.key === key)?.label} atualizada. Clique em 'Salvar Alterações' no topo.`);
    };

    return (
        <SettingsPage
            title="Imagens e Ícones"
            description="Configure URLs para imagens de fundo, logos e ícones usados no aplicativo."
            icon={ImageIcon}
        >
            <SettingsSection title="Ativos visuais" description="Cole URLs públicas e aplique cada ativo antes de salvar as alterações gerais.">
                {imageFields.map((field) => (
                    <div key={field.key} className="mb-4 rounded-lg border border-[#EEF0F4] bg-white p-3 last:mb-0">
                        <Label htmlFor={field.key} className="mb-3 flex items-center gap-2 text-[12.5px] font-semibold text-[#39414F]">
                            {field.key === 'backgroundUrl' ? <Monitor className="h-4 w-4 text-[#98A1B1]" /> : <ImageIcon className="h-4 w-4 text-[#98A1B1]" />}
                            {field.label}
                        </Label>

                        <div className="flex flex-col gap-2 sm:flex-row">
                            <Input
                                id={field.key}
                                placeholder={field.placeholder}
                                value={localUrls[field.key] || ''}
                                onChange={(e) => handleLocalUpdate(field.key, e.target.value)}
                                disabled={isSaving}
                            />
                            <Button onClick={() => handleSaveImage(field.key)} disabled={isSaving || !localUrls[field.key]?.trim()}>
                                <Upload className="h-4 w-4 mr-2" /> Aplicar
                            </Button>
                        </div>

                        {/* Pré-visualização */}
                        {localUrls[field.key] && (
                            <div className="mt-4 rounded-lg border border-[#EEF0F4] bg-[#FAFBFC] p-4">
                                <p className="mb-2 text-[12px] font-semibold text-[#687181]">Pré-visualização</p>
                                <img
                                    src={localUrls[field.key]}
                                    alt={`${field.label} Preview`}
                                    className={`${field.previewSize} object-contain`}
                                    onError={(e) => (e.currentTarget.style.display = 'none')}
                                />
                            </div>
                        )}
                    </div>
                ))}
            </SettingsSection>
        </SettingsPage>
    );
}
