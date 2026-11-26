// admin-painel/src/components/AddProviderDialog.tsx - VERSÃO CORRIGIDA
import { useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import { PlusCircle, Loader2 } from "lucide-react";
import { useApi } from "@/hooks/useApi";
import { getErrorMessage } from "@/shared/errors";
import { DEFAULT_PROVIDER_CONFIG } from "@/features/provider-settings/defaults";
import { saveProviderSettings } from "@/shared/settings/providerSettingsService";

import { newProviderIdError, normalizeProviderId } from "@/features/providers/providerId";

export default function AddProviderDialog({ onUpdate, existingIds = [] }: { onUpdate: () => void; existingIds?: string[] }) {
    const [name, setName] = useState('');
    const [providerId, setProviderId] = useState('');
    const [isSaving, setIsSaving] = useState(false);
    const [isOpen, setIsOpen] = useState(false);
    const { callFunction } = useApi();

    const handleSave = async () => {
        if (!name.trim() || !providerId) { toast.error("Nome e ID são obrigatórios."); return; }
        // Criar com um ID existente sobrescreveria a marca de um provedor em produção.
        const idError = newProviderIdError(providerId, existingIds);
        if (idError) { toast.error(idError); return; }
        setIsSaving(true);
        const toastId = toast.loading("Criando provedor...");
        try {
            await callFunction('CREATE_PROVIDER', { name: name.trim(), providerId }, { silent: true });
            await saveProviderSettings(providerId, DEFAULT_PROVIDER_CONFIG);
            toast.success("Provedor criado com sucesso!", { id: toastId });
            onUpdate();
            setIsOpen(false);
            setName('');
            setProviderId('');
        } catch (error) {
            toast.error(`Erro ao criar provedor: ${getErrorMessage(error)}`, { id: toastId });
        } finally {
            setIsSaving(false);
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
                    <div className="space-y-2"><Label htmlFor="id">ID do Provedor (letras minúsculas, números, - ou _)</Label><Input id="id" value={providerId} onChange={(e) => setProviderId(normalizeProviderId(e.target.value))} />{providerId && newProviderIdError(providerId, existingIds) && <p role="alert" className="text-[12px] text-destructive">{newProviderIdError(providerId, existingIds)}</p>}</div>
                </div>
                <DialogFooter>
                    <Button variant="outline" onClick={() => setIsOpen(false)}>Cancelar</Button>
                    <Button onClick={handleSave} disabled={isSaving}>{isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}Salvar</Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
