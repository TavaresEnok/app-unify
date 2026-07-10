import { useState, useEffect } from 'react';
import { useSettings, ProviderConfig } from '@/contexts/SettingsContext';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Save, Loader2, SlidersHorizontal } from 'lucide-react';
import { toast } from 'sonner';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

export default function OtherSettings() {
    const { config, setConfig, isSaving } = useSettings();

    // Estados locais para campos de texto (exemplo: URL de política de privacidade, etc.)
    const [localPrivacyPolicyUrl, setLocalPrivacyPolicyUrl] = useState(config.other?.privacyPolicyUrl || '');
    const [localCustomDomain, setLocalCustomDomain] = useState(config.other?.customDomain || '');
    const [localSpeedTestUrl, setLocalSpeedTestUrl] = useState(config.other?.speedTestUrl || '');

    useEffect(() => {
        setLocalPrivacyPolicyUrl(config.other?.privacyPolicyUrl || '');
        setLocalCustomDomain(config.other?.customDomain || '');
        setLocalSpeedTestUrl(config.other?.speedTestUrl || '');
    }, [config]);

    // Função para salvar localmente e atualizar o contexto
    const handleSaveOtherSettings = () => {
        // Atualiza o contexto, preservando outras chaves em 'other'
        setConfig((prevConfig: ProviderConfig) => ({
            ...prevConfig,
            other: {
                ...(prevConfig.other || {}),
                privacyPolicyUrl: localPrivacyPolicyUrl.trim(),
                customDomain: localCustomDomain.trim(),
                speedTestUrl: localSpeedTestUrl.trim(),
            },
        }));

        toast.info("Outras configurações salvas localmente. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };

    return (
        <SettingsPage
            title="Outros"
            description="Opções diversas e links não cobertos nas outras seções."
            icon={SlidersHorizontal}
            footer={(
                <>
                    <SettingsFooterNote>Aplica localmente no contexto; salve as alterações gerais para confirmar.</SettingsFooterNote>
                    <Button onClick={handleSaveOtherSettings} disabled={isSaving} className="gap-2">
                        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                        Aplicar outras configurações
                    </Button>
                </>
            )}
        >
            <SettingsSection title="Links e domínios" description="URLs auxiliares usadas pelo aplicativo.">
                <div className="grid gap-4">
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

                <div className="space-y-2">
                    <Label htmlFor="speedTestUrl">URL do Servidor Personalizado (Download/Upload)</Label>
                    <Input
                        id="speedTestUrl"
                        placeholder="Ex: http://192.168.1.100:8080/folder/file.zip"
                        value={localSpeedTestUrl}
                        onChange={(e) => setLocalSpeedTestUrl(e.target.value)}
                        disabled={isSaving}
                    />
                    <p className="text-sm text-muted-foreground">
                        Link direto para seu servidor próprio. O app usará este endereço para forçar o download/upload.
                    </p>
                </div>
                </div>
            </SettingsSection>
        </SettingsPage>
    );
}
