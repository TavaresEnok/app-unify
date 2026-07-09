import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { toast } from "sonner";
import { collection, getDocs, query, where, orderBy, limit } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Server, Users, Bell, MessageSquare } from "lucide-react";
import ClientsChart from '@/components/ClientsChart';
import { DashboardSkeleton } from '@/components/DashboardSkeleton';
import StatsCard from '@/components/StatsCard';

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

        const loadDashboardData = async () => {
            try {
                // 1. Contar provedores
                const providersSnapshot = await getDocs(collection(db, 'provedores'));
                const providerCount = providersSnapshot.size;

                // 2. Preparar dados do gráfico (provedores)
                const chartDataTemp: ChartData[] = [];
                providersSnapshot.forEach(doc => {
                    const data = doc.data();
                    chartDataTemp.push({
                        name: data.name || doc.id,
                        clientes: data.clientCount || 0
                    });
                });
                setChartData(chartDataTemp);

                // 3. Contar usuários (clientes)
                let clientCount = 0;
                try {
                    const usersSnapshot = await getDocs(collection(db, 'users'));
                    clientCount = usersSnapshot.size;
                } catch (e) {
                    console.log('Coleção users não existe ou sem permissão');
                }

                // 4. Contar tickets abertos
                let openTicketsCount = 0;
                let recentTicketsTemp: RecentTicket[] = [];
                try {
                    const openTicketsQuery = query(
                        collection(db, 'tickets'),
                        where('status', 'in', ['Aberto', 'Em Andamento'])
                    );
                    const openTicketsSnapshot = await getDocs(openTicketsQuery);
                    openTicketsCount = openTicketsSnapshot.size;

                    // Tickets recentes
                    const recentTicketsQuery = query(
                        collection(db, 'tickets'),
                        orderBy('updatedAt', 'desc'),
                        limit(5)
                    );
                    const recentTicketsSnapshot = await getDocs(recentTicketsQuery);
                    recentTicketsTemp = recentTicketsSnapshot.docs.map(doc => {
                        const data = doc.data();
                        return {
                            id: doc.id,
                            subject: data.subject || 'Sem assunto',
                            providerName: data.providerName || 'Desconhecido',
                            status: data.status || 'Aberto',
                            updatedAt: data.updatedAt
                        };
                    });
                } catch (e) {
                    console.log('Coleção tickets não existe ou sem permissão');
                }
                setRecentTickets(recentTicketsTemp);

                // 5. Contar notificações (últimas 24h)
                let notificationCount = 0;
                try {
                    const notificationsSnapshot = await getDocs(collection(db, 'notifications'));
                    notificationCount = notificationsSnapshot.size;
                } catch (e) {
                    console.log('Coleção notifications não existe ou sem permissão');
                }

                // Atualizar stats
                setStats({
                    providerCount,
                    clientCount,
                    notificationCount,
                    openTicketsCount
                });

                setLoading(false);
            } catch (error: any) {
                console.error('Erro ao carregar dashboard:', error);
                toast.error(`Erro ao carregar dados: ${error.message}`);
                setLoading(false);
            }
        };

        loadDashboardData();
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
        <div className="flex flex-col gap-8 fade-in p-2">
            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
                <StatsCard
                    title="Total de Provedores"
                    value={stats.providerCount}
                    icon={Server}
                />
                <StatsCard
                    title="Total de Clientes (App)"
                    value={stats.clientCount}
                    icon={Users}
                />
                <StatsCard
                    title="Tickets Abertos"
                    value={stats.openTicketsCount}
                    icon={MessageSquare}
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
                                {recentTickets.length === 0 ? (
                                    <TableRow>
                                        <TableCell colSpan={3} className="text-center text-muted-foreground">
                                            Nenhum ticket encontrado
                                        </TableCell>
                                    </TableRow>
                                ) : (
                                    recentTickets.map((ticket) => (
                                        <TableRow key={ticket.id} className="cursor-pointer hover:bg-muted/50" onClick={() => navigate(`/tickets/${ticket.id}`)}>
                                            <TableCell className="font-medium">{ticket.subject}</TableCell>
                                            <TableCell>{ticket.providerName}</TableCell>
                                            <TableCell><Badge variant={getStatusVariant(ticket.status)}>{ticket.status}</Badge></TableCell>
                                        </TableRow>
                                    ))
                                )}
                            </TableBody>
                        </Table>
                    </CardContent>
                </Card>
            </div>
        </div>
    );
};
