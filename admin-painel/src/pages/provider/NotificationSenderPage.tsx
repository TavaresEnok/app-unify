import { useEffect, useState } from 'react';
import { collection, limit, onSnapshot, orderBy, query, where } from 'firebase/firestore';
import { db } from '@/firebase/config';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { useApi } from '@/hooks/useApi';
import { useAuth } from '@/contexts/AuthContext';
import { useSettings } from '@/contexts/SettingsContext';
import { useLocation } from 'react-router-dom';
import { toast } from 'sonner';
import { Send, Loader2 } from 'lucide-react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

// Estados usados pelo filtro de destinatários.
const statusOptions = [
    { value: 'all', label: 'Todos os Status' },
    { value: 'Ativo', label: 'Ativos' },
    { value: 'Suspenso', label: 'Suspensos (Inadimplentes)' },
    { value: 'Ativo V. Reduzida', label: 'Ativos (Velocidade Reduzida)' },
    { value: 'Cancelado', label: 'Cancelados' },
];

export default function NotificationSenderPage({ historyOnly = false }: { historyOnly?: boolean }) {
    const location = useLocation();
    const draft = location.state as { title?: string; body?: string; category?: string } | null;
    const [title, setTitle] = useState(draft?.title || '');
    const [body, setBody] = useState(draft?.body || '');
    const [category, setCategory] = useState(draft?.category || 'info');
    const [statusFilter, setStatusFilter] = useState('all');
    const [planFilter, setPlanFilter] = useState('all');

    const { callFunction, loading } = useApi();
    const { user } = useAuth();
    const { providerId } = useSettings();

    // Histórico real da coleção `notifications` (antes era uma lista fixa
    // fabricada, que aparentava ser estado real para o operador).
    const [historyError, setHistoryError] = useState(false);
    const [historyLoading, setHistoryLoading] = useState(true);
    const [history, setHistory] = useState<{ id: string; title: string; meta: string; date: string }[]>([]);

    useEffect(() => {
        if (!providerId || !historyOnly) return;
        const notificationsQuery = query(
            collection(db, 'notifications'),
            where('providerId', '==', providerId),
            orderBy('createdAt', 'desc'),
            limit(10),
        );
        setHistoryLoading(true);
        setHistoryError(false);
        return onSnapshot(notificationsQuery, (snapshot) => {
            setHistoryLoading(false);
            setHistoryError(false);
            setHistory(snapshot.docs.map((entry) => {
                const data = entry.data();
                const createdAt = data.createdAt?.toDate?.();
                const audience = data.targetCpf ? 'Cliente específico' : (data.planFilter && data.planFilter !== 'all') || (data.statusFilter && data.statusFilter !== 'all') ? 'Público segmentado' : 'Todos os clientes';
                const delivered = typeof data.successCount === 'number'
                    ? ` · ${data.successCount} envio(s) aceito(s) pelo serviço push`
                    : '';
                return {
                    id: entry.id,
                    title: typeof data.title === 'string' ? data.title : 'Notificação',
                    meta: `${audience}${delivered}`,
                    date: createdAt ? createdAt.toLocaleDateString('pt-BR') : '—',
                };
            }));
        }, () => { setHistoryLoading(false); setHistoryError(true); });
    }, [providerId, historyOnly]);


    const handleSendNotification = async () => {
        if (!user) {
            toast.error("Erro de Autenticação", { description: "Usuário não autenticado." });
            return;
        }
        if (!title.trim() || !body.trim()) {
            toast.error("Erro de Validação", { description: "O título e a mensagem não podem estar vazios." });
            return;
        }

        try {
            if (statusFilter === 'all' && planFilter === 'all') {
                await callFunction('SEND_PUSH_NOTIFICATION', { providerId, title: title.trim(), body: body.trim(), category, targetAll: true });
            } else {
                await callFunction('SEND_SCOPED_NOTIFICATION_SEGMENTED', {
                    providerId, title: title.trim(), body: body.trim(), statusFilter, planFilter,
                });
            }

            // Limpa após o sucesso
            setTitle('');
            setBody('');
            setStatusFilter('all');
            setPlanFilter('all');
            
        } catch {
            // O hook useApi já trata os erros com toast.
        }
    };

    return (
        <div className="space-y-4">
            {!historyOnly && <Card className="overflow-hidden">
                <CardHeader className="border-b border-[#EEF0F4]">
                    <CardTitle>Nova notificação push</CardTitle>
                    <p className="mt-0.5 text-[12.5px] text-[#687181]">Envie mensagens para os clientes do aplicativo.</p>
                </CardHeader>
                <CardContent className="p-[18px]">
                    <div className="grid gap-3.5">
                        <div className="grid gap-3.5 sm:grid-cols-2">
                            <div className="grid gap-1.5">
                                <Label htmlFor="statusFilter">Segmento por status</Label>
                                <Select value={statusFilter} onValueChange={setStatusFilter} disabled={loading}>
                                    <SelectTrigger id="statusFilter">
                                        <SelectValue placeholder="Selecione um status" />
                                    </SelectTrigger>
                                    <SelectContent>
                                        {statusOptions.map(option => (
                                            <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                                        ))}
                                    </SelectContent>
                                </Select>
                            </div>
                            <div className="grid gap-1.5">
                                <Label htmlFor="planFilter">Segmento por plano</Label>
                                <Input id="planFilter" value={planFilter === 'all' ? '' : planFilter}
                                    onChange={event => setPlanFilter(event.target.value || 'all')}
                                    placeholder="Nome do plano (opcional)" disabled={loading} />
                            </div>
                        </div>
                        <div className="grid gap-1.5">
                            <Label htmlFor="category">Categoria</Label>
                            <Select value={category} onValueChange={setCategory} disabled={loading || statusFilter !== 'all' || planFilter !== 'all'}>
                                <SelectTrigger id="category"><SelectValue /></SelectTrigger>
                                <SelectContent><SelectItem value="info">Informação</SelectItem><SelectItem value="urgent">Urgente</SelectItem><SelectItem value="promo">Promoção</SelectItem></SelectContent>
                            </Select>
                        </div>
                        <div className="grid gap-1.5">
                            <Label htmlFor="title">Título</Label>
                            <Input
                                id="title"
                                placeholder="Ex.: Manutenção programada"
                                value={title}
                                onChange={(e) => setTitle(e.target.value.substring(0, 50))}
                                disabled={loading}
                            />
                        </div>
                        <div className="grid gap-1.5">
                            <Label htmlFor="body">Mensagem</Label>
                            <Textarea
                                id="body"
                                placeholder="Escreva a mensagem que os clientes receberão..."
                                value={body}
                                onChange={(e) => setBody(e.target.value)}
                                rows={4}
                                disabled={loading}
                            />
                        </div>
                        <Button onClick={handleSendNotification} disabled={loading} className="w-fit gap-2">
                            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
                            {loading ? 'Enviando...' : 'Enviar agora'}
                        </Button>
                    </div>
                </CardContent>
            </Card>}

            {historyOnly && <Card className="overflow-hidden">
                <CardHeader className="border-b border-[#EEF0F4]">
                    <CardTitle>Histórico de envios</CardTitle>
                </CardHeader>
                <CardContent className="p-0">
                    {historyLoading && <p role="status" className="p-4 text-sm">Carregando histórico…</p>}
                    {historyError && <p role="alert" className="p-4 text-sm text-destructive">Não foi possível carregar o histórico de envios.</p>}
                    {!historyLoading && !historyError && history.length === 0 && (
                        <div className="px-[18px] py-[13px] text-[12px] text-[#98A1B1]">Nenhum envio registrado ainda.</div>
                    )}
                    {!historyError && history.map(item => (
                        <div key={item.id} className="border-b border-[#F2F4F7] px-[18px] py-[13px] last:border-b-0">
                            <div className="flex items-baseline justify-between gap-3">
                                <span className="truncate text-[13px] font-semibold text-[#1A2233]">{item.title}</span>
                                <span className="shrink-0 text-[11.5px] text-[#98A1B1]">{item.date}</span>
                            </div>
                            <div className="mt-1 text-[12px] text-[#98A1B1]">{item.meta}</div>
                        </div>
                    ))}
                </CardContent>
            </Card>}
        </div>
    );
}
