// admin-painel/src/components/EditProviderDialog.tsx
import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { parseDetails } from "@/features/provider-settings/configBoundary";
import { toast } from "sonner";
import { Loader2, FilePenLine } from "lucide-react";
import { useApi } from "@/hooks/useApi";
import { getErrorMessage } from "@/shared/errors";

interface Provider {
    id: string;
    name?: string;
    details?: ProviderDetails;
}

interface ProviderDetails {
    appName?: string;
    systemUrl?: string;
    systemType?: string;
    city?: string;
    state?: string;
    hasAndroidApp?: boolean;
    hasIosApp?: boolean;
}

interface EditProviderDialogProps {
    provider: Provider;
    onUpdate: () => void;
}

export default function EditProviderDialog({ provider, onUpdate }: EditProviderDialogProps) {
    const { callFunction } = useApi();
    const [details, setDetails] = useState<ProviderDetails>({});
    const [name, setName] = useState(provider.name || '');
    const [isSaving, setIsSaving] = useState(false);
    const [isOpen, setIsOpen] = useState(false);

    // Garante que o estado do formulário é atualizado se o prop do provedor mudar
    useEffect(() => {
        setDetails(Object.fromEntries(Object.entries(provider.details || {}).filter(([key]) => ["city", "state", "systemType"].includes(key))));
        setName(provider.name || '');
    }, [provider]);

    const handleDetailChange = (key: keyof ProviderDetails, value: any) => {
        setDetails(prev => ({ ...prev, [key]: value }));
    };

    const handleSave = async () => {
        setIsSaving(true);
        const toastId = toast.loading("A guardar alterações...");
        try {
            await callFunction('UPDATE_PROVIDER_DETAILS', { providerId: provider.id, details: parseDetails({ ...details, name }) });
            toast.success("Provedor atualizado com sucesso!", { id: toastId });
            onUpdate();
            setIsOpen(false);
        } catch (error) {
            toast.error(`Falha ao solicitar a operação: ${getErrorMessage(error)}`, { id: toastId });
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogTrigger asChild>
                <Button variant="outline" size="sm"><FilePenLine className="h-4 w-4" /></Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[800px]">
                <DialogHeader>
                    <DialogTitle>Gerenciar Provedor</DialogTitle>
                    <DialogDescription>Edite as informações de base e de sistema para este provedor.</DialogDescription>
                </DialogHeader>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 py-4">
                    <div className="space-y-2">
                        <Label htmlFor="providerName">Nome do Provedor</Label>
                        <Input id="providerName" value={name} onChange={(e) => setName(e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="systemType">Tipo de Sistema</Label>
                        <Input id="systemType" value={details.systemType || ''} onChange={(e) => handleDetailChange('systemType', e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="city">Cidade</Label>
                        <Input id="city" value={details.city || ''} onChange={(e) => handleDetailChange('city', e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="state">Estado</Label>
                        <Input id="state" value={details.state || ''} onChange={(e) => handleDetailChange('state', e.target.value)} />
                    </div>
                </div>
                <DialogFooter>
                    <Button variant="outline" onClick={() => setIsOpen(false)}>Cancelar</Button>
                    <Button onClick={handleSave} disabled={isSaving}>
                        {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Guardar Alterações
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
