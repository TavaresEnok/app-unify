import { useState, useEffect } from 'react';
import { useSettings, ProviderConfig } from '@/contexts/SettingsContext';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { PlusCircle, Trash2, Image, Link } from 'lucide-react';
import { toast } from 'sonner';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

export default function CarouselSettings() {
    const { config, setConfig, isSaving } = useSettings();

    // Estado local para a lista de URLs de imagens do carrossel
    const [localImages, setLocalImages] = useState<string[]>(config.imageCarousel || []);
    const [newImageUrl, setNewImageUrl] = useState('');

    useEffect(() => {
        setLocalImages(config.imageCarousel || []);
    }, [config.imageCarousel]);

    // Função interna para atualizar o contexto e o estado local
    const updateAndSave = (updatedImages: string[]) => {
        setLocalImages(updatedImages);
        
        // Atualiza o contexto, aninhando a nova configuração de carrossel
        // CORRIGIDO: Tipagem do prev para resolver TS7006
        setConfig((prev: ProviderConfig) => ({ ...prev, imageCarousel: updatedImages }));
    };

    const handleAddImage = () => {
        const url = newImageUrl.trim();
        if (!url || !url.startsWith('http')) {
            toast.error("Por favor, insira uma URL de imagem válida (deve começar com http/https).");
            return;
        }

        const updatedImages = [...localImages, url];
        updateAndSave(updatedImages);
        setNewImageUrl('');
        toast.success("Imagem adicionada. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };

    // CORRIGIDO: Tipagem do index e _ para resolver TS7006 nas funções internas
    const handleRemoveImage = (indexToRemove: number) => {
        const updatedImages = localImages.filter((_, index) => index !== indexToRemove);
        updateAndSave(updatedImages);
        toast.warning("Imagem removida. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };

    return (
        <SettingsPage
            title="Carrossel de Imagens"
            description="Gerencie a lista de imagens que aparecem no carrossel da tela inicial."
            icon={Image}
            footer={<SettingsFooterNote>Adicionar ou remover imagens já atualiza a configuração local. Salve as alterações gerais para persistir.</SettingsFooterNote>}
        >
            <SettingsSection title="Adicionar imagem" description="Use uma URL pública iniciada por http ou https.">
                {/* Adicionar Nova Imagem */}
                <div className="flex flex-col gap-2 sm:flex-row">
                    <Input
                        placeholder="Insira a URL da imagem (Ex: https://meusite.com/promo.jpg)"
                        value={newImageUrl}
                        onChange={(e) => setNewImageUrl(e.target.value)}
                        disabled={isSaving}
                    />
                    <Button onClick={handleAddImage} disabled={isSaving || !newImageUrl.trim()}>
                        <PlusCircle className="h-4 w-4 mr-2" /> Adicionar
                    </Button>
                </div>
            </SettingsSection>

            <SettingsSection title={`Imagens atuais (${localImages.length})`} description="Banners configurados para o app.">
                {/* Lista de Imagens Atuais */}
                {localImages.length > 0 ? (
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                            {/* CORRIGIDO: Tipagem do image e index para resolver TS7006 */}
                            {localImages.map((image: string, index: number) => (
                                <div key={index} className="group relative overflow-hidden rounded-lg border border-[#EEF0F4] bg-white">
                                    <img 
                                        src={image} 
                                        alt={`Carrossel Imagem ${index + 1}`} 
                                        className="w-full h-32 object-cover transition-transform duration-300 group-hover:scale-105"
                                    />
                                    <div className="absolute inset-0 bg-black/50 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                                        <Button 
                                            variant="destructive" 
                                            size="icon" 
                                            onClick={() => handleRemoveImage(index)} 
                                            disabled={isSaving}
                                            className="h-8 w-8"
                                        >
                                            <Trash2 className="h-4 w-4" />
                                        </Button>
                                    </div>
                                    <a href={image} target="_blank" rel="noopener noreferrer" className="absolute top-2 right-2 text-white/80 hover:text-white">
                                        <Link className="h-4 w-4" />
                                    </a>
                                </div>
                            ))}
                        </div>
                ) : (
                    <p className="rounded-lg border border-dashed border-[#C6CDD9] bg-white p-6 text-center text-sm text-muted-foreground">Nenhuma imagem configurada ainda.</p>
                )}
            </SettingsSection>
        </SettingsPage>
    );
}
