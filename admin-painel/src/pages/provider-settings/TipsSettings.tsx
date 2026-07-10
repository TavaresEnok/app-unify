import { useContext, useState, useEffect, useCallback } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Loader2, Lightbulb, PlusCircle, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

// CORREÇÃO: Interface compatível com o Dialog e o App Flutter
export interface TipItem {
    id: string;
    title: string;
    description: string;
}

export default function TipsSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    // Converte o array de tips para um estado local
    const [localTips, setLocalTips] = useState<TipItem[]>(() => {
        // O backend pode retornar strings simples (legado) ou objetos
        return (config.tips || []).map((item: any, index: number) => {
            if (typeof item === 'string') {
                return {
                    id: `tip-${index}-${Math.random()}`,
                    title: 'Dica',
                    description: item
                };
            }
            return {
                id: `tip-${index}-${Math.random()}`,
                title: item.title || 'Dica',
                description: item.description || ''
            };
        });
    });

    // Estados para nova dica
    const [newTitle, setNewTitle] = useState('');
    const [newDescription, setNewDescription] = useState('');

    useEffect(() => {
        setLocalTips((config.tips || []).map((item: any, index: number) => {
             if (typeof item === 'string') {
                return {
                    id: `tip-${index}-${Math.random()}`,
                    title: 'Dica',
                    description: item
                };
            }
            return {
                id: `tip-${index}-${Math.random()}`,
                title: item.title || 'Dica',
                description: item.description || ''
            };
        }));
    }, [config.tips]);

    const updateAndSave = (updatedTips: TipItem[]) => {
        setLocalTips(updatedTips);
        
        // Salva no formato de objeto para o App ler corretamente
        const contentArray = updatedTips.map(t => ({
            title: t.title,
            description: t.description
        }));
        
        setConfig((prev: ProviderConfig) => ({ ...prev, tips: contentArray }));
    };

    const handleAddTip = () => {
        if (!newDescription.trim()) {
            toast.error("A descrição da dica não pode estar vazia.");
            return;
        }

        const newTip: TipItem = { 
            id: `tip-${Date.now()}`, 
            title: newTitle.trim() || 'Dica Útil', 
            description: newDescription.trim() 
        };
        
        const updatedTips = [...localTips, newTip];

        updateAndSave(updatedTips);
        setNewTitle('');
        setNewDescription('');
        toast.success("Dica adicionada. Clique em 'Salvar Alterações' para confirmar.");
    };

    const handleRemoveTip = (id: string) => {
        const updatedTips = localTips.filter(tip => tip.id !== id);
        updateAndSave(updatedTips);
        toast.warning("Dica removida.");
    };
    
    const handleApplyChanges = useCallback(() => {
        toast.success("Alterações aplicadas localmente. Não esqueça de Salvar.");
    }, []);

    return (
        <SettingsPage
            title="Dicas Úteis"
            description="Gerencie as dicas exibidas no aplicativo."
            icon={Lightbulb}
            footer={(
                <>
                    <SettingsFooterNote>As alterações são aplicadas localmente e devem ser salvas nas configurações gerais.</SettingsFooterNote>
                    <Button onClick={handleApplyChanges} disabled={isSaving} className="gap-2">
                        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
                        Confirmar alterações
                    </Button>
                </>
            )}
        >
            <SettingsSection title="Adicionar nova dica" description="Crie uma dica curta para orientar o assinante no app.">
                {/* Adicionar Nova Dica */}
                <div className="grid gap-4">
                    <div className="grid gap-2">
                        <Label>Título</Label>
                        <Input
                            placeholder="Ex: Reinicie seus equipamentos"
                            value={newTitle}
                            onChange={(e) => setNewTitle(e.target.value)}
                            disabled={isSaving}
                        />
                    </div>
                    <div className="grid gap-2">
                        <Label>Descrição</Label>
                        <Input
                            placeholder="Ex: Desligue o modem por 10 segundos..."
                            value={newDescription}
                            onChange={(e) => setNewDescription(e.target.value)}
                            disabled={isSaving}
                        />
                    </div>
                    <Button onClick={handleAddTip} disabled={isSaving || !newDescription.trim()}>
                        <PlusCircle className="h-4 w-4 mr-2" /> Adicionar Dica
                    </Button>
                </div>
            </SettingsSection>

            <SettingsSection title={`Dicas atuais (${localTips.length})`} description="Itens exibidos no carrossel de dicas do aplicativo.">
                {/* Lista de Dicas */}
                {localTips.length > 0 ? (
                    <div className="space-y-3">
                        {localTips.map((tip) => (
                            <div key={tip.id} className="flex items-start gap-3 rounded-lg border border-[#EEF0F4] bg-white p-3">
                                <Lightbulb className="h-5 w-5 mt-1 text-yellow-500 flex-shrink-0" />
                                <div className="flex-1">
                                    <p className="font-medium text-sm">{tip.title}</p>
                                    <p className="text-sm text-muted-foreground">{tip.description}</p>
                                </div>
                                <Button 
                                    variant="destructive" 
                                    size="icon" 
                                    onClick={() => handleRemoveTip(tip.id)} 
                                    disabled={isSaving}
                                    className="h-7 w-7"
                                >
                                    <Trash2 className="h-4 w-4" />
                                </Button>
                            </div>
                        ))}
                    </div>
                ) : (
                    <p className="rounded-lg border border-dashed border-[#C6CDD9] bg-white p-6 text-center text-sm text-muted-foreground">Nenhuma dica configurada.</p>
                )}
            </SettingsSection>
        </SettingsPage>
    );
}
