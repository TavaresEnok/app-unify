import { useState, useEffect } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';
import { Save, Loader2, MessageSquare } from 'lucide-react';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

// Textos de exemplo que o painel salvava antes; app e lembrete os ignoram.
const OLD_WELCOME = 'Bem-vindo ao app!';
const OLD_REMINDER = 'Lembrete: Sua fatura está próxima do vencimento.';
const WELCOME_MAX = 160;
const REMINDER_MAX = 200;

const clean = (value: string | undefined, old: string) => (value && value.trim() !== old ? value : '');

export default function MessagesSettings() {
    const { config, saveConfig, isSaving } = useSettings();
    const [welcome, setWelcome] = useState(clean(config.messages?.welcome, OLD_WELCOME));
    const [reminder, setReminder] = useState(clean(config.messages?.invoiceReminder, OLD_REMINDER));

    useEffect(() => {
        setWelcome(clean(config.messages?.welcome, OLD_WELCOME));
        setReminder(clean(config.messages?.invoiceReminder, OLD_REMINDER));
    }, [config.messages?.welcome, config.messages?.invoiceReminder]);

    const reminderPreview = (reminder.trim() || 'Sua fatura de {valor} vence {quando}. Toque para pagar com PIX ou boleto.')
        .replace(/\{valor\}/gi, 'R$ 99,90').replace(/\{quando\}/gi, 'amanhã');

    const handleSave = async () => {
        await saveConfig({ ...config, messages: { ...(config.messages ?? {}), welcome: welcome.trim(), invoiceReminder: reminder.trim() } });
        toast.success('Mensagens salvas!');
    };

    return (
        <SettingsPage
            title="Mensagens"
            description="Boas-vindas depois do login e o texto dos lembretes de fatura."
            icon={MessageSquare}
            footer={(
                <>
                    <SettingsFooterNote>Em branco, o app usa os textos automáticos.</SettingsFooterNote>
                    <Button onClick={() => void handleSave()} disabled={isSaving} className="gap-2">
                        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                        {isSaving ? 'Salvando...' : 'Salvar alterações'}
                    </Button>
                </>
            )}
        >
            <SettingsSection title="Boas-vindas" description="Aparece uma vez, na parte de baixo da tela, logo depois que o assinante entra. Apps a partir da versão 1.0.22.">
                <div className="space-y-2">
                    <Label htmlFor="welcome">Mensagem</Label>
                    <Input
                        id="welcome"
                        maxLength={WELCOME_MAX}
                        placeholder="Ex: Que bom ter você aqui! Qualquer dúvida, fale com a gente no Suporte."
                        value={welcome}
                        onChange={(e) => setWelcome(e.target.value)}
                        disabled={isSaving}
                    />
                    <p className="text-xs text-muted-foreground">Até {WELCOME_MAX} caracteres. Em branco, nada aparece.</p>
                </div>
            </SettingsSection>

            <SettingsSection title="Lembrete de fatura" description="Texto da notificação enviada antes e depois do vencimento (regras em Comunicados). O título continua automático, dizendo quando vence.">
                <div className="space-y-2">
                    <Label htmlFor="reminder">Texto da notificação</Label>
                    <Textarea
                        id="reminder"
                        rows={2}
                        maxLength={REMINDER_MAX}
                        placeholder="Ex: Olá! Sua fatura de {valor} vence {quando}. Pague pelo app com PIX."
                        value={reminder}
                        onChange={(e) => setReminder(e.target.value)}
                        disabled={isSaving}
                    />
                    <p className="text-xs text-muted-foreground">
                        Use <code>{'{valor}'}</code> para o valor e <code>{'{quando}'}</code> para "amanhã", "hoje", "em 3 dias" ou "há 2 dias". Em branco, vale o texto automático.
                    </p>
                    <div className="rounded-lg border border-[#EEF0F4] bg-white p-3 text-sm">
                        <p className="font-semibold text-[#18202C]">Fatura vencendo amanhã</p>
                        <p className="text-[#596577]">{reminderPreview}</p>
                    </div>
                </div>
            </SettingsSection>
        </SettingsPage>
    );
}
