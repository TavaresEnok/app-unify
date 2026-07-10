// admin-painel/src/components/EditProviderDialog.tsx
import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
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
    apiToken?: string;
    systemUrl?: string;
    systemType?: string;
    apiUrl?: string;  // URL do Proxy/API
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
    const [details, setDetails] = useState<ProviderDetails>(provider.details || {});
    const [name, setName] = useState(provider.name || '');
    const [isSaving, setIsSaving] = useState(false);
    const [isOpen, setIsOpen] = useState(false);

    // Garante que o estado do formulário é atualizado se o prop do provedor mudar
    useEffect(() => {
        setDetails(provider.details || {});
        setName(provider.name || '');
    }, [provider]);

    const handleDetailChange = (key: keyof ProviderDetails, value: any) => {
        setDetails(prev => ({ ...prev, [key]: value }));
    };

    const handleSave = async () => {
        setIsSaving(true);
        const toastId = toast.loading("A guardar alterações...");
        try {
            await callFunction('UPDATE_PROVIDER_DETAILS', { providerId: provider.id, details: { ...details, name } });
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
                        <Label htmlFor="appName">Nome do Aplicativo</Label>
                        <Input id="appName" value={details.appName || ''} onChange={(e) => handleDetailChange('appName', e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="apiToken">Token da API (SGP)</Label>
                        <Input id="apiToken" value={details.apiToken || ''} onChange={(e) => handleDetailChange('apiToken', e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="systemUrl">URL do Sistema (SGP)</Label>
                        <Input id="systemUrl" value={details.systemUrl || ''} onChange={(e) => handleDetailChange('systemUrl', e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="systemType">Tipo de Sistema</Label>
                        <Input id="systemType" value={details.systemType || ''} onChange={(e) => handleDetailChange('systemType', e.target.value)} />
                    </div>
                    <div className="space-y-2 md:col-span-2">
                        <Label htmlFor="apiUrl">URL do Proxy/API (usado pelo app)</Label>
                        <Input id="apiUrl" placeholder="https://api.seudominio.com" value={details.apiUrl || ''} onChange={(e) => handleDetailChange('apiUrl', e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="city">Cidade</Label>
                        <Input id="city" value={details.city || ''} onChange={(e) => handleDetailChange('city', e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="state">Estado</Label>
                        <Input id="state" value={details.state || ''} onChange={(e) => handleDetailChange('state', e.target.value)} />
                    </div>
                    <div className="flex flex-col gap-2 pt-2">
                        <div className="flex items-center space-x-2">
                            <Switch id="hasAndroidApp" checked={details.hasAndroidApp} onCheckedChange={(c) => handleDetailChange('hasAndroidApp', c)} />
                            <Label htmlFor="hasAndroidApp">Habilitar app Android</Label>
                        </div>
                        <div className="flex items-center space-x-2">
                            <Switch id="hasIosApp" checked={details.hasIosApp} onCheckedChange={(c) => handleDetailChange('hasIosApp', c)} />
                            <Label htmlFor="hasIosApp">Habilitar app iPhone</Label>
                        </div>
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
