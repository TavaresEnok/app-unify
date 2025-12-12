import { useContext, useState, useEffect } from 'react';
import { SettingsContext } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Save, Loader2, Link } from 'lucide-react';
import { toast } from 'sonner';
// Import de { ProviderConfig } removido - TS6133

export default function IntegrationsSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    // Acessa as configurações aninhadas no contexto
    const [localApiToken, setLocalApiToken] = useState(config.integrations?.apiToken || '');
    const [localAppName, setLocalAppName] = useState(config.integrations?.appName || '');

    useEffect(() => {
        setLocalApiToken(config.integrations?.apiToken || '');
        setLocalAppName(config.integrations?.appName || '');
    }, [config]);

    const handleSaveIntegration = () => {
        const newIntegrations = {
            apiToken: localApiToken.trim(),
            appName: localAppName.trim(),
        };

        // Atualiza o contexto, aninhando a nova configuração de integrações
        // Isso será persistido no Firestore sob config.integrations quando o botão "Salvar Alterações" no ProviderDetailPage for pressionado.
        setConfig((prev: any) => ({
            ...prev,
            integrations: newIntegrations,
        }));
        
        toast.info("Configurações atualizadas localmente. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };

    return (
        <Card>
            <CardHeader>
                <CardTitle>Integrações SGP</CardTitle>
                <CardDescription>
                    Configure o token e o nome do aplicativo necessários para sincronizar clientes e acessar dados do SGP.
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                
                <div className="space-y-2">
                    <Label htmlFor="apiToken">Token da API do SGP</Label>
                    <Input
                        id="apiToken"
                        placeholder="Insira o seu token de API do SGP"
                        value={localApiToken}
                        onChange={(e) => setLocalApiToken(e.target.value)}
                        disabled={isSaving}
                    />
                    <p className="text-sm text-muted-foreground">Chave secreta fornecida pelo seu sistema SGP.</p>
                </div>

                <div className="space-y-2">
                    <Label htmlFor="appName">Nome do Aplicativo (App Name)</Label>
                    <Input
                        id="appName"
                        placeholder="Ex: VIBE_TELECOM"
                        value={localAppName}
                        onChange={(e) => setLocalAppName(e.target.value)}
                        disabled={isSaving}
                    />
                    <p className="text-sm text-muted-foreground">Nome da sua aplicação cadastrada no SGP.</p>
                </div>

                <Button onClick={handleSaveIntegration} disabled={isSaving}>
                    {isSaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
                    Aplicar Configurações
                </Button>
                
                <div className="flex items-center text-sm text-muted-foreground pt-4 border-t">
                    <Link className="h-4 w-4 mr-2" />
                    As integrações entrarão em vigor após salvar as alterações no painel.
                </div>
            </CardContent>
        </Card>
    );
}
