import { useContext, useState, useEffect } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';
import { Save, Loader2, MessageSquare } from 'lucide-react';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

export default function MessagesSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    // Estados locais para campos de texto (exemplo)
    const [localWelcomeMessage, setLocalWelcomeMessage] = useState(config.messages?.welcome || 'Bem-vindo ao app!');
    const [localInvoiceReminder, setLocalInvoiceReminder] = useState(config.messages?.invoiceReminder || 'Lembrete: Sua fatura está próxima do vencimento.');

    useEffect(() => {
        setLocalWelcomeMessage(config.messages?.welcome || 'Bem-vindo ao app!');
        setLocalInvoiceReminder(config.messages?.invoiceReminder || 'Lembrete: Sua fatura está próxima do vencimento.');
    }, [config]);

    // Função para salvar localmente e atualizar o contexto
    const handleSaveMessages = () => {
        const newMessages = {
            welcome: localWelcomeMessage.trim(),
            invoiceReminder: localInvoiceReminder.trim(),
        };

        // Atualiza o contexto, aninhando a nova configuração de mensagens
        // CORRIGIDO: Tipagem do prevConfig para resolver TS7006
        setConfig((prevConfig: ProviderConfig) => ({
            ...prevConfig,
            messages: newMessages,
        }));
        
        toast.info("Configurações de mensagens salvas localmente. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };

    return (
        <SettingsPage
            title="Mensagens"
            description="Configure mensagens específicas que aparecem em telas ou notificações."
            icon={MessageSquare}
            footer={(
                <>
                    <SettingsFooterNote>Aplica no estado local; depois salve as alterações gerais para persistir.</SettingsFooterNote>
                    <Button onClick={handleSaveMessages} disabled={isSaving} className="gap-2">
                        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                        Aplicar mensagens
                    </Button>
                </>
            )}
        >
            <SettingsSection title="Textos operacionais" description="Mensagens exibidas após login e em lembretes financeiros.">
                <div className="grid gap-4">
                <div className="space-y-2">
                    <Label htmlFor="welcome">Mensagem de Boas-Vindas (Após Login)</Label>
                    <Input
                        id="welcome"
                        placeholder="Ex: Olá, aproveite nossos serviços!"
                        value={localWelcomeMessage}
                        onChange={(e) => setLocalWelcomeMessage(e.target.value)}
                        disabled={isSaving}
                    />
                    <p className="text-sm text-muted-foreground">Mensagem exibida na tela inicial após o login.</p>
                </div>

                <div className="space-y-2">
                    <Label htmlFor="reminder">Lembrete de Fatura</Label>
                    <Input
                        id="reminder"
                        placeholder="Ex: Sua fatura vence amanhã."
                        value={localInvoiceReminder}
                        onChange={(e) => setLocalInvoiceReminder(e.target.value)}
                        disabled={isSaving}
                    />
                    <p className="text-sm text-muted-foreground">Texto usado em notificações e alertas sobre faturas.</p>
                </div>
                </div>
            </SettingsSection>
        </SettingsPage>
    );
}
