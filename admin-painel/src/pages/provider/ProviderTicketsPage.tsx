import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { ChevronRight, Loader2, MessageSquare, Search, RefreshCw } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import AddTicketDialog from '@/components/AddTicketDialog';
import EmptyState from '@/components/EmptyState';
import DataTable from '@/components/DataTable';
import StatusBadge from '@/components/StatusBadge';
import { useApi } from '@/hooks/useApi';

interface Ticket {
    id: string;
    subject: string;
    createdBy: string;
    status: 'Aberto' | 'Em Andamento' | 'Fechado';
    updatedAt: { seconds: number; nanoseconds: number };
}

export default function ProviderTicketsPage() {
    const navigate = useNavigate();
    const { providerId } = useAuth();
    const { callFunction } = useApi();
    const [tickets, setTickets] = useState<Ticket[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [searchTerm, setSearchTerm] = useState('');

    const loadTickets = useCallback(async () => {
        if (!providerId) {
            setError("Provider ID não encontrado");
            return;
        }

        setLoading(true);
        setError(null);

        try {
            const result = await callFunction('GET_PROVIDER_TICKETS', { providerId });
            setTickets(result as unknown as Ticket[]);
        } catch (err: any) {
            console.error("Erro ao carregar tickets:", err);
            setError(err.message || "Erro desconhecido");
        } finally {
            setLoading(false);
        }
    }, [providerId, callFunction]);

    // Carrega apenas uma vez quando o providerId está disponível
    useEffect(() => {
        if (providerId) void loadTickets();
    }, [providerId, loadTickets]);

    const filteredTickets = tickets.filter(t =>
        t.subject?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t.createdBy?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <DataTable<Ticket>
            title="Tickets de suporte"
            description="Gerencie as solicitações de suporte dos seus clientes."
            actions={(
                <>
                        <Button variant="outline" size="sm" onClick={loadTickets} disabled={loading}>
                            <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
                            Atualizar
                        </Button>
                        <div className="relative w-full sm:w-64">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder="Pesquisar..."
                                className="pl-8 w-full"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                        <AddTicketDialog providerName="Provedor" onTicketCreated={loadTickets} />
                </>
            )}
            columns={[
                { label: "Status" },
                { label: "Assunto" },
                { label: "Solicitante" },
                { label: "Prioridade" },
                { label: "Atualização" },
                { label: "" },
            ]}
            gridTemplate="130px 2.2fr 1.2fr .8fr 1fr 32px"
            rows={!loading && !error ? filteredTickets : []}
            getRowKey={(ticket) => ticket.id}
            minWidth="900px"
            empty={loading ? (
                <div className="flex items-center justify-center py-12">
                        <Loader2 className="animate-spin h-8 w-8" />
                    </div>
            ) : error ? (
                <div className="rounded-lg border border-red-200 bg-red-50 p-4">
                        <p className="text-red-500 font-medium">Erro: {error}</p>
                        <Button variant="outline" size="sm" className="mt-2" onClick={loadTickets}>
                            Tentar Novamente
                        </Button>
                    </div>
            ) : (
                    <EmptyState
                        icon={MessageSquare}
                        title="Nenhum ticket encontrado"
                        description="A lista está vazia."
                    />
            )}
            renderRow={(ticket) => (
                            <button
                                type="button"
                    className="grid w-full items-center gap-x-3 border-b border-[#F2F4F7] px-[18px] py-[11px] text-left transition-colors hover:bg-[#F8FAFC]"
                    style={{ gridTemplateColumns: "130px 2.2fr 1.2fr .8fr 1fr 32px" }}
                                    onClick={() => navigate(`/provedor/tickets/${ticket.id}`)}
                                >
                    <StatusBadge status={ticket.status} />
                    <span className="min-w-0">
                        <span className="block truncate text-[13px] font-semibold text-[#1A2233]">{ticket.subject}</span>
                        <span className="block font-mono text-[10.5px] text-[#98A1B1]">{ticket.id.substring(0, 8)}</span>
                    </span>
                                <span className="truncate text-[12.5px] text-[#4A5364]">{ticket.createdBy}</span>
                    <StatusBadge status="Média" tone="gray" />
                                <span className="font-mono text-[11.5px] text-[#687181]">
                                        {ticket.updatedAt ? new Date(ticket.updatedAt.seconds * 1000).toLocaleString('pt-BR') : 'N/A'}
                                </span>
                                <ChevronRight className="h-3.5 w-3.5 justify-self-end text-[#B9C0CC]" />
                            </button>
            )}
        />
    );
}
