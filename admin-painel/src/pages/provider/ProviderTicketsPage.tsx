import { useState, useEffect, useMemo } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useApi } from '@/hooks/useApi';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from '@/components/ui/badge';
import { Loader2, MessageSquare, Search } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button'; // <--- IMPORT CORRIGIDO
import AddTicketDialog from '@/components/AddTicketDialog';
import EmptyState from '@/components/EmptyState';

interface Ticket {
    id: string;
    subject: string;
    createdBy: string; // Email do cliente ou CPF/CNPJ
    status: 'Aberto' | 'Em Andamento' | 'Fechado';
    updatedAt: { seconds: number; nanoseconds: number };
}

const ITEMS_PER_PAGE = 10;

export default function ProviderTicketsPage() {
    const navigate = useNavigate();
    // userRole e loading removidos daqui para resolver TS6133, pois são usados no useApi
    const { user, providerId } = useAuth(); 
    const { callFunction, loading: isApiLoading } = useApi();
    const [tickets, setTickets] = useState<Ticket[]>([]);
    const [isLoadingTickets, setIsLoadingTickets] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentPage, setCurrentPage] = useState(1);

    const fetchTickets = async () => {
        if (!providerId || !user) {
            setIsLoadingTickets(false);
            return;
        }
        setIsLoadingTickets(true);
        try {
            const result = await callFunction('GET_PROVIDER_TICKETS', { providerId });
            const formattedTickets: Ticket[] = (result?.tickets || []).map((t: any) => ({
                ...t,
                id: t.id,
                // Garantir o updatedAt no formato esperado
            }));
            setTickets(formattedTickets);
        } catch (error) {
            toast.error("Falha ao carregar a lista de tickets.");
        } finally {
            setIsLoadingTickets(false);
        }
    };

    useEffect(() => {
        fetchTickets();
    }, [providerId, user, callFunction]);

    const filteredTickets = useMemo(() => tickets.filter(t =>
        t.subject.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t.createdBy.toLowerCase().includes(searchTerm.toLowerCase())
    ), [tickets, searchTerm]);

    const pageCount = Math.ceil(filteredTickets.length / ITEMS_PER_PAGE);
    const paginatedTickets = filteredTickets.slice((currentPage - 1) * ITEMS_PER_PAGE, currentPage * ITEMS_PER_PAGE);

    const getStatusVariant = (status: Ticket['status']) => {
        switch (status) {
            case 'Aberto': return 'default';
            case 'Em Andamento': return 'secondary';
            case 'Fechado': return 'outline';
            default: return 'default';
        }
    };
    
    // Simulação da busca do nome do provedor (necessário para a prop providerName do AddTicketDialog)
    // Em um cenário real, você buscaria isso do Firestore ou do AuthContext.
    const mockProviderName = "Nome do Provedor"; 
    
    if (isLoadingTickets) {
        return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin" /></div>;
    }

    return (
        <Card>
            <CardHeader>
                <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                    <div>
                        <CardTitle>Tickets de Suporte</CardTitle>
                        <CardDescription>Gerencie as solicitações de suporte dos seus clientes.</CardDescription>
                    </div>
                    <div className="flex items-center gap-2 w-full sm:w-auto">
                        <div className="relative w-full sm:w-64">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder="Pesquisar por assunto ou cliente..."
                                className="pl-8 w-full"
                                value={searchTerm}
                                onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
                            />
                        </div>
                        {/* CORRIGIDO: Passando providerName e onTicketCreated */}
                        <AddTicketDialog 
                            providerName={mockProviderName} 
                            onTicketCreated={fetchTickets} 
                        />
                    </div>
                </div>
            </CardHeader>
            <CardContent>
                {filteredTickets.length === 0 ? (
                    <EmptyState
                        icon={MessageSquare}
                        title="Nenhum ticket encontrado"
                        description="Nenhum ticket corresponde à sua pesquisa ou a lista está vazia."
                    />
                ) : (
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>ID</TableHead>
                                <TableHead>Assunto</TableHead>
                                <TableHead>Cliente</TableHead>
                                <TableHead className="text-center">Status</TableHead>
                                <TableHead className="text-right">Última Atualização</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {paginatedTickets.map((ticket) => (
                                <TableRow 
                                    key={ticket.id} 
                                    className="cursor-pointer hover:bg-muted/50" 
                                    onClick={() => navigate(`/provedor/tickets/${ticket.id}`)}
                                >
                                    <TableCell className="font-medium text-xs text-muted-foreground">{ticket.id.substring(0, 8)}</TableCell>
                                    <TableCell className="font-medium">{ticket.subject}</TableCell>
                                    <TableCell>{ticket.createdBy}</TableCell>
                                    <TableCell className="text-center">
                                        <Badge variant={getStatusVariant(ticket.status)}>{ticket.status}</Badge>
                                    </TableCell>
                                    <TableCell className="text-right">
                                        {ticket.updatedAt ? new Date(ticket.updatedAt.seconds * 1000).toLocaleString('pt-BR') : 'N/A'}
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                )}
            </CardContent>
            {filteredTickets.length > 0 && (
                <div className="flex items-center justify-between px-6 py-4 border-t">
                    <span className="text-sm text-muted-foreground">A exibir {paginatedTickets.length} de {filteredTickets.length} tickets.</span>
                    <div className="flex items-center gap-2">
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}>Anterior</Button>
                        <span className="text-sm">Página {currentPage} de {pageCount > 0 ? pageCount : 1}</span>
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.min(pageCount, p + 1))} disabled={currentPage === pageCount || pageCount === 0}>Próxima</Button>
                    </div>
                </div>
            )}
        </Card>
    );
}
