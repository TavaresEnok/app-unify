import { useContext, useState, useEffect } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { PlusCircle, Trash2, Upload, Loader2, Image, Link } from 'lucide-react';
import { toast } from 'sonner';

export default function CarouselSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

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
        <Card>
            <CardHeader>
                <CardTitle>Carrossel de Imagens</CardTitle>
                <CardDescription>
                    Gerencie a lista de imagens que aparecerão no carrossel da tela inicial do aplicativo.
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                
                {/* Adicionar Nova Imagem */}
                <div className="flex gap-2">
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

                {/* Lista de Imagens Atuais */}
                {localImages.length > 0 && (
                    <div className="space-y-4 pt-4 border-t">
                        <Label className="text-base font-semibold flex items-center gap-2">
                            <Image className="h-5 w-5" /> Imagens Atuais ({localImages.length})
                        </Label>
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                            {/* CORRIGIDO: Tipagem do image e index para resolver TS7006 */}
                            {localImages.map((image: string, index: number) => (
                                <div key={index} className="relative group overflow-hidden rounded-lg border bg-muted">
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
                    </div>
                )}
                
                {localImages.length === 0 && (
                    <p className="text-sm text-muted-foreground pt-4">Nenhuma imagem configurada ainda.</p>
                )}
                
                <Button disabled={isSaving} className="mt-4">
                    {isSaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : "Aplicar Carrossel (Salvar Localmente)"}
                </Button>
            </CardContent>
        </Card>
    );
}
