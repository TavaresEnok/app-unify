import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "sonner";
import { TipItem } from "@/pages/provider-settings/TipsSettings"; // Interface da página de Dicas

interface AddEditTipDialogProps {
  mode: 'add' | 'edit';
  initialData?: TipItem;
  onSave: (tipItem: TipItem) => void;
  children: React.ReactNode;
}

export default function AddEditTipDialog({ mode, initialData, onSave, children }: AddEditTipDialogProps) {
    const [isOpen, setIsOpen] = useState(false);
    const [title, setTitle] = useState('');
    const [description, setDescription] = useState('');

    useEffect(() => {
        if (isOpen && mode === 'edit' && initialData) {
            setTitle(initialData.title);
            setDescription(initialData.description);
        } else if (!isOpen) {
            setTitle('');
            setDescription('');
        }
    }, [isOpen, mode, initialData]);

    const handleSave = () => {
        if (!title || !description) {
            toast.error("O Título e a Descrição são obrigatórios.");
            return;
        }
        const tipData: TipItem = {
            id: initialData?.id || crypto.randomUUID(),
            title,
            description
        };
        onSave(tipData);
        setIsOpen(false);
        toast.success(`Dica ${mode === 'add' ? 'adicionada' : 'atualizada'}!`);
    };

    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogTrigger asChild>{children}</DialogTrigger>
            <DialogContent>
                <DialogHeader>
                    <DialogTitle>{mode === 'add' ? 'Adicionar Nova Dica' : 'Editar Dica'}</DialogTitle>
                    <DialogDescription>
                        Insira um título e a descrição para a dica ou informativo.
                    </DialogDescription>
                </DialogHeader>
                <div className="space-y-4 py-4">
                    <div className="space-y-2">
                        <Label htmlFor="title">Título</Label>
                        <Input id="title" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Ex: Reinicie seu roteador!" />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="description">Descrição</Label>
                        <Textarea id="description" value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Ex: Desligar o roteador da tomada por 10 segundos pode resolver problemas de lentidão." rows={5} />
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
