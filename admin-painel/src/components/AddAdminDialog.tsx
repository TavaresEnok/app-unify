import { useState, useEffect } from "react";
import { Dialog, DialogContent,  DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { toast } from "sonner";
import { PlusCircle, Loader2 } from "lucide-react";
import { validatePassword, PASSWORD_STRENGTH_COLORS, PASSWORD_STRENGTH_LABELS } from "@/lib/passwordPolicy";
import { subscribeProviders } from "@/features/providers/providerService";
import { useApi } from "@/hooks/useApi";
import { getErrorMessage } from "@/shared/errors";

interface Provider { id: string; name: string; }

export default function AddAdminDialog({ onUpdate }: { onUpdate: () => void }) {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [role, setRole] = useState('');
    const [providerId, setProviderId] = useState('');
    const [providers, setProviders] = useState<Provider[]>([]);
    const [isSaving, setIsSaving] = useState(false);
    const [isOpen, setIsOpen] = useState(false);
    const { callFunction } = useApi();

    useEffect(() => {
        if (isOpen) {
            const unsubscribe = subscribeProviders((items) => {
                setProviders(items.map((provider) => ({ id: provider.id, name: provider.name })));
            });
            return () => unsubscribe();
        }
    }, [isOpen]);

    const handleSave = async () => {
        if (!email || !password || !role) { toast.error("Email, senha e permissão são obrigatórios."); return; }
        if (role === 'providerAdmin' && !providerId) { toast.error("Para um Admin de Provedor, é necessário selecionar o provedor."); return; }
        const pwValidation = validatePassword(password);
        if (!pwValidation.valid) {
            toast.error(`Senha inválida: ${pwValidation.errors.join(', ')}`);
            return;
        }
        setIsSaving(true);
        const toastId = toast.loading("Enviando pedido para criar utilizador...");
        try {
            await callFunction('CREATE_ADMIN_USER', {
                email,
                password,
                role: role as 'superAdmin' | 'providerAdmin',
                ...(providerId ? { providerId } : {}),
            });
            toast.success("Utilizador criado com sucesso!", { id: toastId });
            onUpdate();
            setIsOpen(false);
            setEmail(''); setPassword(''); setRole(''); setProviderId('');
        } catch (error) {
            toast.error(`Erro ao solicitar criação: ${getErrorMessage(error)}`, { id: toastId });
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <Dialog open={isOpen} onOpenChange={setIsOpen}>
            <DialogTrigger asChild><Button><PlusCircle className="mr-2 h-4 w-4" />Adicionar Utilizador</Button></DialogTrigger>
            <DialogContent>
                <DialogHeader><DialogTitle>Adicionar Novo Utilizador</DialogTitle></DialogHeader>
                <div className="grid gap-4 py-4">
                    <div className="space-y-2"><Label htmlFor="email">Email</Label><Input id="email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} /></div>
                    <div className="space-y-2">
                        <Label htmlFor="password">Senha</Label>
                        <Input id="password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
                        {password.length > 0 && (() => {
                            const v = validatePassword(password);
                            return (
                                <p className={`text-xs ${PASSWORD_STRENGTH_COLORS[v.strength]}`}>
                                    Força: {PASSWORD_STRENGTH_LABELS[v.strength]}
                                    {v.errors.length > 0 && ` — ${v.errors.join(', ')}`}
                                </p>
                            );
                        })()}
                    </div>
                    <div className="space-y-2"><Label>Permissão</Label>
                        <Select onValueChange={setRole} value={role}>
                            <SelectTrigger><SelectValue placeholder="Selecione a permissão" /></SelectTrigger>
                            <SelectContent>
                                <SelectItem value="superAdmin">Super Admin</SelectItem>
                                <SelectItem value="providerAdmin">Admin de Provedor</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                    {role === 'providerAdmin' && (
                        <div className="space-y-2"><Label>Provedor</Label>
                            <Select onValueChange={setProviderId} value={providerId}>
                                <SelectTrigger><SelectValue placeholder="Selecione o provedor" /></SelectTrigger>
                                <SelectContent>
                                    {providers.map(p => <SelectItem key={p.id} value={p.id}>{p.name}</SelectItem>)}
                                </SelectContent>
                            </Select>
                        </div>
                    )}
                </div>
                <DialogFooter>
                    <Button variant="outline" onClick={() => setIsOpen(false)}>Cancelar</Button>
                    <Button onClick={handleSave} disabled={isSaving}>{isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}Salvar</Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
