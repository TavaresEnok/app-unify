// admin-painel/src/components/AddProviderDialog.tsx - VERSÃO CORRIGIDA
import { useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import { PlusCircle, Loader2 } from "lucide-react";
import { db } from "@/firebase/config";
// AQUI ESTÁ A CORREÇÃO: onSnapshot foi adicionado à importação
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";
import { useAuth } from "@/contexts/AuthContext";

export default function AddProviderDialog({ onUpdate }: { onUpdate: () => void }) {
    const [name, setName] = useState('');
    const [providerId, setProviderId] = useState('');
    const [isSaving, setIsSaving] = useState(false);
    const [isOpen, setIsOpen] = useState(false);
    const { user } = useAuth();

    const handleSave = async () => {
        if (!name || !providerId) { toast.error("Nome e ID são obrigatórios."); return; }
        if (!user) { toast.error("Utilizador não autenticado."); return; }

        setIsSaving(true);
        const toastId = toast.loading("Enviando pedido para criar provedor...");
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                if (response.result) {
                    toast.success(response.result.message || "Provedor criado com sucesso!", { id: toastId });
                    onUpdate(); // Atualiza a lista na página principal
                    setIsOpen(false);
                    setName('');
                    setProviderId('');
                } else if (response.error) {
                    toast.error(`Erro ao criar provedor: ${response.error}`, { id: toastId });
                }
                // Parar de ouvir após receber a resposta
                unsubscribe();
                setIsSaving(false); // Reativa o botão
            }
        });
        
        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'CREATE_PROVIDER',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: { name, providerId }
            });
        } catch (error: any) {
            toast.error(`Erro ao solicitar criação: ${error.message}`, { id: toastId });
            unsubscribe();
            setIsSaving(false); // Reativa o botão em caso de erro na solicitação
        }
    };

    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogTrigger asChild><Button><PlusCircle className="mr-2 h-4 w-4" />Adicionar Novo Provedor</Button></DialogTrigger>
            <DialogContent>
                <DialogHeader>
                    <DialogTitle>Adicionar Novo Provedor</DialogTitle>
                    <DialogDescription>Crie um novo provedor na plataforma.</DialogDescription>
                </DialogHeader>
                <div className="grid gap-4 py-4">
                    <div className="space-y-2"><Label htmlFor="name">Nome do Provedor</Label><Input id="name" value={name} onChange={(e) => setName(e.target.value)} /></div>
                    <div className="space-y-2"><Label htmlFor="id">ID do Provedor (sem espaços/caracteres especiais)</Label><Input id="id" value={providerId} onChange={(e) => setProviderId(e.target.value.toLowerCase().trim())} /></div>
                </div>
                <DialogFooter>
                    <Button variant="outline" onClick={() => setIsOpen(false)}>Cancelar</Button>
                    <Button onClick={handleSave} disabled={isSaving}>{isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}Salvar</Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
