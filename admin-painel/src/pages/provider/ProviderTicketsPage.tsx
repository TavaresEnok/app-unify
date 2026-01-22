import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { collection, query, where, getDocs, orderBy } from "firebase/firestore";
import { db } from "@/firebase/config";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from '@/components/ui/badge';
import { Loader2, MessageSquare, Search, RefreshCw } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import AddTicketDialog from '@/components/AddTicketDialog';
import EmptyState from '@/components/EmptyState';

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
    const [tickets, setTickets] = useState<Ticket[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [searchTerm, setSearchTerm] = useState('');
    const [hasFetched, setHasFetched] = useState(false);

    const loadTickets = async () => {
        if (!providerId) {
            setError("Provider ID não encontrado");
            return;
        }

        setLoading(true);
        setError(null);

        try {
            const ticketsRef = collection(db, 'tickets');
            const q = query(ticketsRef, where('providerId', '==', providerId));
            const snapshot = await getDocs(q);

            const ticketList: Ticket[] = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            })) as Ticket[];

            setTickets(ticketList);
            setHasFetched(true);
        } catch (err: any) {
            console.error("Erro ao carregar tickets:", err);
            setError(err.message || "Erro desconhecido");
        } finally {
            setLoading(false);
        }
    };

    // Carrega apenas uma vez quando o providerId está disponível
    useEffect(() => {
        if (providerId && !hasFetched && !loading) {
            loadTickets();
        }
    }, [providerId]);

    const filteredTickets = tickets.filter(t =>
        t.subject?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        t.createdBy?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const getStatusVariant = (status: Ticket['status']) => {
        switch (status) {
            case 'Aberto': return 'default';
            case 'Em Andamento': return 'secondary';
            case 'Fechado': return 'outline';
            default: return 'default';
        }
    };

    return (
        <Card>
            <CardHeader>
                <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                    <div>
                        <CardTitle>Tickets de Suporte</CardTitle>
                        <CardDescription>Gerencie as solicitações de suporte dos seus clientes.</CardDescription>
                    </div>
                    <div className="flex items-center gap-2 w-full sm:w-auto">
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
                    </div>
                </div>
            </CardHeader>
            <CardContent>
                {loading && (
                    <div className="flex justify-center items-center py-12">
                        <Loader2 className="animate-spin h-8 w-8" />
                    </div>
                )}

                {error && (
                    <div className="bg-red-500/10 border border-red-500/50 rounded-lg p-4 mb-4">
                        <p className="text-red-500 font-medium">Erro: {error}</p>
                        <Button variant="outline" size="sm" className="mt-2" onClick={loadTickets}>
                            Tentar Novamente
                        </Button>
                    </div>
                )}

                {!loading && !error && filteredTickets.length === 0 && (
                    <EmptyState
                        icon={MessageSquare}
                        title="Nenhum ticket encontrado"
                        description={hasFetched ? "A lista está vazia." : "Clique em Atualizar para carregar."}
                    />
                )}

                {!loading && filteredTickets.length > 0 && (
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
                            {filteredTickets.map((ticket) => (
                                <TableRow
                                    key={ticket.id}
                                    className="cursor-pointer hover:bg-muted/50"
                                    onClick={() => navigate(`/provedor/tickets/${ticket.id}`)}
                                >
                                    <TableCell className="font-medium text-xs text-muted-foreground">
                                        {ticket.id.substring(0, 8)}
                                    </TableCell>
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
        </Card>
    );
}
