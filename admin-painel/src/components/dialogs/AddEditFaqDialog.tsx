import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "sonner";
import { FaqItem } from "@/pages/provider-settings/FaqSettings"; // Iremos criar esta interface

interface AddEditFaqDialogProps {
  mode: 'add' | 'edit';
  initialData?: FaqItem;
  onSave: (faqItem: FaqItem) => void;
  children: React.ReactNode;
}

export default function AddEditFaqDialog({ mode, initialData, onSave, children }: AddEditFaqDialogProps) {
    const [isOpen, setIsOpen] = useState(false);
    const [question, setQuestion] = useState('');
    const [answer, setAnswer] = useState('');

    useEffect(() => {
        if (isOpen && mode === 'edit' && initialData) {
            setQuestion(initialData.question);
            setAnswer(initialData.answer);
        } else if (!isOpen) {
            setQuestion('');
            setAnswer('');
        }
    }, [isOpen, mode, initialData]);

    const handleSave = () => {
        if (!question || !answer) {
            toast.error("A Pergunta e a Resposta são obrigatórias.");
            return;
        }
        const faqData: FaqItem = {
            id: initialData?.id || crypto.randomUUID(),
            question,
            answer
        };
        onSave(faqData);
        setIsOpen(false);
        toast.success(`Item de FAQ ${mode === 'add' ? 'adicionado' : 'atualizado'}!`);
    };

    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogTrigger asChild>{children}</DialogTrigger>
            <DialogContent>
                <DialogHeader>
                    <DialogTitle>{mode === 'add' ? 'Adicionar Pergunta Frequente' : 'Editar Pergunta Frequente'}</DialogTitle>
                    <DialogDescription>
                        Insira a pergunta e a resposta correspondente.
                    </DialogDescription>
                </DialogHeader>
                <div className="space-y-4 py-4">
                    <div className="space-y-2">
                        <Label htmlFor="question">Pergunta</Label>
                        <Input id="question" value={question} onChange={(e) => setQuestion(e.target.value)} placeholder="Ex: Como solicitar a segunda via da fatura?" />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="answer">Resposta</Label>
                        <Textarea id="answer" value={answer} onChange={(e) => setAnswer(e.target.value)} placeholder="Ex: Você pode acessar a segunda via através do menu 'Faturas'..." rows={5} />
                    </div>
                </div>
                <DialogFooter>
                    <Button variant="outline" onClick={() => setIsOpen(false)}>Cancelar</Button>
                    <Button onClick={handleSave}>Salvar</Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
