import { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Timestamp } from "firebase/firestore";
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Loader2, Search, MessageSquareOff, Trash2, ChevronRight } from 'lucide-react';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import EmptyState from '@/components/EmptyState.tsx';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog";
import { Button } from '@/components/ui/button';
import DataTable from '@/components/DataTable';
import StatusBadge from '@/components/StatusBadge';
import { useApi } from '@/hooks/useApi';

interface Ticket {
    id: string;
    subject: string;
    providerName: string;
    status: 'Aberto' | 'Em Andamento' | 'Fechado';
    updatedAt?: Timestamp;
}

export default function AdminTicketsPage() {
    const navigate = useNavigate();
    const { user, userRole } = useAuth();
    const { callFunction } = useApi();
    const [tickets, setTickets] = useState<Ticket[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState('Todos');

    const fetchTickets = useCallback(async () => {
        if (userRole !== 'superAdmin' || !user) {
            setLoading(false);
            return;
        }

        setLoading(true);
        try {
            const result = await callFunction('GET_ALL_TICKETS', {});
            setTickets(result as Ticket[]);
        } catch (error) {
            console.error("Falha ao carregar tickets", error);
        } finally {
            setLoading(false);
        }
    }, [userRole, user, callFunction]);

    useEffect(() => {
        void fetchTickets();
    }, [fetchTickets]);

    const handleDelete = async (ticketId: string) => {
        if (!user) return;
        try {
            await callFunction('DELETE_TICKET', { ticketId });
            setTickets(prevTickets => prevTickets.filter(t => t.id !== ticketId));
        } catch (error: any) {
            console.error("Falha ao apagar ticket", error);
        }
    };

    const filteredTickets = useMemo(() => {
        return tickets.filter(ticket => {
            const matchesStatus = statusFilter === 'Todos' || ticket.status === statusFilter;
            const matchesSearch = (ticket.subject?.toLowerCase() || '').includes(searchTerm.toLowerCase()) || (ticket.providerName?.toLowerCase() || '').includes(searchTerm.toLowerCase());
            return matchesStatus && matchesSearch;
        });
    }, [tickets, searchTerm, statusFilter]);

    const formatUpdatedAt = (ticket: Ticket) => {
        if (!ticket.updatedAt) return 'Data inválida';
        return format(ticket.updatedAt.toDate(), "dd/MM/yyyy 'às' HH:mm", { locale: ptBR });
    };

    if (loading) {
        return <div className="flex h-full items-center justify-center"><Loader2 className="h-8 w-8 animate-spin" /></div>;
    }

    return (
        <DataTable<Ticket>
            title="Todos os tickets"
            description="Gerencie os tickets de todos os provedores da plataforma."
            actions={(
                <>
                    <div className="relative w-full sm:w-[240px]">
                        <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                        <Input
                            type="search"
                            placeholder="Buscar por assunto..."
                            className="pl-8"
                            value={searchTerm}
                            onChange={(event) => setSearchTerm(event.target.value)}
                        />
                    </div>
                    <Select value={statusFilter} onValueChange={setStatusFilter}>
                        <SelectTrigger className="w-full sm:w-[170px]"><SelectValue placeholder="Filtrar por status" /></SelectTrigger>
                        <SelectContent>
                            <SelectItem value="Todos">Todos os status</SelectItem>
                            <SelectItem value="Aberto">Aberto</SelectItem>
                            <SelectItem value="Em Andamento">Em andamento</SelectItem>
                            <SelectItem value="Fechado">Fechado</SelectItem>
                        </SelectContent>
                    </Select>
                </>
            )}
            columns={[
                { label: "Status" },
                { label: "Assunto" },
                { label: "Provedor" },
                { label: "Prioridade" },
                { label: "Atualização" },
                { label: "" },
            ]}
            gridTemplate="130px 2.2fr 1.2fr .8fr 1fr 88px"
            rows={filteredTickets}
            getRowKey={(ticket) => ticket.id}
            minWidth="920px"
            empty={(
                    <EmptyState icon={MessageSquareOff} title="Nenhum ticket encontrado" description="Não há tickets que correspondam aos filtros atuais." />
            )}
            renderRow={(ticket) => (
                            <div
                    className="grid items-center gap-x-3 border-b border-[#F2F4F7] px-[18px] py-[11px] transition-colors hover:bg-[#F8FAFC]"
                    style={{ gridTemplateColumns: "130px 2.2fr 1.2fr .8fr 1fr 88px" }}
                            >
                    <StatusBadge status={ticket.status} />
                    <button type="button" onClick={() => navigate(`/tickets/${ticket.id}`)} className="min-w-0 text-left">
                        <span className="block truncate text-[13px] font-semibold text-[#1A2233]">{ticket.subject}</span>
                        <span className="block truncate font-mono text-[10.5px] text-[#98A1B1]">{ticket.id}</span>
                    </button>
                    <button type="button" onClick={() => navigate(`/tickets/${ticket.id}`)} className="truncate text-left text-[12.5px] text-[#4A5364]">
                        {ticket.providerName}
                    </button>
                    <StatusBadge status="Média" tone="gray" />
                    <span className="font-mono text-[11.5px] text-[#687181]">{formatUpdatedAt(ticket)}</span>
                    <div className="flex justify-end gap-2">
                        <Button variant="outline" size="icon" onClick={() => navigate(`/tickets/${ticket.id}`)} aria-label="Abrir ticket">
                            <ChevronRight className="h-4 w-4" />
                        </Button>
                        <AlertDialog>
                            <AlertDialogTrigger asChild>
                                <Button variant="destructive" size="icon" aria-label="Apagar ticket"><Trash2 className="h-4 w-4" /></Button>
                            </AlertDialogTrigger>
                            <AlertDialogContent>
                                <AlertDialogHeader>
                                    <AlertDialogTitle>Tem certeza absoluta?</AlertDialogTitle>
                                    <AlertDialogDescription>Esta ação não pode ser desfeita. Isto irá apagar permanentemente o ticket e todas as suas mensagens.</AlertDialogDescription>
                                </AlertDialogHeader>
                                <AlertDialogFooter>
                                    <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                    <AlertDialogAction onClick={() => handleDelete(ticket.id)}>Sim, apagar ticket</AlertDialogAction>
                                </AlertDialogFooter>
                            </AlertDialogContent>
                        </AlertDialog>
                    </div>
                            </div>
            )}
        />
    );
}
