// admin-painel/src/components/SetSuperAdminDialog.tsx
import { useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import { UserCog, Loader2 } from "lucide-react";
import { db } from "@/firebase/config";
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";

interface SetSuperAdminDialogProps {
  onUpdate: () => void;
}

export default function SetSuperAdminDialog({ onUpdate }: SetSuperAdminDialogProps) {
    const { user } = useAuth();
    const [email, setEmail] = useState('');
    const [isSaving, setIsSaving] = useState(false);
    const [isOpen, setIsOpen] = useState(false);

    const handleSave = async () => {
        if (!email.trim()) {
            toast.error("O campo 'Email' é obrigatório.");
            return;
        }
        if (!user) {
            toast.error("Utilizador não autenticado.");
            return;
        }

        setIsSaving(true);
        const toastId = toast.loading("A conceder permissão...");

        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                unsubscribe();
                if (response.result) {
                    toast.success(response.result.message || "Permissão concedida com sucesso!", { id: toastId });
                    onUpdate();
                    setIsOpen(false);
                    setEmail('');
                } else {
                    toast.error(`Erro ao conceder permissão: ${response.error}`, { id: toastId });
                }
                setIsSaving(false);
            }
        });

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'SET_SUPER_ADMIN_BY_EMAIL',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: { email, requesterUid: user.uid }
            });
        } catch (error: any) {
            toast.error(`Falha ao solicitar a operação: ${error.message}`, { id: toastId });
            setIsSaving(false);
            unsubscribe();
        }
    };

    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogTrigger asChild>
                <Button variant="outline"><UserCog className="mr-2 h-4 w-4" />Definir Super Admin</Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[425px]">
                <DialogHeader>
                    <DialogTitle>Definir Permissão de Super Admin</DialogTitle>
                    <DialogDescription>
                        Insira o email de um utilizador existente para lhe conceder permissões de Super Admin. Esta ação é irreversível.
                    </DialogDescription>
                </DialogHeader>
                <div className="grid gap-4 py-4">
                    <div className="space-y-2">
                        <Label htmlFor="email">Email do Utilizador</Label>
                        <Input
                            id="email"
                            type="email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            placeholder="utilizador@exemplo.com"
                        />
                    </div>
                </div>
                <DialogFooter>
                    <Button variant="outline" onClick={() => setIsOpen(false)}>Cancelar</Button>
                    <Button onClick={handleSave} disabled={isSaving}>
                        {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Conceder Permissão
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
