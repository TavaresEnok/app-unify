import { useContext, useState, useEffect, useCallback } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Loader2, HelpCircle, PlusCircle, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';
import { SettingsFooterNote, SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

export interface FaqItem {
    id: string;
    question: string;
    answer: string;
}

export default function FaqSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    // Converte o objeto/array de faqs para um estado local
    const [localFaqs, setLocalFaqs] = useState<FaqItem[]>(() => {
        // Assume que 'config.faq' é um array de { question: string, answer: string }
        return (config.faq || []).map((item: { question: string, answer: string }, index: number) => ({
            id: `faq-${index}-${Math.random()}`,
            question: item.question,
            answer: item.answer,
        }));
    });
    const [newQuestion, setNewQuestion] = useState('');
    const [newAnswer, setNewAnswer] = useState('');

    useEffect(() => {
        // Sincroniza o estado local com o estado global ao carregar a página
        setLocalFaqs((config.faq || []).map((item: { question: string, answer: string }, index: number) => ({
            id: `faq-${index}-${Math.random()}`,
            question: item.question,
            answer: item.answer,
        })));
    }, [config.faq]);

    // Função interna para atualizar o contexto e o estado local
    const updateAndSave = (updatedFaqs: FaqItem[]) => {
        setLocalFaqs(updatedFaqs);
        
        // Mapeia para o formato de salvamento (apenas question e answer)
        const contentArray = updatedFaqs.map(t => ({ question: t.question, answer: t.answer }));
        
        // Atualiza o contexto, aninhando a nova configuração de faqs
        // CORRIGIDO: Tipagem do prev para resolver TS7006
        setConfig((prev: ProviderConfig) => ({ ...prev, faq: contentArray }));
    };

    const handleAddFaq = () => {
        if (!newQuestion.trim() || !newAnswer.trim()) {
            toast.error("A pergunta e a resposta são obrigatórias.");
            return;
        }

        const newFaq: FaqItem = { id: `faq-${Date.now()}`, question: newQuestion.trim(), answer: newAnswer.trim() };
        const updatedFaqs = [...localFaqs, newFaq];

        updateAndSave(updatedFaqs);
        setNewQuestion('');
        setNewAnswer('');
        toast.success("FAQ adicionada. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };

    const handleRemoveFaq = (id: string) => {
        const updatedFaqs = localFaqs.filter(faq => faq.id !== id);
        updateAndSave(updatedFaqs);
        toast.warning("FAQ removida. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };
    
    // Função para aplicar as alterações (apenas notifica, pois o setConfig já foi chamado)
    const handleApplyChanges = useCallback(() => {
        toast.success("Configurações de FAQ aplicadas. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    }, []);

    return (
        <SettingsPage
            title="Perguntas Frequentes"
            description="Gerencie perguntas e respostas exibidas na seção de ajuda do aplicativo."
            icon={HelpCircle}
            footer={(
                <>
                    <SettingsFooterNote>As alterações são aplicadas localmente e devem ser salvas nas configurações gerais.</SettingsFooterNote>
                    <Button onClick={handleApplyChanges} disabled={isSaving} className="gap-2">
                        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
                        Aplicar FAQ
                    </Button>
                </>
            )}
        >
            <SettingsSection title="Adicionar FAQ" description="Crie uma pergunta e resposta para a central de ajuda.">
                {/* Adicionar Nova FAQ */}
                <div className="space-y-4">
                    <Input
                        placeholder="Pergunta"
                        value={newQuestion}
                        onChange={(e) => setNewQuestion(e.target.value)}
                        disabled={isSaving}
                    />
                    <Input
                        placeholder="Resposta"
                        value={newAnswer}
                        onChange={(e) => setNewAnswer(e.target.value)}
                        disabled={isSaving}
                    />
                    <Button onClick={handleAddFaq} disabled={isSaving || !newQuestion.trim() || !newAnswer.trim()}>
                        <PlusCircle className="h-4 w-4 mr-2" /> Adicionar FAQ
                    </Button>
                </div>
            </SettingsSection>

            <SettingsSection title={`FAQs atuais (${localFaqs.length})`} description="Itens exibidos no app para autoatendimento.">
                {/* Lista de FAQs Atuais */}
                {localFaqs.length > 0 ? (
                        <Accordion type="single" collapsible className="w-full">
                            {localFaqs.map((faq) => (
                                <AccordionItem key={faq.id} value={faq.id} className="rounded-lg border border-[#EEF0F4] bg-white px-3">
                                    <AccordionTrigger className="font-medium text-left">
                                        <div className="flex items-center gap-2">
                                            <HelpCircle className="h-4 w-4 text-primary" />
                                            {faq.question}
                                        </div>
                                    </AccordionTrigger>
                                    <AccordionContent className="flex items-start gap-4">
                                        <p className="flex-1 text-sm text-muted-foreground pt-1">{faq.answer}</p>
                                        <Button 
                                            variant="destructive" 
                                            size="icon" 
                                            onClick={() => handleRemoveFaq(faq.id)} 
                                            disabled={isSaving}
                                            className="h-7 w-7 flex-shrink-0"
                                        >
                                            <Trash2 className="h-4 w-4" />
                                        </Button>
                                    </AccordionContent>
                                </AccordionItem>
                            ))}
                        </Accordion>
                ) : (
                    <p className="rounded-lg border border-dashed border-[#C6CDD9] bg-white p-6 text-center text-sm text-muted-foreground">Nenhuma FAQ configurada ainda.</p>
                )}
            </SettingsSection>
        </SettingsPage>
    );
}
