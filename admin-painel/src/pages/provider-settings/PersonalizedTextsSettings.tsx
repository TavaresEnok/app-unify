import { useState, useEffect } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { PlusCircle, Trash2, Type } from 'lucide-react';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';
export default function PersonalizedTextsSettings() {
    const { config, setConfig } = useSettings();
    // Local state for the strings section
    const [strings, setStrings] = useState<any>({});
    const [ticketSubjects, setTicketSubjects] = useState<string[]>([]);
    const [newSubject, setNewSubject] = useState('');
    useEffect(() => {
        // Load existing strings or use defaults
        const currentStrings = config.strings || {};
        setStrings(currentStrings);
        setTicketSubjects(currentStrings.ticket_subjects || []);
    }, [config.strings]);
    const handleStringChange = (key: string, value: string) => {
        const updatedStrings = { ...strings, [key]: value };
        setStrings(updatedStrings);
        // Update global config immediately
        setConfig((prev: any) => ({ ...prev, strings: updatedStrings }));
    };
    const handleAddSubject = () => {
        if (!newSubject.trim()) return;
        const updatedSubjects = [...ticketSubjects, newSubject.trim()];
        setTicketSubjects(updatedSubjects);
        setNewSubject('');
        
        const updatedStrings = { ...strings, ticket_subjects: updatedSubjects };
        setStrings(updatedStrings);
        setConfig((prev: any) => ({ ...prev, strings: updatedStrings }));
    };
    const handleRemoveSubject = (index: number) => {
        const updatedSubjects = ticketSubjects.filter((_, i) => i !== index);
        setTicketSubjects(updatedSubjects);
        
        const updatedStrings = { ...strings, ticket_subjects: updatedSubjects };
        setStrings(updatedStrings);
        setConfig((prev: any) => ({ ...prev, strings: updatedStrings }));
    };
    return (
        <SettingsPage
            title="Textos personalizados"
            description="Personalize textos, etiquetas e opções exibidas no aplicativo do assinante."
            icon={Type}
            footer={<SettingsFooterNote>Esses campos atualizam a configuração local imediatamente. Salve as alterações gerais para persistir.</SettingsFooterNote>}
        >
            <SettingsSection title="Tela inicial" description="Saudações, labels de plano e atalhos principais.">
                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label>Saudação (Home)</Label>
                            <Input 
                                value={strings.hello_prefix || ''} 
                                onChange={(e) => handleStringChange('hello_prefix', e.target.value)}
                                placeholder="Ex: Olá,"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Prefixo do Plano</Label>
                            <Input 
                                value={strings.plan_prefix || ''} 
                                onChange={(e) => handleStringChange('plan_prefix', e.target.value)}
                                placeholder="Ex: Seu plano é:"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Botão Sair</Label>
                            <Input 
                                value={strings.logout_label || ''} 
                                onChange={(e) => handleStringChange('logout_label', e.target.value)}
                                placeholder="Ex: Sair"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Título Aba Home</Label>
                            <Input 
                                value={strings.home_tab_title || ''} 
                                onChange={(e) => handleStringChange('home_tab_title', e.target.value)}
                                placeholder="Ex: Início"
                            />
                        </div>
                    </div>
                    <div className="space-y-2">
                        <Label>Botão Diagnóstico de Rede</Label>
                        <Input 
                            value={strings.diagnostics_button || ''} 
                            onChange={(e) => handleStringChange('diagnostics_button', e.target.value)}
                            placeholder="Ex: Diagnóstico de Rede"
                        />
                    </div>
                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label>Status OK (Título)</Label>
                            <Input 
                                value={strings.status_ok_title || ''} 
                                onChange={(e) => handleStringChange('status_ok_title', e.target.value)}
                                placeholder="Ex: Tudo certo"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Status OK (Mensagem)</Label>
                            <Input 
                                value={strings.status_ok_message || ''} 
                                onChange={(e) => handleStringChange('status_ok_message', e.target.value)}
                                placeholder="Ex: com seu(s) plano(s)!"
                            />
                        </div>
                    </div>
                     <div className="space-y-2">
                        <Label>Mensagem Selecionar Contrato</Label>
                        <Input 
                            value={strings.select_contract_message || ''} 
                            onChange={(e) => handleStringChange('select_contract_message', e.target.value)}
                            placeholder="Ex: Selecionar contrato"
                        />
                    </div>
                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label>Etiqueta Última Fatura</Label>
                            <Input 
                                value={strings.last_invoice_label || ''} 
                                onChange={(e) => handleStringChange('last_invoice_label', e.target.value)}
                                placeholder="Ex: Última fatura"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Botão Ver Faturas</Label>
                            <Input 
                                value={strings.view_invoices_label || ''} 
                                onChange={(e) => handleStringChange('view_invoices_label', e.target.value)}
                            placeholder="Ex: Ver faturas"
                        />
                    </div>
                    <div className="space-y-2">
                        <Label>Botão Pagar Fatura</Label>
                        <Input
                            value={strings.pay_invoice_label || ''}
                            onChange={(e) => handleStringChange('pay_invoice_label', e.target.value)}
                            placeholder="Ex: Pagar fatura"
                        />
                    </div>
                    <div className="space-y-2">
                        <Label>Botão Promessa Pagamento</Label>
                        <Input
                            value={strings.promise_payment_label || ''}
                            onChange={(e) => handleStringChange('promise_payment_label', e.target.value)}
                            placeholder="Ex: Prometer pagamento"
                        />
                    </div>
                    </div>
            </SettingsSection>

            <SettingsSection title="Tela de suporte" description="Textos e opções da área de atendimento.">
                     <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label>Título da Tela</Label>
                            <Input 
                                value={strings.support_title || ''} 
                                onChange={(e) => handleStringChange('support_title', e.target.value)}
                                placeholder="Ex: Suporte Técnico"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Título Canais de Atendimento</Label>
                            <Input 
                                value={strings.channels_title || ''} 
                                onChange={(e) => handleStringChange('channels_title', e.target.value)}
                                placeholder="Ex: Canais de Atendimento"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Título Abrir Ticket</Label>
                            <Input 
                                value={strings.open_ticket_title || ''} 
                                onChange={(e) => handleStringChange('open_ticket_title', e.target.value)}
                                placeholder="Ex: Abrir Novo Ticket"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Título Termos de Uso</Label>
                            <Input 
                                value={strings.terms_title || ''} 
                                onChange={(e) => handleStringChange('terms_title', e.target.value)}
                                placeholder="Ex: Termos de Serviço"
                            />
                        </div>
                    </div>
                    <div className="space-y-4 border-t border-[#EEF0F4] pt-4">
                        <Label className="text-[12.5px] font-semibold text-[#39414F]">Assuntos de Ticket</Label>
                        <div className="flex gap-2">
                            <Input 
                                value={newSubject}
                                onChange={(e) => setNewSubject(e.target.value)}
                                placeholder="Novo assunto (ex: Financeiro)"
                                onKeyDown={(e) => e.key === 'Enter' && handleAddSubject()}
                            />
                            <Button onClick={handleAddSubject} variant="secondary">
                                <PlusCircle className="h-4 w-4" />
                            </Button>
                        </div>
                        
                        <div className="space-y-2">
                            {ticketSubjects.map((subject, index) => (
                                <div key={index} className="flex items-center justify-between rounded-lg border border-[#EEF0F4] bg-white p-2">
                                    <span>{subject}</span>
                                    <Button variant="ghost" size="sm" onClick={() => handleRemoveSubject(index)}>
                                        <Trash2 className="h-4 w-4 text-destructive" />
                                    </Button>
                                </div>
                            ))}
                            {ticketSubjects.length === 0 && (
                                <p className="text-sm text-muted-foreground italic">Nenhum assunto configurado.</p>
                            )}
                        </div>
                    </div>
            </SettingsSection>
        </SettingsPage>
    );
}
