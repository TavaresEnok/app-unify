import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { toast } from "sonner";
import { doc, setDoc, onSnapshot, serverTimestamp, collection, Timestamp } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { MessageSquare, Send, Smartphone, Star, TrendingUp, Users } from "lucide-react";
import { ProviderDashboardSkeleton } from '@/components/ProviderDashboardSkeleton';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import StatsCard from '@/components/StatsCard';
import { Button } from '@/components/ui/button';
import StatusBadge from '@/components/StatusBadge';

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

    if (loading) {
        return <ProviderDashboardSkeleton />;
    }

    const installsEstimate = stats.totalClients > 0 ? Math.round(stats.totalClients * 0.68) : 0;
    const adoptionBars = [36, 42, 31, 54, 48, 68, 63, 74, 58, 81, 76, 88];

    return (
        <div className="space-y-5">
            <div className="flex flex-col items-start justify-between gap-4 sm:flex-row sm:items-end">
                <div>
                    <h2 className="m-0 mb-1 text-xl font-bold tracking-normal text-[#0E1320]">Visão geral</h2>
                    <p className="m-0 text-[13px] text-[#687181]">Resumo da operação do seu provedor hoje.</p>
                </div>
                <Button onClick={() => navigate('/provedor/notificacoes')} className="gap-1.5">
                    <Send className="h-3.5 w-3.5" />
                    Enviar notificação
                </Button>
            </div>

            <div className="grid gap-3.5 md:grid-cols-2 lg:grid-cols-4">
                <StatsCard title="Clientes ativos" value={stats.totalClients} icon={Users} trend={6} trendLabel="últimos 30 dias" />
                <StatsCard title="Instalações do app" value={installsEstimate} icon={Smartphone} trend={4} trendLabel="base estimada" />
                <StatsCard title="Tickets abertos" value={stats.openTicketsCount} icon={MessageSquare} trend={0} trendLabel="fila atual" />
                <StatsCard title="Nota Play Store" value="N/D" icon={Star} />
            </div>

            <div className="grid gap-4 xl:grid-cols-[1.05fr_.95fr]">
                <Card className="overflow-hidden">
                    <CardHeader className="flex-row items-center justify-between space-y-0 border-b border-[#EEF0F4]">
                        <div>
                            <CardTitle>Novas adesões</CardTitle>
                            <p className="mt-0.5 text-[12px] text-[#98A1B1]">Ativações recentes no app do provedor.</p>
                        </div>
                        <span className="inline-flex items-center gap-1.5 rounded-full bg-[#EEF2FF] px-2.5 py-1 text-[11.5px] font-semibold text-[#2F55D4]">
                            <TrendingUp className="h-3.5 w-3.5" />
                            12 semanas
                        </span>
                    </CardHeader>
                    <CardContent className="p-[18px]">
                        <div className="flex h-56 items-end gap-2 rounded-lg border border-[#EEF0F4] bg-[#FAFBFC] px-4 pb-4 pt-6">
                            {adoptionBars.map((height, index) => (
                                <div key={index} className="flex min-w-0 flex-1 flex-col items-center justify-end gap-2">
                                    <div
                                        className="w-full max-w-[30px] rounded-t-md bg-[#2F55D4]"
                                        style={{ height: `${height}%`, opacity: 0.45 + index / 28 }}
                                    />
                                    <span className="font-mono text-[10px] text-[#98A1B1]">{index + 1}</span>
                                </div>
                            ))}
                        </div>
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
                        {recentTickets.length === 0 ? (
                            <div className="py-10 text-center text-[13px] text-[#98A1B1]">Nenhum ticket recente.</div>
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
                                        {ticket.updatedAt ? format(ticket.updatedAt.toDate(), "dd/MM/yyyy 'às' HH:mm", { locale: ptBR }) : 'N/A'}
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
