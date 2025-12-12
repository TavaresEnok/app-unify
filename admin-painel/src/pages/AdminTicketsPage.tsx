import { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { doc, setDoc, onSnapshot, serverTimestamp, collection, Timestamp } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Loader2, Search, MessageSquareOff, Trash2 } from 'lucide-react';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import EmptyState from '@/components/EmptyState.tsx';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog";
import { Button } from '@/components/ui/button';

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
    const [tickets, setTickets] = useState<Ticket[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState('Todos');

    const fetchTickets = useCallback(() => {
        if (userRole !== 'superAdmin' || !user) { setLoading(false); return () => {}; }
        setLoading(true);
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);
        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                if (response.result?.tickets) { setTickets(response.result.tickets); } 
                else if (response.error) { toast.error(`Erro ao buscar tickets: ${response.error}`); }
                setLoading(false);
                unsubscribe();
            }
        });
        const triggerFunction = async () => {
            try {
                await setDoc(doc(db, 'function_requests', requestId), { type: 'GET_ALL_TICKETS', requesterUid: user.uid, createdAt: serverTimestamp() });
            } catch (error: any) {
                toast.error(`Falha ao solicitar tickets: ${error.message}`);
                setLoading(false);
                unsubscribe();
            }
        };
        triggerFunction();
        return unsubscribe;
    }, [userRole, user]);

    useEffect(() => {
        const unsubscribe = fetchTickets();
        return () => { if (unsubscribe) unsubscribe(); };
    }, [fetchTickets]);

    const handleDelete = async (ticketId: string) => {
        if (!user) return;
        const toastId = toast.loading("Apagando ticket...");
        const requestId = doc(collection(db, 'function_requests')).id;
        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'DELETE_TICKET',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: { ticketId }
            });
            // A remoção da UI será tratada pelo listener em tempo real, mas podemos ser otimistas
            setTickets(prevTickets => prevTickets.filter(t => t.id !== ticketId));
            toast.success("Ticket apagado.", { id: toastId });
        } catch (error: any) {
            toast.error(`Falha ao apagar ticket: ${error.message}`, { id: toastId });
        }
    };

    const filteredTickets = useMemo(() => {
        return tickets.filter(ticket => {
            const matchesStatus = statusFilter === 'Todos' || ticket.status === statusFilter;
            const matchesSearch = (ticket.subject?.toLowerCase() || '').includes(searchTerm.toLowerCase()) || (ticket.providerName?.toLowerCase() || '').includes(searchTerm.toLowerCase());
            return matchesStatus && matchesSearch;
        });
    }, [tickets, searchTerm, statusFilter]);
    
    const getStatusVariant = (status: Ticket['status']) => {
        switch (status) {
            case 'Aberto': return 'default';
            case 'Em Andamento': return 'secondary';
            case 'Fechado': return 'outline';
            default: return 'default';
        }
    };

    if (loading) { return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin h-8 w-8" /></div>; }

    return (
        <Card>
            <CardHeader>
                <CardTitle>Todos os Tickets</CardTitle>
                <CardDescription>Gerencie e responda a todos os tickets de suporte da plataforma.</CardDescription>
                <div className="flex flex-col sm:flex-row items-center gap-4 mt-4">
                    <div className="relative w-full flex-1">
                        <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                        <Input type="search" placeholder="Pesquisar por assunto ou provedor..." className="pl-8 w-full" value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
                    </div>
                    <Select value={statusFilter} onValueChange={setStatusFilter}>
                        <SelectTrigger className="w-full sm:w-[180px]"><SelectValue placeholder="Filtrar por status" /></SelectTrigger>
                        <SelectContent>
                            <SelectItem value="Todos">Todos os Status</SelectItem>
                            <SelectItem value="Aberto">Aberto</SelectItem>
                            <SelectItem value="Em Andamento">Em Andamento</SelectItem>
                            <SelectItem value="Fechado">Fechado</SelectItem>
                        </SelectContent>
                    </Select>
                </div>
            </CardHeader>
            <CardContent>
                {filteredTickets.length === 0 ? (
                    <EmptyState icon={MessageSquareOff} title="Nenhum ticket encontrado" description="Não há tickets que correspondam aos filtros atuais." />
                ) : (
                    <Table>
                        <TableHeader><TableRow><TableHead>Status</TableHead><TableHead>Assunto</TableHead><TableHead>Provedor</TableHead><TableHead>Última Atualização</TableHead><TableHead className="text-right">Ações</TableHead></TableRow></TableHeader>
                        <TableBody>
                            {filteredTickets.map((ticket) => (
                                <TableRow key={ticket.id}>
                                    <TableCell className="cursor-pointer" onClick={() => navigate(`/tickets/${ticket.id}`)}><Badge variant={getStatusVariant(ticket.status)}>{ticket.status}</Badge></TableCell>
                                    <TableCell className="font-medium cursor-pointer" onClick={() => navigate(`/tickets/${ticket.id}`)}>{ticket.subject}</TableCell>
                                    <TableCell className="cursor-pointer" onClick={() => navigate(`/tickets/${ticket.id}`)}>{ticket.providerName}</TableCell>
                                    <TableCell className="cursor-pointer" onClick={() => navigate(`/tickets/${ticket.id}`)}>
                                        {ticket.updatedAt ? format(ticket.updatedAt.toDate(), "dd/MM/yyyy 'às' HH:mm", { locale: ptBR }) : 'Data inválida'}
                                    </TableCell>
                                    <TableCell className="text-right">
                                        <AlertDialog>
                                            <AlertDialogTrigger asChild>
                                                <Button variant="destructive" size="icon"><Trash2 className="h-4 w-4" /></Button>
                                            </AlertDialogTrigger>
                                            <AlertDialogContent>
                                                <AlertDialogHeader>
                                                    <AlertDialogTitle>Tem a certeza absoluta?</AlertDialogTitle>
                                                    <AlertDialogDescription>Esta ação não pode ser desfeita. Isto irá apagar permanentemente o ticket e todas as suas mensagens.</AlertDialogDescription>
                                                </AlertDialogHeader>
                                                <AlertDialogFooter>
                                                    <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                                    <AlertDialogAction onClick={() => handleDelete(ticket.id)}>Sim, apagar ticket</AlertDialogAction>
                                                </AlertDialogFooter>
                                            </AlertDialogContent>
                                  _  </AlertDialog>
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
