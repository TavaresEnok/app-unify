import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Loader2, UserX, Search, RefreshCw, ChevronRight } from 'lucide-react';
import EmptyState from '@/components/EmptyState';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import DataTable from '@/components/DataTable';
import StatusBadge from '@/components/StatusBadge';
import { useApi } from '@/hooks/useApi';

interface SgpClient {
    id: number;
    nome: string;
    cpfcnpj: string;
    contratos: { id: number; status: string }[];
    plano?: string;
    cidade?: string;
}

const ITEMS_PER_PAGE = 25;

// Hook para "atrasar" a busca e não fazer uma requisição a cada tecla digitada
function useDebounce(value: string, delay: number) {
    const [debouncedValue, setDebouncedValue] = useState(value);
    useEffect(() => {
        const handler = setTimeout(() => {
            setDebouncedValue(value);
        }, delay);
        return () => {
            clearTimeout(handler);
        };
    }, [value, delay]);
    return debouncedValue;
}

export default function ProviderClientsPage() {
    const navigate = useNavigate();
    const { user, providerId } = useAuth();
    const { callFunction } = useApi();
    const [clients, setClients] = useState<SgpClient[]>([]);
    const [loading, setLoading] = useState(true);
    const [isSyncing, setIsSyncing] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentPage, setCurrentPage] = useState(1);
    const [totalClients, setTotalClients] = useState(0);

    const debouncedSearchTerm = useDebounce(searchTerm, 300); // Aguarda 300ms após o usuário parar de digitar
    const pageCount = Math.ceil(totalClients / ITEMS_PER_PAGE);

    const callProxy = useCallback(async (action: 'sync' | 'get', page = 1, search = '') => {
        if (!providerId || !user) return;

        const isSyncAction = action === 'sync';
        if (isSyncAction) {
            setIsSyncing(true);
            toast.info("Iniciando sincronização... Isso pode levar vários minutos. Por favor, aguarde.");
        } else {
            setLoading(true);
        }

        const offset = (page - 1) * ITEMS_PER_PAGE;
        try {
            const result = await callFunction('SGP_API_PROXY', {
                providerId,
                action,
                params: isSyncAction ? {
                        limit: 100,
                        offset: 0,
                        contrato_status: 1,
                        omitir_titulos: 1
                } : {
                        limit: ITEMS_PER_PAGE,
                        offset: offset,
                        searchTerm: search
                },
            });

            if (isSyncAction) {
                toast.success("Sincronização concluída!", { description: `${result.count || 0} clientes foram salvos.` });
                setSearchTerm('');
                setCurrentPage(1);
            } else {
                setClients((result.clientes || []) as unknown as SgpClient[]);
                setTotalClients(result.paginacao?.total || 0);
            }
        } catch (error: any) {
            console.error("Falha na operação de clientes", error);
        } finally {
            setLoading(false);
            setIsSyncing(false);
        }
    }, [providerId, user, callFunction]);

    // Efeito para buscar os clientes do cache ao carregar ou mudar de página/busca
    useEffect(() => {
        if (!isSyncing) {
            callProxy('get', currentPage, debouncedSearchTerm);
        }
    }, [currentPage, debouncedSearchTerm, callProxy, isSyncing]);

    // Handler para o input de busca
    const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        setSearchTerm(event.target.value);
        setCurrentPage(1); // Volta para a primeira página sempre que uma nova busca é feita
    };

    const getContractSummary = (client: SgpClient) => {
        if (!client.contratos?.length) return "-";
        return client.contratos.map((contract: any) => contract.id).join(', ');
    };

    const getClientStatus = (client: SgpClient) => {
        const firstContract = client.contratos?.[0] as any;
        return firstContract?.status || "Ativo";
    };

    if (loading && clients.length === 0) {
        return (
            <div className="flex flex-col justify-center items-center h-full text-center">
                <Loader2 className="animate-spin h-8 w-8 mb-4" />
                <p className="text-lg font-semibold">Carregando clientes do cache...</p>
            </div>
        );
    }

    return (
        <DataTable<SgpClient>
            title="Clientes"
            description={totalClients > 0 ? `Encontrados ${totalClients} clientes no total.` : "Nenhum cliente sincronizado."}
            actions={(
                <>
                        <div className="relative flex-grow sm:flex-grow-0 sm:w-64">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder={`Pesquisar em ${totalClients} clientes...`}
                                className="pl-8 w-full"
                                value={searchTerm}
                                onChange={handleSearchChange}
                            />
                        </div>
                        <Button onClick={() => callProxy('sync')} disabled={isSyncing} variant="outline">
                        {isSyncing ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <RefreshCw className="mr-2 h-4 w-4" />}
                            Sincronizar
                        </Button>
                </>
            )}
            columns={[
                { label: "Cliente" },
                { label: "Contrato" },
                { label: "CPF/CNPJ" },
                { label: "Status" },
                { label: "Cidade" },
                { label: "" },
            ]}
            gridTemplate="2.2fr .9fr 1.2fr .9fr 1fr 32px"
            rows={!loading ? clients : []}
            getRowKey={(client) => String(client.id)}
            minWidth="850px"
            empty={loading ? (
                <div className="flex h-64 items-center justify-center"><Loader2 className="h-8 w-8 animate-spin" /></div>
            ) : (
                    <EmptyState
                        icon={UserX}
                        title={searchTerm ? "Nenhum resultado para sua busca" : "Nenhum Cliente no Cache"}
                        description={searchTerm ? `Não foram encontrados clientes com o termo "${searchTerm}". Limpe a busca para ver todos.` : "Clique em 'Sincronizar' para buscar os dados do SGP."}
                    />
            )}
            renderRow={(client) => (
                            <button
                                type="button"
                    className="grid w-full items-center gap-x-3 border-b border-[#F2F4F7] px-[18px] py-[11px] text-left transition-colors hover:bg-[#F8FAFC]"
                    style={{ gridTemplateColumns: "2.2fr .9fr 1.2fr .9fr 1fr 32px" }}
                                    onClick={() => navigate(`/provedor/clientes/${client.cpfcnpj}`)}
                                >
                                <span className="min-w-0">
                                    <span className="block truncate text-[13px] font-semibold text-[#1A2233]">{client.nome}</span>
                                    <span className="block font-mono text-[10.5px] text-[#98A1B1]">ID {client.id}</span>
                                </span>
                                <span className="truncate font-mono text-[12px] text-[#4A5364]">{getContractSummary(client)}</span>
                                <span className="truncate font-mono text-[12px] text-[#4A5364]">{client.cpfcnpj}</span>
                    <StatusBadge status={getClientStatus(client)} />
                                <span className="truncate text-[12.5px] text-[#687181]">{client.cidade || "-"}</span>
                                <ChevronRight className="h-3.5 w-3.5 justify-self-end text-[#B9C0CC]" />
                            </button>
            )}
            footer={pageCount > 1 && (
                <div className="flex items-center justify-between">
                    <span className="text-[12px] text-[#98A1B1]">
                        Página {currentPage} de {pageCount}
                    </span>
                    <div className="flex items-center gap-2">
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1 || loading}>Anterior</Button>
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.min(pageCount, p + 1))} disabled={currentPage === pageCount || loading}>Próxima</Button>
                    </div>
                </div>
            )}
        />
    );
}
