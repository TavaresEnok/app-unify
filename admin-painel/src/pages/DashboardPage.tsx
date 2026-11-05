import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Plus, Server, Users, Bell, MessageSquare } from "lucide-react";
import { DashboardSkeleton } from '@/components/DashboardSkeleton';
import StatsCard from '@/components/StatsCard';
import StatusBadge from '@/components/StatusBadge';
import { useApi } from '@/hooks/useApi';
import { reportPanelReady } from '@/shared/api/panelTiming';

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
    const { callFunction } = useApi();
    const [stats, setStats] = useState({ providerCount: 0, clientCount: 0, notificationCount: 0, openTicketsCount: 0 });
    const [chartData, setChartData] = useState<ChartData[]>([]);
    const [recentTickets, setRecentTickets] = useState<RecentTicket[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(false);
    const [retry, setRetry] = useState(0);

    useEffect(() => { if (!loading && !error && user) reportPanelReady(user); }, [loading, error, user]);

    useEffect(() => {
        if (userRole !== 'superAdmin' || !user) {
            setLoading(false);
            return;
        }

        const loadDashboardData = async () => {
            setLoading(true);
            setError(false);
            try {
                const result = await callFunction('GET_DASHBOARD_DATA', {});
                setStats(result.stats as typeof stats);
                setChartData((result.chartData as ChartData[]) || []);
                setRecentTickets((result.recentTickets as RecentTicket[]) || []);
            } catch (error) {
                console.error('Erro ao carregar dashboard:', error);
                setError(true);
            } finally {
                setLoading(false);
            }
        };

        loadDashboardData();
    }, [userRole, user, callFunction, retry]);

    const maxClients = Math.max(...chartData.map(item => item.clientes), 1);
    const visibleProviders = chartData.slice(0, 6);
    const formatClientCount = (value: number) => new Intl.NumberFormat('pt-BR').format(value);

    if (loading) {
        return <DashboardSkeleton />;
    }

    if (error) return <Card><CardHeader><CardTitle>Não foi possível carregar a visão geral</CardTitle></CardHeader><CardContent><Button onClick={() => setRetry(value => value + 1)}>Tentar novamente</Button></CardContent></Card>;

    return (
        <div className="space-y-5 fade-in">
            <div className="flex flex-col items-start justify-between gap-4 sm:flex-row sm:items-end">
                <div>
                    <h2 className="m-0 mb-1 text-xl font-bold tracking-normal text-[#0E1320]">Visão geral</h2>
                    <p className="m-0 text-[13px] text-[#687181]">Acompanhe a operação de todos os provedores da plataforma.</p>
                </div>
                <div className="flex gap-2.5">
                    <Button onClick={() => navigate('/provedores')} className="gap-1.5">
                        <Plus className="h-3.5 w-3.5" />
                        Novo provedor
                    </Button>
                </div>
            </div>

            <div className="grid gap-3.5 md:grid-cols-2 lg:grid-cols-4">
                <StatsCard
                    title="Total de Provedores"
                    value={stats.providerCount}
                    icon={Server}
                />
                <StatsCard
                    title="Perfis de assinantes"
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

            <div className="grid grid-cols-1 gap-3.5 xl:grid-cols-2">
                <Card className="overflow-hidden">
                    <CardHeader className="border-b border-[#EEF0F4]">
                        <CardTitle>Clientes por provedor</CardTitle>
                        <CardDescription>Base sincronizada via SGP.</CardDescription>
                    </CardHeader>
                    <CardContent className="flex flex-col gap-3 p-[18px]">
                        {visibleProviders.length === 0 ? (
                            <div className="py-10 text-center text-[13px] text-[#98A1B1]">Nenhum provedor com clientes sincronizados.</div>
                        ) : (
                            visibleProviders.map((item) => (
                                <div key={item.name} className="grid grid-cols-[118px_1fr_52px] items-center gap-3">
                                    <span className="truncate text-[12.5px] font-medium text-[#39414F]">{item.name}</span>
                                    <div className="h-2 overflow-hidden rounded-full bg-[#EEF1F6]">
                                        <div
                                            className="h-full rounded-full bg-primary"
                                            style={{ width: `${Math.round((item.clientes / maxClients) * 100)}%` }}
                                        />
                                    </div>
                                    <span className="text-right font-mono text-[11.5px] text-[#687181]">{formatClientCount(item.clientes)}</span>
                                </div>
                            ))
                        )}
                    </CardContent>
                </Card>

                <Card className="overflow-hidden">
                    <CardHeader className="flex-row items-center justify-between space-y-0 border-b border-[#EEF0F4]">
                        <CardTitle>Tickets recentes</CardTitle>
                        <Button variant="link" size="sm" onClick={() => navigate('/tickets')} className="h-auto px-0 text-[12px] font-semibold">
                            Ver todos
                        </Button>
                    </CardHeader>
                    <CardContent className="p-0">
                        {recentTickets.length === 0 ? (
                            <div className="py-10 text-center text-[13px] text-[#98A1B1]">Nenhum ticket encontrado.</div>
                        ) : (
                            recentTickets.map((ticket) => (
                                <button
                                    key={ticket.id}
                                    type="button"
                                    onClick={() => navigate(`/tickets/${ticket.id}`)}
                                    className="grid w-full grid-cols-[1fr_auto] gap-x-3 gap-y-1 border-b border-[#F2F4F7] px-[18px] py-[11px] text-left transition-colors last:border-b-0 hover:bg-[#F8FAFC]"
                                >
                                    <span className="truncate text-[13px] font-semibold text-[#1A2233]">{ticket.subject}</span>
                                    <StatusBadge status={ticket.status} className="justify-self-end" />
                                    <span className="col-span-2 truncate text-[11.5px] text-[#98A1B1]">{ticket.providerName}</span>
                                </button>
                            ))
                        )}
                    </CardContent>
                </Card>
            </div>
        </div>
    );
};
