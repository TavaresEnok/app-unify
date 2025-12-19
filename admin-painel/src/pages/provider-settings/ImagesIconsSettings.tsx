import { useContext, useState, useEffect } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Upload, ImageIcon, Monitor, Loader2, Save } from 'lucide-react';
import { toast } from 'sonner';

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
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

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
        <Card>
            <CardHeader>
                <CardTitle>Imagens e Ícones</CardTitle>
                <CardDescription>
                    Configure as URLs para imagens de fundo, ícones e outros elementos visuais do aplicativo.
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-8">
                {imageFields.map((field) => (
                    <div key={field.key} className="space-y-4 pt-4 border-t first:border-t-0">
                        <Label htmlFor={field.key} className="text-base font-semibold flex items-center gap-2">
                            {field.key === 'backgroundUrl' ? <Monitor className="h-5 w-5" /> : <ImageIcon className="h-5 w-5" />}
                            {field.label}
                        </Label>

                        <div className="flex gap-2">
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
                            <div className="mt-4 p-4 border rounded-md bg-muted/50">
                                <p className="text-sm font-medium mb-2">Pré-visualização:</p>
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
            </CardContent>
        </Card>
    );
}
