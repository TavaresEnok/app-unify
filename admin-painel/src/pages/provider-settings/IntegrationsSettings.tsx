import { useState, useEffect } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Save, Loader2, Link, Server, Eye, EyeOff } from 'lucide-react';
import { toast } from 'sonner';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

export default function IntegrationsSettings() {
    const { config, setConfig, isSaving } = useSettings();

    // SGP Integration
    const [localApiToken, setLocalApiToken] = useState(config.integrations?.apiToken || '');
    const [localAppName, setLocalAppName] = useState(config.integrations?.appName || '');
    const [showToken, setShowToken] = useState(false);

    useEffect(() => {
        setLocalApiToken(config.integrations?.apiToken || '');
        setLocalAppName(config.integrations?.appName || '');
    }, [config]);

    const handleSaveIntegration = () => {
        const newIntegrations = {
            apiToken: localApiToken.trim(),
            appName: localAppName.trim(),
        };

        setConfig((prev) => ({
            ...prev,
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
            <SettingsSection title="Integração SGP" description="Configure o token e o nome do aplicativo para sincronizar dados do SGP.">

                    <div className="space-y-2">
                        <Label htmlFor="apiToken">Token da API do SGP</Label>
                        <div className="relative">
                            <Input
                                id="apiToken"
                                type={showToken ? 'text' : 'password'}
                                autoComplete="off"
                                spellCheck={false}
                                placeholder="Insira o seu token de API do SGP"
                                value={localApiToken}
                                onChange={(e) => setLocalApiToken(e.target.value)}
                                disabled={isSaving}
                                className="pr-10"
                            />
                            <button
                                type="button"
                                onClick={() => setShowToken((v) => !v)}
                                className="absolute inset-y-0 right-2 flex items-center text-muted-foreground hover:text-foreground"
                                aria-label={showToken ? 'Ocultar token' : 'Mostrar token'}
                            >
                                {showToken ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                            </button>
                        </div>
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
