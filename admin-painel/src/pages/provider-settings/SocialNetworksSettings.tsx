import { useContext, useState, useEffect } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Save, Loader2, Instagram, Facebook, Globe, MessageCircle } from 'lucide-react'; // Whatsapp substituído por MessageCircle
import { toast } from 'sonner';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

export default function SocialNetworksSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    const [localInstagram, setLocalInstagram] = useState(config.socialNetworks?.instagram || '');
    const [localFacebook, setLocalFacebook] = useState(config.socialNetworks?.facebook || '');
    const [localWebsite, setLocalWebsite] = useState(config.socialNetworks?.website || '');
    const [localWhatsapp, setLocalWhatsapp] = useState(config.socialNetworks?.whatsapp || '');

    useEffect(() => {
        setLocalInstagram(config.socialNetworks?.instagram || '');
        setLocalFacebook(config.socialNetworks?.facebook || '');
        setLocalWebsite(config.socialNetworks?.website || '');
        setLocalWhatsapp(config.socialNetworks?.whatsapp || '');
    }, [config]);

    // Função para salvar localmente e atualizar o contexto
    const handleSaveSocial = () => {
        const newSocialNetworks = {
            instagram: localInstagram.trim(),
            facebook: localFacebook.trim(),
            website: localWebsite.trim(),
            whatsapp: localWhatsapp.trim(),
        };

        // Atualiza o contexto, aninhando a nova configuração de redes sociais
        setConfig((prevConfig: ProviderConfig) => ({
            ...prevConfig,
            socialNetworks: newSocialNetworks,
        }));
        
        toast.info("Links de redes sociais salvos localmente. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };

    return (
        <SettingsPage
            title="Redes Sociais e Links"
            description="Adicione links diretos para as redes sociais da sua empresa."
            icon={Globe}
            footer={(
                <>
                    <SettingsFooterNote>Aplica localmente no contexto; salve as alterações gerais para confirmar.</SettingsFooterNote>
                    <Button onClick={handleSaveSocial} disabled={isSaving} className="gap-2">
                        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                        Aplicar links
                    </Button>
                </>
            )}
        >
            <SettingsSection title="Canais públicos" description="Links exibidos no app e nos pontos de contato do cliente.">
                <div className="grid gap-4 lg:grid-cols-2">
                <div className="space-y-2">
                    <Label htmlFor="instagram">Link do Instagram</Label>
                    <div className="flex items-center gap-2">
                        <Instagram className="h-4 w-4 text-muted-foreground flex-shrink-0" />
                        <Input
                            id="instagram"
                            placeholder="Ex: https://instagram.com/seuperfil"
                            value={localInstagram}
                            onChange={(e) => setLocalInstagram(e.target.value)}
                            disabled={isSaving}
                        />
                    </div>
                </div>

                <div className="space-y-2">
                    <Label htmlFor="facebook">Link do Facebook</Label>
                    <div className="flex items-center gap-2">
                        <Facebook className="h-4 w-4 text-muted-foreground flex-shrink-0" />
                        <Input
                            id="facebook"
                            placeholder="Ex: https://facebook.com/seuperfil"
                            value={localFacebook}
                            onChange={(e) => setLocalFacebook(e.target.value)}
                            disabled={isSaving}
                        />
                    </div>
                </div>

                <div className="space-y-2">
                    <Label htmlFor="website">Link do Site</Label>
                    <div className="flex items-center gap-2">
                        <Globe className="h-4 w-4 text-muted-foreground flex-shrink-0" />
                        <Input
                            id="website"
                            placeholder="Ex: https://www.seuprovedor.com"
                            value={localWebsite}
                            onChange={(e) => setLocalWebsite(e.target.value)}
                            disabled={isSaving}
                        />
                    </div>
                </div>
                
                <div className="space-y-2">
                    <Label htmlFor="whatsapp">Número de Contato/WhatsApp</Label>
                    <div className="flex items-center gap-2">
                        <MessageCircle className="h-4 w-4 text-muted-foreground flex-shrink-0" /> 
                        <Input
                            id="whatsapp"
                            placeholder="Ex: +5511987654321"
                            value={localWhatsapp}
                            onChange={(e) => setLocalWhatsapp(e.target.value)}
                            disabled={isSaving}
                        />
                    </div>
                </div>
                </div>
            </SettingsSection>
        </SettingsPage>
    );
}
