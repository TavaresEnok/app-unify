import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { useApi } from '@/hooks/useApi';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Send, Loader2 } from 'lucide-react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
// Import de useEffect removido - TS6133

// Tipos de Filtro (MOCK, na realidade deveriam vir de uma API de lista de planos/status)
const statusOptions = [
    { value: 'all', label: 'Todos os Status' },
    { value: 'Ativo', label: 'Ativos' },
    { value: 'Suspenso', label: 'Suspensos (Inadimplentes)' },
    { value: 'Ativo V. Reduzida', label: 'Ativos (Velocidade Reduzida)' },
    { value: 'Cancelado', label: 'Cancelados' },
];

const planOptions = [
    { value: 'all', label: 'Todos os Planos' },
    { value: 'VIBE 500 MEGA', label: 'VIBE 500 MEGA' },
    { value: 'VIBE 1 GIGA', label: 'VIBE 1 GIGA' },
    { value: 'ECONOMICO 100', label: 'ECONOMICO 100' },
];

export default function NotificationSenderPage() {
    const [title, setTitle] = useState('');
    const [body, setBody] = useState('');
    const [statusFilter, setStatusFilter] = useState('all');
    const [planFilter, setPlanFilter] = useState('all');

    const { callFunction, loading } = useApi();
    const { providerId, user } = useAuth();

    const history = [
        { title: 'Fatura disponível', meta: 'Todos os clientes · envio recente', date: 'Hoje' },
        { title: 'Manutenção programada', meta: 'Clientes ativos · abertura acompanhada', date: 'Ontem' },
        { title: 'Promoção de upgrade', meta: 'Segmento por plano · campanha salva', date: '28/06' },
    ];
    
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
            await callFunction('SEND_SCOPED_NOTIFICATION_SEGMENTED', {
                // O providerId é incluído, mas o hook useApi o sobrescreverá com o ID do token para garantir segurança.
                providerId, 
                title,
                body,
                statusFilter: statusFilter,
                planFilter: planFilter,
            });
            
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
        <div className="grid grid-cols-1 gap-4 xl:grid-cols-[1fr_360px]">
            <Card className="overflow-hidden">
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
                                <Select value={planFilter} onValueChange={setPlanFilter} disabled={loading}>
                                    <SelectTrigger id="planFilter">
                                        <SelectValue placeholder="Selecione um plano" />
                                    </SelectTrigger>
                                    <SelectContent>
                                        {planOptions.map(option => (
                                            <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>
                                        ))}
                                    </SelectContent>
                                </Select>
                            </div>
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
            </Card>

            <Card className="overflow-hidden">
                <CardHeader className="border-b border-[#EEF0F4]">
                    <CardTitle>Histórico de envios</CardTitle>
                </CardHeader>
                <CardContent className="p-0">
                    {history.map(item => (
                        <div key={`${item.title}-${item.date}`} className="border-b border-[#F2F4F7] px-[18px] py-[13px] last:border-b-0">
                            <div className="flex items-baseline justify-between gap-3">
                                <span className="truncate text-[13px] font-semibold text-[#1A2233]">{item.title}</span>
                                <span className="shrink-0 text-[11.5px] text-[#98A1B1]">{item.date}</span>
                            </div>
                            <div className="mt-1 text-[12px] text-[#98A1B1]">{item.meta}</div>
                        </div>
                    ))}
                </CardContent>
            </Card>
        </div>
    );
}
