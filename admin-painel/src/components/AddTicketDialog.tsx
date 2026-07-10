// admin-painel/src/components/AddTicketDialog.tsx - TESTE FINAL DE CAMINHO
import { useState, useRef } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "sonner";
import { PlusCircle, Loader2, Paperclip, XCircle } from "lucide-react";
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { useAuth } from "@/contexts/AuthContext";
import { useApi } from "@/hooks/useApi";

interface AddTicketDialogProps {
  providerName: string;
  onTicketCreated: () => void;
}

export default function AddTicketDialog({ providerName, onTicketCreated }: AddTicketDialogProps) {
    const [subject, setSubject] = useState('');
    const [message, setMessage] = useState('');
    const [isSaving, setIsSaving] = useState(false);
    const [isOpen, setIsOpen] = useState(false);
    const [imageFile, setImageFile] = useState<File | null>(null);
    const [imagePreview, setImagePreview] = useState<string | null>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);
    const { user, providerId } = useAuth();
    const { callFunction } = useApi();

    const resetState = () => {
        setSubject('');
        setMessage('');
        setImageFile(null);
        setImagePreview(null);
        if (fileInputRef.current) fileInputRef.current.value = "";
    };

    const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files[0]) {
            const file = e.target.files[0];
            setImageFile(file);
            setImagePreview(URL.createObjectURL(file));
        }
    };

    const handleSave = async () => {
        if (!subject.trim()) {
            toast.error("O campo 'Assunto' é obrigatório.");
            return;
        }
        if (!user || !providerId || !user.email) {
            toast.error("Utilizador não autenticado corretamente.");
            return;
        }
        
        setIsSaving(true);
        const toastId = toast.loading("A abrir novo ticket...");

        try {
            let imageUrl: string | null = null;
            if (imageFile) {
                toast.loading("A enviar imagem...", { id: toastId });
                const storage = getStorage();

                // ===================================================================
                // O TESTE FINAL ESTÁ AQUI: Mudamos o caminho para dentro de 'providers'
                // ===================================================================
                const filePath = `providers/${providerId}/ticket_attachments/${Date.now()}_${imageFile.name}`;
                
                const storageRef = ref(storage, filePath);
                const uploadResult = await uploadBytes(storageRef, imageFile);
                imageUrl = await getDownloadURL(uploadResult.ref);
            }

            toast.loading("A registar ticket...", { id: toastId });
            await callFunction('CREATE_TICKET', { subject, message, providerName, providerId, userEmail: user.email, imageUrl });
            toast.success("Ticket criado com sucesso!", { id: toastId });
            onTicketCreated();
            setIsOpen(false);
            resetState();
        } catch (error: any) {
            toast.error(`Falha crítica ao criar ticket: ${error.message}`, { id: toastId });
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <Dialog open={isOpen} onOpenChange={(open) => { if (!open) resetState(); setIsOpen(open); }}>
            <DialogTrigger asChild><Button><PlusCircle className="mr-2 h-4 w-4" />Abrir Novo Ticket</Button></DialogTrigger>
            <DialogContent className="sm:max-w-[625px]">
                <DialogHeader>
                    <DialogTitle>Abrir Novo Ticket de Suporte</DialogTitle>
                    <DialogDescription>Descreva o seu problema ou dúvida. A nossa equipe responderá o mais breve possível.</DialogDescription>
                </DialogHeader>
                <div className="grid gap-4 py-4">
                    <div className="space-y-2">
                        <Label htmlFor="subject">Assunto</Label>
                        <Input id="subject" value={subject} onChange={(e) => setSubject(e.target.value)} placeholder="Ex: Dúvida sobre o módulo de faturas" />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="message">Mensagem</Label>
                        <Textarea id="message" value={message} onChange={(e) => setMessage(e.target.value)} placeholder="Detalhe aqui a sua solicitação..." rows={6} />
                    </div>
                    {imagePreview && (
                        <div className="relative w-32 h-32">
                            <img src={imagePreview} alt="Pré-visualização" className="rounded-md w-full h-full object-cover"/>
                            <Button variant="ghost" size="icon" className="absolute top-0 right-0 h-6 w-6 bg-black/50 hover:bg-black/70" onClick={() => { setImageFile(null); setImagePreview(null); if(fileInputRef.current) fileInputRef.current.value = ""; }}>
                                <XCircle className="text-white"/>
                            </Button>
                        </div>
                    )}
                </div>
                <DialogFooter className="sm:justify-between">
                    <Button variant="outline" onClick={() => fileInputRef.current?.click()} disabled={isSaving}>
                        <Paperclip className="mr-2 h-4 w-4" />
                        Anexar Imagem
                    </Button>
                    <input type="file" ref={fileInputRef} className="hidden" accept="image/png, image/jpeg" onChange={handleImageSelect}/>
                    <div className="flex gap-2">
                        <Button variant="outline" onClick={() => setIsOpen(false)}>Cancelar</Button>
                        <Button onClick={handleSave} disabled={isSaving}>
                            {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            Enviar Ticket
                        </Button>
                    </div>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
