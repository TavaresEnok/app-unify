import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { timestampDate, type TimestampValue } from '@/shared/api/timestamp';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { MessageSquare, Send, Activity, Bell, Users } from "lucide-react";
import { ProviderDashboardSkeleton } from '@/components/ProviderDashboardSkeleton';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import StatsCard from '@/components/StatsCard';
import { Button } from '@/components/ui/button';
import StatusBadge from '@/components/StatusBadge';
import { useApi } from '@/hooks/useApi';
import { reportPanelReady } from '@/shared/api/panelTiming';

interface RecentTicket {
    id: string;
    subject: string;
    status: 'Aberto' | 'Em Andamento' | 'Fechado';
    updatedAt?: TimestampValue;
}

export default function ProviderDashboardPage() {
    const navigate = useNavigate();
    const { user, providerId } = useAuth();
    const { callFunction } = useApi();
    const [stats, setStats] = useState<{ totalClients: number; openTicketsCount: number; notificationCount?: number }>({ totalClients: 0, openTicketsCount: 0 });
    const [error, setError] = useState(false);
    const [recentTickets, setRecentTickets] = useState<RecentTicket[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => { if (!loading && !error && user) reportPanelReady(user); }, [loading, error, user]);

    const fetchDashboardData = useCallback(async () => {
        if (!providerId || !user) {
            setLoading(false);
            return;
        }

        setLoading(true);
        setError(false);
        try {
            const result = await callFunction('GET_PROVIDER_DASHBOARD_DATA', { providerId });
            setStats((result.stats as typeof stats) || { totalClients: 0, openTicketsCount: 0 });
            setRecentTickets((result.recentTickets as RecentTicket[]) || []);
        } catch (error) {
            console.error("Falha ao carregar dashboard", error);
            setError(true);
        } finally {
            setLoading(false);
        }
    }, [providerId, user, callFunction]);

    useEffect(() => {
        void fetchDashboardData();
    }, [fetchDashboardData]);

    if (loading) {
        return <ProviderDashboardSkeleton />;
    }

    if (error) return <Card><CardHeader><CardTitle>Não foi possível carregar a visão geral</CardTitle></CardHeader><CardContent><Button onClick={() => void fetchDashboardData()}>Tentar novamente</Button></CardContent></Card>;

    return (
        <div className="space-y-5">
            <div className="flex flex-col items-start justify-between gap-4 sm:flex-row sm:items-end">
                <div>
                    <h2 className="m-0 mb-1 text-xl font-bold tracking-normal text-[#0E1320]">Visão geral</h2>
                    <p className="m-0 text-[13px] text-[#687181]">Resumo da operação do seu provedor hoje.</p>
                </div>
                <Button onClick={() => navigate('/provedor/comunicados/notificacoes')} className="gap-1.5">
                    <Send className="h-3.5 w-3.5" />
                    Enviar notificação
                </Button>
            </div>

            <div className="grid gap-3.5 md:grid-cols-3">
                <StatsCard title="Clientes sincronizados" value={stats.totalClients} icon={Users} />
                <StatsCard title="Chamados abertos" value={stats.openTicketsCount} icon={MessageSquare} />
                <StatsCard title="Notificações (24h)" value={stats.notificationCount ?? "—"} icon={Bell} />
            </div>

            <div className="grid gap-4 xl:grid-cols-[.85fr_1.15fr]">
                <Card><CardHeader><CardTitle>Ações rápidas</CardTitle></CardHeader><CardContent className="flex flex-col items-start gap-3">
                    <Button variant="outline" onClick={() => navigate('/provedor/atendimento/diagnosticos')}><Activity className="mr-2 h-4 w-4" />Consultar diagnósticos</Button>
                    <Button variant="outline" onClick={() => navigate('/provedor/comunicados/instabilidades')}><Bell className="mr-2 h-4 w-4" />Publicar aviso de instabilidade</Button>
                    <Button variant="outline" onClick={() => navigate('/provedor/aplicativo')}>Abrir downloads do aplicativo</Button>
                </CardContent></Card>

                <Card className="overflow-hidden">
                    <CardHeader className="flex-row items-center justify-between space-y-0 border-b border-[#EEF0F4]">
                        <div>
                            <CardTitle>Chamados recentes</CardTitle>
                            <p className="mt-0.5 text-[12px] text-[#98A1B1]">Solicitações recentes da sua operação.</p>
                        </div>
                        <Button variant="link" size="sm" onClick={() => navigate('/provedor/atendimento/chamados')} className="h-auto px-0 text-[12px] font-semibold">
                            Ver todos
                        </Button>
                    </CardHeader>
                    <CardContent className="p-0">
                        {recentTickets.length === 0 ? (
                            <div className="py-10 text-center text-[13px] text-[#98A1B1]">Nenhum ticket recente.</div>
                        ) : (
                            recentTickets.map((ticket) => (
                                <button
                                    key={ticket.id}
                                    type="button"
                                    className="grid w-full grid-cols-[1fr_auto] gap-x-3 gap-y-1 border-b border-[#F2F4F7] px-[18px] py-[11px] text-left transition-colors last:border-b-0 hover:bg-[#F8FAFC]"
                                    onClick={() => navigate(`/provedor/atendimento/chamados/${ticket.id}`)}
                                >
                                    <span className="truncate text-[13px] font-semibold text-[#1A2233]">{ticket.subject}</span>
                                    <StatusBadge status={ticket.status} className="justify-self-end" />
                                    <span className="col-span-2 font-mono text-[11.5px] text-[#98A1B1]">
                                        {timestampDate(ticket.updatedAt) ? format(timestampDate(ticket.updatedAt)!, "dd/MM/yyyy 'às' HH:mm", { locale: ptBR }) : 'N/A'}
                                    </span>
                                </button>
                            ))
                        )}
                    </CardContent>
                </Card>
            </div>
        </div>
    );
}
