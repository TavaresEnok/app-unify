import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { toast } from "sonner";
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Server, Users, Bell, MessageSquare } from "lucide-react";
import ClientsChart from '@/components/ClientsChart';
import { DashboardSkeleton } from '@/components/DashboardSkeleton';
import StatsCard from '@/components/StatsCard'; // Novo Componente

interface ChartData { name: string; clientes: number; }
interface RecentTicket {
    id: string;
    subject: string;
    providerName: string;
    status: 'Aberto' | 'Em Andamento' | 'Fechado';
    updatedAt: { _seconds: number; _nanoseconds: number; };
}

export default function DashboardPage() {
    const { userRole, user } = useAuth();
    const navigate = useNavigate();
    const [stats, setStats] = useState({ providerCount: 0, clientCount: 0, notificationCount: 0, openTicketsCount: 0 });
    const [chartData, setChartData] = useState<ChartData[]>([]);
    const [recentTickets, setRecentTickets] = useState<RecentTicket[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (userRole !== 'superAdmin' || !user) {
            setLoading(false);
            return;
        }

        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                if (response.result) {
                    const data = response.result;
                    setStats(data.stats);
                    setChartData(data.chartData);
                    setRecentTickets(data.recentTickets || []);
                } else if (response.error) {
                    toast.error(`Erro no Dashboard: ${response.error}`);
                }
                setLoading(false);
                unsubscribe();
            }
        });

        const triggerFunction = async () => {
            try {
                const requestDocRef = doc(db, 'function_requests', requestId);
                await setDoc(requestDocRef, {
                    type: 'GET_DASHBOARD_DATA',
                    requesterUid: user.uid,
                    createdAt: serverTimestamp(),
                });
            } catch (error: any) {
                toast.error(`Falha ao solicitar dados: ${error.message}`);
                setLoading(false);
                unsubscribe();
            }
        };

        triggerFunction();
        return () => unsubscribe();
    }, [userRole, user]);

    const getStatusVariant = (status: RecentTicket['status']) => {
        switch (status) {
            case 'Aberto': return 'default';
            case 'Em Andamento': return 'secondary';
            case 'Fechado': return 'outline';
            default: return 'default';
        }
    };

    if (loading) {
        return <DashboardSkeleton />;
    }

    return (
        <div className="flex flex-col gap-6 fade-in">
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <StatsCard 
                    title="Total de Provedores" 
                    value={stats.providerCount} 
                    icon={Server} 
                    trend={5} // Simulação
                />
                <StatsCard 
                    title="Total de Clientes (App)" 
                    value={stats.clientCount} 
                    icon={Users} 
                    trend={12} // Simulação
                />
                <StatsCard 
                    title="Tickets Abertos" 
                    value={stats.openTicketsCount} 
                    icon={MessageSquare} 
                    trend={-2} // Simulação (negativo é bom aqui, mas a cor será vermelha pela lógica padrão, pode ajustar depois)
                />
                <StatsCard 
                    title="Notificações (24h)" 
                    value={stats.notificationCount} 
                    icon={Bell} 
                />
            </div>

            <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
                <Card className="xl:col-span-1 shadow-sm">
                    <CardHeader>
                        <CardTitle>Clientes por Provedor</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <ClientsChart data={chartData} />
                    </CardContent>
                </Card>
                 <Card className="xl:col-span-1 shadow-sm">
                    <CardHeader>
                        <CardTitle>Atividade Recente de Tickets</CardTitle>
                        <CardDescription>Os últimos 5 tickets atualizados.</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead>Assunto</TableHead>
                                    <TableHead>Provedor</TableHead>
                                    <TableHead>Status</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {recentTickets.map((ticket) => (
                                    <TableRow key={ticket.id} className="cursor-pointer hover:bg-muted/50" onClick={() => navigate(`/tickets/${ticket.id}`)}>
                                        <TableCell className="font-medium">{ticket.subject}</TableCell>
                                        <TableCell>{ticket.providerName}</TableCell>
                                        <TableCell><Badge variant={getStatusVariant(ticket.status)}>{ticket.status}</Badge></TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    </CardContent>
                </Card>
            </div>
        </div>
    );
};
