import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Loader2 } from 'lucide-react';
import { subscribeProvider } from '@/features/providers/providerService';
import { useApi } from '@/hooks/useApi';
import { fetchProviderClients } from '@/shared/api/clients';
import { companyDetailsFromProvider, companyDetailsPayload, type CompanyDetails } from '@/features/provider-settings/companyDetails';

interface IntegrationStatus {
    total: number;
    lastSyncedAt: string | null;
}

export default function MyCompanyPage() {
    const { user, providerId } = useAuth();
    const { callFunction } = useApi();
    const [details, setDetails] = useState<CompanyDetails>({});
    const [loading, setLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);
    const dirtyRef = useRef(false);
    const [integration, setIntegration] = useState<IntegrationStatus | null>(null);

    useEffect(() => {
        if (!providerId) return;

        const unsubscribe = subscribeProvider(providerId, (provider) => {
            // Não sobrescreve o que a pessoa está digitando com a leitura periódica.
            if (provider && !dirtyRef.current) setDetails(companyDetailsFromProvider(provider.details));
            setLoading(false);
        }, () => {
            toast.error('Não foi possível carregar os dados da empresa.');
            setLoading(false);
        });

        return () => unsubscribe();
    }, [providerId]);

    useEffect(() => {
        if (!providerId) return;
        let alive = true;
        fetchProviderClients(providerId, { page: 1, limit: 1 })
            .then((data) => { if (alive) setIntegration({ total: data.total, lastSyncedAt: data.lastSyncedAt }); })
            .catch(() => { if (alive) setIntegration(null); });
        return () => { alive = false; };
    }, [providerId]);

    const handleDetailChange = (key: keyof CompanyDetails, value: string) => {
        dirtyRef.current = true;
        setDetails(prev => ({ ...prev, [key]: value }));
    };

    const handleSave = useCallback(async () => {
        if (!providerId || !user) {
            toast.error("Não foi possível salvar. Tente fazer login novamente.");
            return;
        }

        setIsSaving(true);
        try {
            await callFunction('UPDATE_PROVIDER_DETAILS', { providerId, details: companyDetailsPayload(details) });
            dirtyRef.current = false;
        } catch (error) {
            // useApi já mostra o erro em um toast.
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
                {/* Status derivado da configuração real do provedor. Não afirmamos
                    conectividade ao vivo (o painel não faz health-check do SGP). */}
                <Card className="p-[18px]">
                    <div className="mb-3 flex items-center justify-between">
                        <div className="text-[13.5px] font-semibold text-[#1A2233]">Integração com o sistema (ERP)</div>
                        {integration && integration.total > 0 ? (
                            <span className="inline-flex items-center gap-1.5 text-[11.5px] font-semibold text-emerald-700">
                                <span className="h-1.5 w-1.5 rounded-full bg-current" />
                                Conectada
                            </span>
                        ) : (
                            <span className="inline-flex items-center gap-1.5 text-[11.5px] font-semibold text-[#98A1B1]">
                                <span className="h-1.5 w-1.5 rounded-full bg-current" />
                                {integration ? 'Sem clientes sincronizados' : 'Sem informação'}
                            </span>
                        )}
                    </div>
                    <div className="grid grid-cols-2 gap-2 text-[12px]">
                        <span className="text-[#98A1B1]">Clientes sincronizados</span>
                        <span className="text-right text-[#4A5364]">{integration ? integration.total : '—'}</span>
                        <span className="text-[#98A1B1]">Última sincronização</span>
                        <span className="text-right text-[#4A5364]">
                            {integration?.lastSyncedAt ? new Date(integration.lastSyncedAt).toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' }) : '—'}
                        </span>
                    </div>
                    <p className="mt-3 text-[11.5px] text-[#687181]">A conexão com o ERP é configurada pela equipe da plataforma.</p>
                </Card>
            </div>
        </div>
    );
}
