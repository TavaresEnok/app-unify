import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "sonner";

interface EditTermDialogProps {
  termName: 'Termos de Uso' | 'Política de Privacidade';
  initialContent: string;
  onSave: (content: string) => void;
  children: React.ReactNode;
}

export default function EditTermDialog({ termName, initialContent, onSave, children }: EditTermDialogProps) {
    const [isOpen, setIsOpen] = useState(false);
    const [content, setContent] = useState('');

    useEffect(() => {
        if (isOpen) {
            setContent(initialContent || '');
        }
    }, [isOpen, initialContent]);

    const handleSave = () => {
        onSave(content);
        setIsOpen(false);
        toast.success(`${termName} atualizados. Clique em 'Salvar Alterações' para confirmar.`);
    };

    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogTrigger asChild>{children}</DialogTrigger>
            <DialogContent className="sm:max-w-2xl">
                <DialogHeader>
                    <DialogTitle>Editar {termName}</DialogTitle>
                    <DialogDescription>
                        Modifique o conteúdo abaixo. Você pode usar tags HTML básicas como &lt;p&gt; e &lt;br&gt; para formatação.
                    </DialogDescription>
                </DialogHeader>
                <div className="py-4">
                    <Label htmlFor="term-content" className="sr-only">{termName}</Label>
                    <Textarea
                        id="term-content"
                        value={content}
                        onChange={(e) => setContent(e.target.value)}
                        className="h-80"
                        placeholder={`Digite os ${termName} aqui...`}
                    />
                </div>
                <DialogFooter>
                    <Button variant="outline" onClick={() => setIsOpen(false)}>Cancelar</Button>
                    <Button onClick={handleSave}>Salvar Conteúdo</Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
