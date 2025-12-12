import { useContext, useState, useEffect } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Save, Loader2 } from 'lucide-react';
import { toast } from 'sonner';

export default function OtherSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    // Estados locais para campos de texto (exemplo: URL de política de privacidade, etc.)
    const [localPrivacyPolicyUrl, setLocalPrivacyPolicyUrl] = useState(config.other?.privacyPolicyUrl || '');
    const [localCustomDomain, setLocalCustomDomain] = useState(config.other?.customDomain || '');

    useEffect(() => {
        setLocalPrivacyPolicyUrl(config.other?.privacyPolicyUrl || '');
        setLocalCustomDomain(config.other?.customDomain || '');
    }, [config]);

    // Função para salvar localmente e atualizar o contexto
    const handleSaveOtherSettings = () => {
        const newOtherSettings = {
            privacyPolicyUrl: localPrivacyPolicyUrl.trim(),
            customDomain: localCustomDomain.trim(),
        };

        // Atualiza o contexto, aninhando a nova configuração de outras opções
        // CORRIGIDO: Tipagem do prevConfig para resolver TS7006
        setConfig((prevConfig: ProviderConfig) => ({
            ...prevConfig,
            other: newOtherSettings,
        }));
        
        toast.info("Outras configurações salvas localmente. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };

    return (
        <Card>
            <CardHeader>
                <CardTitle>Outras Configurações</CardTitle>
                <CardDescription>
                    Opções diversas e links não cobertos nas outras seções.
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                
                <div className="space-y-2">
                    <Label htmlFor="privacyUrl">URL da Política de Privacidade</Label>
                    <Input
                        id="privacyUrl"
                        placeholder="https://seuprovedor.com/privacidade"
                        value={localPrivacyPolicyUrl}
                        onChange={(e) => setLocalPrivacyPolicyUrl(e.target.value)}
                        disabled={isSaving}
                    />
                    <p className="text-sm text-muted-foreground">Link externo para a política de privacidade da sua empresa.</p>
                </div>

                <div className="space-y-2">
                    <Label htmlFor="customDomain">Domínio Personalizado (opcional)</Label>
                    <Input
                        id="customDomain"
                        placeholder="Ex: app.seuprovedor.com"
                        value={localCustomDomain}
                        onChange={(e) => setLocalCustomDomain(e.target.value)}
                        disabled={isSaving}
                    />
                    <p className="text-sm text-muted-foreground">Pode ser usado para personalizar links internos, se aplicável.</p>
                </div>

                <Button onClick={handleSaveOtherSettings} disabled={isSaving}>
                    {isSaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
                    Aplicar Outras Configurações
                </Button>
                
            </CardContent>
        </Card>
    );
}
