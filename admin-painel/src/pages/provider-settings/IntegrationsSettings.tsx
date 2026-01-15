import { useContext, useState, useEffect } from 'react';
import { SettingsContext } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Save, Loader2, Link, Server, AlertTriangle } from 'lucide-react';
import { toast } from 'sonner';

export default function IntegrationsSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    // API URL (CRITICAL - used by all apps!)
    const [localApiUrl, setLocalApiUrl] = useState(config.apiUrl || '');
    // SGP Integration
    const [localApiToken, setLocalApiToken] = useState(config.integrations?.apiToken || '');
    const [localAppName, setLocalAppName] = useState(config.integrations?.appName || '');

    useEffect(() => {
        setLocalApiUrl(config.apiUrl || '');
        setLocalApiToken(config.integrations?.apiToken || '');
        setLocalAppName(config.integrations?.appName || '');
    }, [config]);

    const handleSaveIntegration = () => {
        const newIntegrations = {
            apiToken: localApiToken.trim(),
            appName: localAppName.trim(),
        };

        setConfig((prev: any) => ({
            ...prev,
            apiUrl: localApiUrl.trim(),
            integrations: newIntegrations,
        }));

        toast.info("Configurações atualizadas. Clique em 'Salvar Alterações' para confirmar.");
    };

    return (
        <div className="space-y-6">
            {/* CRITICAL: API URL Card */}
            <Card className="border-amber-500/50 bg-amber-500/5">
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Server className="h-5 w-5" />
                        URL do Servidor (API)
                    </CardTitle>
                    <CardDescription>
                        <span className="flex items-center gap-2 text-amber-600 dark:text-amber-400">
                            <AlertTriangle className="h-4 w-4" />
                            Configuração crítica - todos os apps usam esta URL
                        </span>
                    </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                    <div className="space-y-2">
                        <Label htmlFor="apiUrl">URL da API do Servidor</Label>
                        <Input
                            id="apiUrl"
                            placeholder="http://seu-servidor:3000"
                            value={localApiUrl}
                            onChange={(e) => setLocalApiUrl(e.target.value)}
                            disabled={isSaving}
                            className="font-mono"
                        />
                        <p className="text-sm text-muted-foreground">
                            Se você mudar de servidor/IP, atualize aqui e todos os apps receberão
                            automaticamente a nova URL sem precisar de atualização.
                        </p>
                    </div>
                </CardContent>
            </Card>

            {/* SGP Integration Card */}
            <Card>
                <CardHeader>
                    <CardTitle>Integrações SGP</CardTitle>
                    <CardDescription>
                        Configure o token e o nome do aplicativo para sincronizar dados do SGP.
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
        </div>
    );
}

