import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { toast } from "sonner";
import { doc, setDoc, onSnapshot, serverTimestamp, collection, Timestamp } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Users, MessageSquare } from "lucide-react";
import { ProviderDashboardSkeleton } from '@/components/ProviderDashboardSkeleton';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';

interface RecentTicket {
    id: string;
    subject: string;
    status: 'Aberto' | 'Em Andamento' | 'Fechado';
    updatedAt?: Timestamp;
}

export default function ProviderDashboardPage() {
    const navigate = useNavigate();
    const { user, providerId } = useAuth();
    const [stats, setStats] = useState({ totalClients: 0, openTicketsCount: 0 });
    const [recentTickets, setRecentTickets] = useState<RecentTicket[]>([]);
    const [loading, setLoading] = useState(true);

    const fetchDashboardData = useCallback(() => {
        if (!providerId || !user) {
            setLoading(false);
            return () => {};
        }

        setLoading(true);
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                if (response.result) {
                    setStats(response.result.stats || { totalClients: 0, openTicketsCount: 0 });
                    setRecentTickets(response.result.recentTickets || []);
                } else if (response.error) {
                    toast.error(`Erro no Dashboard: ${response.error}`);
                }
                setLoading(false);
                unsubscribe();
            }
        });

        const triggerFunction = async () => {
            try {
                await setDoc(doc(db, 'function_requests', requestId), {
                    type: 'GET_PROVIDER_DASHBOARD_DATA',
                    requesterUid: user.uid,
                    createdAt: serverTimestamp(),
                    payload: { providerId, requesterUid: user.uid }
                });
            } catch (error: any) {
                toast.error(`Falha ao solicitar dados: ${error.message}`);
                setLoading(false);
                unsubscribe();
            }
        };

        triggerFunction();
        return unsubscribe;
    }, [providerId, user]);

    useEffect(() => {
        const unsubscribe = fetchDashboardData();
        return () => {
            if (unsubscribe) unsubscribe();
        };
    }, [fetchDashboardData]);

    const getStatusVariant = (status: RecentTicket['status']) => {
        switch (status) {
            case 'Aberto': return 'default';
            case 'Em Andamento': return 'secondary';
            case 'Fechado': return 'outline';
            default: return 'default';
        }
    };

    if (loading) {
        return <ProviderDashboardSkeleton />;
    }

    return (
        <div className="flex flex-col gap-6">
            <h1 className="text-3xl font-bold tracking-tight">Dashboard do Provedor</h1>
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium">Clientes Ativos (Sincronizados)</CardTitle>
                        <Users className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold">{stats.totalClients}</div>
                    </CardContent>
                </Card>
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium">Tickets de Suporte Abertos</CardTitle>
                        <MessageSquare className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold">{stats.openTicketsCount}</div>
                    </CardContent>
                </Card>
            </div>
            <Card>
                <CardHeader>
                    <CardTitle>Atividade Recente de Tickets</CardTitle>
                    <CardDescription>Os seus 5 tickets de suporte mais recentes.</CardDescription>
                </CardHeader>
                <CardContent>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>Assunto</TableHead>
                                <TableHead>Status</TableHead>
                                <TableHead>Última Atualização</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {recentTickets.map((ticket) => (
                                <TableRow key={ticket.id} className="cursor-pointer" onClick={() => navigate(`/provedor/tickets/${ticket.id}`)}>
                                    <TableCell className="font-medium">{ticket.subject}</TableCell>
                                    <TableCell><Badge variant={getStatusVariant(ticket.status)}>{ticket.status}</Badge></TableCell>
                                    <TableCell>
                                        {ticket.updatedAt ? format(ticket.updatedAt.toDate(), "dd/MM/yyyy 'às' HH:mm", { locale: ptBR }) : 'N/A'}
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                </CardContent>
            </Card>
        </div>
    );
}
