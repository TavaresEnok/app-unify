import { useState, useEffect } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Save, Loader2, Link, Server, AlertTriangle } from 'lucide-react';
import { toast } from 'sonner';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

export default function IntegrationsSettings() {
    const { config, setConfig, isSaving } = useSettings();

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
        <SettingsPage
            title="Integrações"
            description="Configure as conexões usadas pelo aplicativo e pelo SGP."
            icon={Server}
            footer={(
                <>
                    <SettingsFooterNote>As integrações entram em vigor após aplicar e salvar as alterações gerais.</SettingsFooterNote>
                    <Button onClick={handleSaveIntegration} disabled={isSaving} className="gap-2">
                        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                        Aplicar configurações
                    </Button>
                </>
            )}
        >
            <SettingsSection
                title="URL do Servidor (API)"
                description="Configuração crítica: todos os apps usam esta URL."
                className="border-amber-200 bg-amber-50"
                actions={<AlertTriangle className="h-4 w-4 text-amber-600" />}
            >
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
            </SettingsSection>

            <SettingsSection title="Integração SGP" description="Configure o token e o nome do aplicativo para sincronizar dados do SGP.">

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

                    <div className="flex items-center border-t border-[#EEF0F4] pt-4 text-sm text-muted-foreground">
                        <Link className="h-4 w-4 mr-2" />
                        As integrações entrarão em vigor após salvar as alterações no painel.
                    </div>
            </SettingsSection>
        </SettingsPage>
    );
}
