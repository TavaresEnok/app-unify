// admin-painel/src/pages/ProvidersPage.tsx - VERSÃO CORRIGIDA
import { useState, useEffect, useMemo, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Card, CardHeader, CardTitle } from "@/components/ui/card";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogHeader, AlertDialogTitle, AlertDialogFooter, AlertDialogTrigger, AlertDialogDescription } from "@/components/ui/alert-dialog";
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Trash2, Loader2, Search, Settings, ServerCrash } from 'lucide-react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import AddProviderDialog from '@/components/AddProviderDialog.tsx';
import EditProviderDialog from '@/components/EditProviderDialog.tsx';
import EmptyState from '@/components/EmptyState.tsx';
import DataTable from '@/components/DataTable';
import StatusBadge from '@/components/StatusBadge';
import { subscribeProviders } from '@/features/providers/providerService';
import { useApi } from '@/hooks/useApi';

interface Provider {
    id: string;
    name?: string;
    plan?: string;
    clientCount?: number;
    appStatus?: string;
    lastBuild?: string;
    cnpj?: string;
}

const ITEMS_PER_PAGE = 10;

export default function ProvidersPage() {
    const navigate = useNavigate();
    const { user, userRole } = useAuth();
    const { callFunction } = useApi();
    const [providers, setProviders] = useState<Provider[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentPage, setCurrentPage] = useState(1);

    const fetchProviders = useCallback(() => {
        if (!user || userRole !== 'superAdmin') {
            setLoading(false);
            return () => {};
        }
        setLoading(true);
        const unsubscribe = subscribeProviders((items) => {
            setProviders(items as Provider[]);
            setLoading(false);
        }, () => {
            toast.error("Falha ao carregar provedores.");
            setLoading(false);
        });
        return unsubscribe;
    }, [user, userRole]);

    useEffect(() => {
        const unsubscribe = fetchProviders();
        return () => unsubscribe();
    }, [fetchProviders]);

    const filteredProviders = useMemo(() => providers.filter(p =>
        p.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.id.toLowerCase().includes(searchTerm.toLowerCase())
    ), [providers, searchTerm]);
    
    const pageCount = Math.ceil(filteredProviders.length / ITEMS_PER_PAGE);
    const paginatedProviders = filteredProviders.slice((currentPage - 1) * ITEMS_PER_PAGE, currentPage * ITEMS_PER_PAGE);

    const initialsFor = (provider: Provider) => {
        const source = provider.name || provider.id;
        return source
            .split(/\s+/)
            .filter(Boolean)
            .slice(0, 2)
            .map(part => part[0])
            .join('')
            .toUpperCase();
    };

    const paletteFor = (index: number) => {
        const palettes = [
            ["#10324B", "#7FC7F0"],
            ["#243B22", "#91D68C"],
            ["#3A2E10", "#F0C36A"],
            ["#301C47", "#C9A7FF"],
            ["#3B1F25", "#F2A6B3"],
        ];
        return palettes[index % palettes.length];
    };

    const providerStatus = (provider: Provider) => provider.appStatus || "Publicado";

    const handleDelete = async (providerToDelete: Provider) => {
        if (!user) return;
        
        try {
            await callFunction('DELETE_PROVIDER', { providerId: providerToDelete.id });
        } catch (error: any) {
            console.error("Falha ao apagar provedor", error);
        }
    };

    if (loading) return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin" /></div>;
    if (userRole !== 'superAdmin') return <Card><CardHeader><CardTitle>Acesso Negado</CardTitle></CardHeader></Card>;

    return (
        <TooltipProvider>
            <DataTable<Provider>
                title="Provedores"
                description={`${filteredProviders.length} provedores ativos na plataforma`}
                actions={(
                    <>
                        <div className="relative w-full sm:w-64">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder="Buscar por nome ou ID..."
                                className="pl-8 w-full"
                                value={searchTerm}
                                onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
                            />
                        </div>
                        <AddProviderDialog onUpdate={fetchProviders} />
                    </>
                )}
                columns={[
                    { label: "Provedor" },
                    { label: "Plano" },
                    { label: "Clientes" },
                    { label: "Status do app" },
                    { label: "Última build" },
                    { label: "" },
                ]}
                gridTemplate="2.1fr .8fr .7fr 1fr 1fr 120px"
                rows={paginatedProviders}
                getRowKey={(provider) => provider.id}
                minWidth="860px"
                empty={(
                        <EmptyState 
                            icon={ServerCrash}
                            title="Nenhum provedor encontrado"
                            description="Adicione um novo provedor para começar a gerir."
                        />
                )}
                renderRow={(p, index) => {
                    const palette = paletteFor(index);
                    return (
                                <div
                            className="grid items-center gap-x-3 border-b border-[#F2F4F7] px-[18px] py-[11px] transition-colors hover:bg-[#F8FAFC]"
                            style={{ gridTemplateColumns: "2.1fr .8fr .7fr 1fr 1fr 120px" }}
                                >
                                    <button type="button" onClick={() => navigate(`/provedores/${p.id}`)} className="flex min-w-0 items-center gap-[11px] text-left">
                                        <span
                                            className="grid h-8 w-8 shrink-0 place-items-center rounded-lg text-[11.5px] font-bold"
                                    style={{ backgroundColor: palette[0], color: palette[1] }}
                                        >
                                            {initialsFor(p)}
                                        </span>
                                        <span className="min-w-0">
                                            <span className="block truncate text-[13px] font-semibold text-[#1A2233]">{p.name || "Sem nome"}</span>
                                            <span className="block truncate font-mono text-[10.5px] text-[#98A1B1]">{p.cnpj || p.id}</span>
                                        </span>
                                    </button>
                                    <span className="w-fit rounded-md bg-[#EEF0F4] px-2 py-0.5 text-[12px] font-semibold text-[#4A5364]">{p.plan || "Standard"}</span>
                                    <span className="font-mono text-[12px] text-[#2A3242]">{p.clientCount ?? "-"}</span>
                            <StatusBadge status={providerStatus(p)} />
                                    <span className="font-mono text-[11.5px] text-[#687181]">{p.lastBuild || "-"}</span>
                                    <div className="flex justify-end gap-2">
                                                <Tooltip>
                                            <TooltipTrigger asChild><Button variant="outline" size="icon" onClick={() => navigate(`/provedores/${p.id}`)}><Settings className="h-4 w-4" /></Button></TooltipTrigger>
                                                    <TooltipContent><p>Personalizar App</p></TooltipContent>
                                                </Tooltip>
                                                <EditProviderDialog provider={p} onUpdate={fetchProviders} />
                                                <AlertDialog>
                                                    <Tooltip>
                                                        <TooltipTrigger asChild><AlertDialogTrigger asChild><Button variant="destructive" size="sm"><Trash2 className="h-4 w-4" /></Button></AlertDialogTrigger></TooltipTrigger>
                                                        <TooltipContent><p>Apagar Provedor</p></TooltipContent>
                                                    </Tooltip>
                                                    <AlertDialogContent>
                                                        <AlertDialogHeader>
                                                            <AlertDialogTitle>Tem a certeza?</AlertDialogTitle>
                                                            <AlertDialogDescription>Esta ação é irreversível e irá apagar o provedor e todos os seus utilizadores de painel associados.</AlertDialogDescription>
                                                        </AlertDialogHeader>
                                                        <AlertDialogFooter>
                                                            <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                                            <AlertDialogAction onClick={() => handleDelete(p)}>Sim, apagar</AlertDialogAction>
                                                        </AlertDialogFooter>
                                                    </AlertDialogContent>
                                                </AlertDialog>
                                            </div>
                                </div>
                    );
                }}
                footer={filteredProviders.length > 0 && (
                    <div className="flex items-center justify-between">
                        <span className="text-[12px] text-[#98A1B1]">Exibindo {paginatedProviders.length} de {filteredProviders.length} provedores</span>
                        <div className="flex items-center gap-2">
                            <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}>Anterior</Button>
                            <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.min(pageCount, p + 1))} disabled={currentPage === pageCount || pageCount === 0}>Próxima</Button>
                        </div>
                    </div>
                )}
            />
        </TooltipProvider>
    );
};
