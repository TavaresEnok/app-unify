// admin-painel/src/components/SetSuperAdminDialog.tsx
import { useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import { UserCog, Loader2 } from "lucide-react";
import { useApi } from "@/hooks/useApi";
import { getErrorMessage } from "@/shared/errors";

interface SetSuperAdminDialogProps {
  onUpdate: () => void;
}

export default function SetSuperAdminDialog({ onUpdate }: SetSuperAdminDialogProps) {
    const { callFunction } = useApi();
    const [email, setEmail] = useState('');
    const [isSaving, setIsSaving] = useState(false);
    const [isOpen, setIsOpen] = useState(false);

    const handleSave = async () => {
        if (!email.trim()) {
            toast.error("O campo 'Email' é obrigatório.");
            return;
        }
        setIsSaving(true);
        const toastId = toast.loading("A conceder permissão...");
        try {
            await callFunction('SET_SUPER_ADMIN_BY_EMAIL', { email });
            toast.success("Permissão concedida com sucesso!", { id: toastId });
            onUpdate();
            setIsOpen(false);
            setEmail('');
        } catch (error) {
            toast.error(`Falha ao solicitar a operação: ${getErrorMessage(error)}`, { id: toastId });
        } finally {
            setIsSaving(false);
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
