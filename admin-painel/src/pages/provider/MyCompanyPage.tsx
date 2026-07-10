import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Loader2 } from 'lucide-react';
import { subscribeProvider } from '@/features/providers/providerService';
import { useApi } from '@/hooks/useApi';

interface CompanyDetails {
    razaoSocial?: string;
    nomeFantasia?: string;
    cnpj?: string;
    email?: string;
    telefone?: string;
}

export default function MyCompanyPage() {
    const { user, providerId } = useAuth();
    const { callFunction } = useApi();
    const [details, setDetails] = useState<CompanyDetails>({});
    const [loading, setLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);

    useEffect(() => {
        if (!providerId) return;

        const unsubscribe = subscribeProvider(providerId, (provider) => {
            if (provider) setDetails((provider.details as CompanyDetails) || {});
            setLoading(false);
        });

        return () => unsubscribe();
    }, [providerId]);

    const handleDetailChange = (key: keyof CompanyDetails, value: string) => {
        setDetails(prev => ({ ...prev, [key]: value }));
    };

    const handleSave = useCallback(async () => {
        if (!providerId || !user) {
            toast.error("Não foi possível salvar. Tente fazer login novamente.");
            return;
        }

        setIsSaving(true);
        try {
            await callFunction('UPDATE_PROVIDER_DETAILS', { providerId, details: { ...details } });
        } catch (error) {
            console.error("Falha ao salvar empresa", error);
        } finally {
            setIsSaving(false);
        }
    }, [providerId, user, details, callFunction]);

    if (loading) {
        return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin h-8 w-8" /></div>;
    }

    return (
        <div className="grid grid-cols-1 gap-4 xl:grid-cols-[1fr_340px]">
            <Card className="overflow-hidden">
                <CardHeader className="border-b border-[#EEF0F4]">
                    <CardTitle>Dados da empresa</CardTitle>
                    <p className="mt-0.5 text-[12.5px] text-[#687181]">Informações exibidas no aplicativo e nas faturas.</p>
                </CardHeader>
                <CardContent className="p-[18px]">
                    <div className="grid gap-3.5 sm:grid-cols-2">
                        <div className="space-y-1.5">
                            <Label htmlFor="razaoSocial">Razão social</Label>
                            <Input id="razaoSocial" value={details.razaoSocial || ''} onChange={(e) => handleDetailChange('razaoSocial', e.target.value)} />
                        </div>
                        <div className="space-y-1.5">
                            <Label htmlFor="nomeFantasia">Nome fantasia</Label>
                            <Input id="nomeFantasia" value={details.nomeFantasia || ''} onChange={(e) => handleDetailChange('nomeFantasia', e.target.value)} />
                        </div>
                        <div className="space-y-1.5">
                            <Label htmlFor="cnpj">CNPJ</Label>
                            <Input id="cnpj" className="font-mono" value={details.cnpj || ''} onChange={(e) => handleDetailChange('cnpj', e.target.value)} />
                        </div>
                        <div className="space-y-1.5">
                            <Label htmlFor="telefone">WhatsApp</Label>
                            <Input id="telefone" value={details.telefone || ''} onChange={(e) => handleDetailChange('telefone', e.target.value)} />
                        </div>
                        <div className="space-y-1.5 sm:col-span-2">
                            <Label htmlFor="email">E-mail de contato</Label>
                            <Input id="email" type="email" value={details.email || ''} onChange={(e) => handleDetailChange('email', e.target.value)} />
                        </div>
                    </div>
                </CardContent>
                <div className="flex justify-end border-t border-[#EEF0F4] px-[18px] py-3.5">
                    <Button onClick={handleSave} disabled={isSaving}>
                        {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Salvar alterações
                    </Button>
                </div>
            </Card>

            <div className="flex flex-col gap-3.5">
                <Card className="p-[18px]">
                    <div className="mb-3 flex items-center justify-between">
                        <div className="text-[13.5px] font-semibold text-[#1A2233]">Integração SGP</div>
                        <span className="inline-flex items-center gap-1.5 text-[11.5px] font-semibold text-emerald-700">
                            <span className="h-1.5 w-1.5 rounded-full bg-current" />
                            Conectado
                        </span>
                    </div>
                    <div className="grid grid-cols-2 gap-2 text-[12px]">
                        <span className="text-[#98A1B1]">Última sincronização</span>
                        <span className="text-right text-[#4A5364]">hoje às 14:48</span>
                        <span className="text-[#98A1B1]">Ambiente</span>
                        <span className="text-right text-[#4A5364]">Produção</span>
                    </div>
                </Card>
                <Card className="p-[18px]">
                    <div className="mb-3 flex items-center justify-between">
                        <div className="text-[13.5px] font-semibold text-[#1A2233]">Plano da plataforma</div>
                        <span className="rounded-md bg-primary/10 px-2 py-0.5 text-[11.5px] font-semibold text-primary">Enterprise</span>
                    </div>
                    <div className="mb-2 text-[12px] text-[#98A1B1]">Clientes sincronizados</div>
                    <div className="mb-2 h-2 overflow-hidden rounded-full bg-[#EEF1F6]">
                        <div className="h-full w-[48%] rounded-full bg-primary" />
                    </div>
                    <div className="text-[12px] text-[#687181]">Renovação em 01/09/2026</div>
                </Card>
            </div>
        </div>
    );
}
