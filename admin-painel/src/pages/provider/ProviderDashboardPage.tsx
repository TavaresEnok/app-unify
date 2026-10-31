import { useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { timestampDate, type TimestampValue } from '@/shared/api/timestamp';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { MessageSquare, Send, Smartphone, Star, Users } from "lucide-react";
import { ProviderDashboardSkeleton } from '@/components/ProviderDashboardSkeleton';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import StatsCard from '@/components/StatsCard';
import { Button } from '@/components/ui/button';
import StatusBadge from '@/components/StatusBadge';
import { useApi } from '@/hooks/useApi';
import { useDashboardState, measuredCount } from '@/shared/api/dashboardState';
import { reportPanelReady } from '@/shared/api/panelTiming';

interface RecentTicket {
    id: string;
    subject: string;
    status: 'Aberto' | 'Em Andamento' | 'Fechado';
    updatedAt?: TimestampValue;
}

export default function ProviderDashboardPage() {
    const navigate = useNavigate();
    const { user, userRole, providerId } = useAuth();
    const { callFunction } = useApi();
    const request = useCallback(() => callFunction('GET_PROVIDER_DASHBOARD_DATA', { providerId: providerId! }, { silent: true }), [callFunction, providerId]);
    const dashboard = useDashboardState(user, userRole, providerId, !!user && !!providerId && userRole === 'providerAdmin', request);
    const { status, data } = dashboard;
    const stats = (data?.stats || {}) as Record<string, unknown>;
    const recentTickets = Array.isArray(data?.recentTickets) ? data.recentTickets as RecentTicket[] : undefined;
    useEffect(() => { if (status === 'ready' && user) reportPanelReady(user); }, [status, user]);

    return (
        <div className="space-y-5">
            <div className="flex flex-col items-start justify-between gap-4 sm:flex-row sm:items-end">
                <div>
                    <h2 className="m-0 mb-1 text-xl font-bold tracking-normal text-[#0E1320]">Visão geral</h2>
                    <p className="m-0 text-[13px] text-[#687181]">Contagens de registros do provedor consultadas no Firestore; sem garantia de frescor da origem.</p>
                </div>
                <Button onClick={() => navigate('/provedor/notificacoes')} className="gap-1.5">
                    <Send className="h-3.5 w-3.5" />
                    Enviar notificação
                </Button>
            </div>

            <Button variant="outline" onClick={() => void dashboard.reload()} disabled={status === 'loading' || status === 'denied'}>Recarregar</Button>
            {status === 'loading' && <div role="status">Carregando…<ProviderDashboardSkeleton /></div>}
            {status === 'denied' && <p role="alert">Sessão sem acesso ao dashboard do provedor.</p>}
            {status === 'error' && <p role="alert">Não foi possível carregar os dados. Tente recarregar.</p>}
            {(status === 'stale' || (status === 'loading' && data)) && <p role="status">Dados desatualizados da consulta anterior.</p>}
            {data && <>
            <div className="grid gap-3.5 md:grid-cols-2 lg:grid-cols-4">
                <StatsCard title="Registros de clientes" value={measuredCount(stats.totalClients)} icon={Users} description="Total cadastrado no Firestore, sem período." />
                <StatsCard title="Instalações do app" value="N/D" icon={Smartphone} description="Medição indisponível." />
                <StatsCard title="Tickets abertos" value={measuredCount(stats.openTicketsCount)} icon={MessageSquare} description="Firestore: Aberto ou Em Andamento, sem período." />
                <StatsCard title="Nota Play Store" value="N/D" icon={Star} description="Medição indisponível." />
            </div>

            <div className="grid gap-4 xl:grid-cols-[1.05fr_.95fr]">
                <Card className="overflow-hidden">
                    <CardHeader className="flex-row items-center justify-between space-y-0 border-b border-[#EEF0F4]">
                        <div>
                            <CardTitle>Novas adesões</CardTitle>
                            <p className="mt-0.5 text-[12px] text-[#98A1B1]">Sem série medida de ativações no app.</p>
                        </div>
                    </CardHeader>
                    <CardContent className="p-[18px]">
                        <p>N/D — Medição de adesões indisponível.</p>
                    </CardContent>
                </Card>

                <Card className="overflow-hidden">
                    <CardHeader className="flex-row items-center justify-between space-y-0 border-b border-[#EEF0F4]">
                        <div>
                            <CardTitle>Seus tickets</CardTitle>
                            <p className="mt-0.5 text-[12px] text-[#98A1B1]">Solicitações recentes da sua operação.</p>
                        </div>
                        <Button variant="link" size="sm" onClick={() => navigate('/provedor/tickets')} className="h-auto px-0 text-[12px] font-semibold">
                            Ver todos
                        </Button>
                    </CardHeader>
                    <CardContent className="p-0">
                        {!recentTickets || recentTickets.length === 0 ? (
                            <div className="py-10 text-center text-[13px] text-[#98A1B1]">{recentTickets ? 'Nenhum ticket recente.' : 'Tickets indisponíveis.'}</div>
                        ) : (
                            recentTickets.map((ticket) => (
                                <button
                                    key={ticket.id}
                                    type="button"
                                    className="grid w-full grid-cols-[1fr_auto] gap-x-3 gap-y-1 border-b border-[#F2F4F7] px-[18px] py-[11px] text-left transition-colors last:border-b-0 hover:bg-[#F8FAFC]"
                                    onClick={() => navigate(`/provedor/tickets/${ticket.id}`)}
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
            </>}
        </div>
    );
}
