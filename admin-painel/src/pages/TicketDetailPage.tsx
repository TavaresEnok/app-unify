import { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Textarea } from '@/components/ui/textarea';
import { Loader2, ArrowLeft, Send } from 'lucide-react';
import StatusBadge from '@/components/StatusBadge';
import { subscribeTicket } from '@/features/tickets/ticketService';
import { useApi } from '@/hooks/useApi';
// Import de { Skeleton } removido - TS6133

interface Message {
    id: string;
    senderEmail: string;
    message?: string;
    imageUrl?: string;
    timestamp: { seconds: number; nanoseconds: number };
}

interface Ticket {
    id: string;
    subject: string;
    status: 'Aberto' | 'Em Andamento' | 'Fechado';
    createdBy: string;
    providerName: string;
    updatedAt: { seconds: number; nanoseconds: number };
}

const formatTimestamp = (timestamp: { seconds: number; nanoseconds: number }) => {
    const date = new Date(timestamp.seconds * 1000);
    return date.toLocaleString('pt-BR');
};

export default function TicketDetailPage() {
    const { ticketId } = useParams<{ ticketId: string }>();
    const navigate = useNavigate();
    const { user } = useAuth();
    const { callFunction } = useApi();
    const [ticket, setTicket] = useState<Ticket | null>(null);
    const [messages, setMessages] = useState<Message[]>([]);
    const [newMessage, setNewMessage] = useState('');
    const [loading, setLoading] = useState(true);
    const [isSending, setIsSending] = useState(false);

    useEffect(() => {
        if (!ticketId) return;
        return subscribeTicket(ticketId, {
            onTicket: (value) => { setTicket(value as Ticket | null); setLoading(false); },
            onMessages: (value) => setMessages(value as Message[]),
            onError: (error) => { console.error("Erro ao carregar ticket", error); toast.error("Erro ao carregar ticket."); setLoading(false); },
        });
    }, [ticketId]);


    // 2. Reply Logic
    const handleReply = useCallback(async () => {
        if (!ticketId || !user || !newMessage.trim()) return;

        setIsSending(true);
        try {
            await callFunction('REPLY_TO_TICKET', { ticketId, message: newMessage.trim() });
            setNewMessage('');
        } catch (error: any) {
            console.error("Falha ao responder ticket", error);
        } finally {
            setIsSending(false);
        }
    }, [ticketId, user, newMessage, callFunction]);

    // 3. Status Update Logic
    const handleUpdateStatus = useCallback(async (newStatus: 'Aberto' | 'Em Andamento' | 'Fechado') => {
        if (!ticketId || !user || !ticket || ticket.status === newStatus) return;

        try {
            await callFunction('UPDATE_TICKET_STATUS', { ticketId, status: newStatus });
        } catch (error: any) {
            console.error("Falha ao atualizar status", error);
        }
    }, [ticketId, user, ticket, callFunction]);

    const initialsFor = (value: string) => value
        .split(/[\s@.]+/)
        .filter(Boolean)
        .slice(0, 2)
        .map((part) => part[0])
        .join('')
        .toUpperCase();

    const messageAuthor = (msg: Message) => {
        if (msg.senderEmail === user?.email) return "Você";
        return msg.senderEmail || ticket?.createdBy || "Atendimento";
    };

    if (loading) {
        return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin" /></div>;
    }

    if (!ticket) {
        return <div className="text-center p-8">Ticket não encontrado ou foi apagado.</div>;
    }

    return (
        <div className="space-y-5">
            <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
                <Button variant="outline" onClick={() => navigate(-1)} className="gap-2">
                    <ArrowLeft className="h-4 w-4" /> Voltar
                </Button>
                <div className="flex flex-wrap gap-2">
                    {ticket.status !== 'Em Andamento' && <Button variant="secondary" onClick={() => handleUpdateStatus('Em Andamento')}>Iniciar Trabalho</Button>}
                    {ticket.status !== 'Fechado' && <Button variant="destructive" onClick={() => handleUpdateStatus('Fechado')}>Fechar Ticket</Button>}
                </div>
            </div>

            <div className="grid gap-4 xl:grid-cols-[1fr_290px]">
                <Card className="min-h-[640px] overflow-hidden">
                    <CardHeader className="border-b border-[#EEF0F4]">
                        <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-start">
                            <div className="min-w-0">
                                <div className="mb-2 flex flex-wrap items-center gap-2">
                                    <StatusBadge status={ticket.status} />
                                    <span className="rounded-full bg-[#EEF0F4] px-2.5 py-0.5 font-mono text-[11px] font-semibold text-[#5B6472]">{ticket.id}</span>
                                </div>
                                <CardTitle className="text-[18px] leading-6">{ticket.subject}</CardTitle>
                                <p className="mt-1 text-[12.5px] text-[#687181]">Solicitado por {ticket.createdBy}</p>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="flex min-h-[520px] flex-col p-0">
                        <div className="flex-1 space-y-0 overflow-y-auto">
                            {messages.length === 0 ? (
                                <div className="py-16 text-center text-[13px] text-[#98A1B1]">Nenhuma mensagem registrada.</div>
                            ) : (
                                messages.map((msg) => (
                                    <div key={msg.id} className="flex gap-3 border-b border-[#F2F4F7] px-[18px] py-4">
                                        <span className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-[#0E1320] text-[11px] font-bold text-white">
                                            {initialsFor(messageAuthor(msg))}
                                        </span>
                                        <div className="min-w-0 flex-1">
                                            <div className="mb-1 flex flex-wrap items-center gap-2">
                                                <span className="text-[13px] font-semibold text-[#1A2233]">{messageAuthor(msg)}</span>
                                                {msg.senderEmail !== ticket.createdBy && <StatusBadge status="Equipe Unify" tone="blue" />}
                                                <span className="font-mono text-[11px] text-[#98A1B1]">{formatTimestamp(msg.timestamp)}</span>
                                            </div>
                                            {msg.message && <p className="whitespace-pre-wrap text-[13px] leading-6 text-[#4A5364]">{msg.message}</p>}
                                            {msg.imageUrl && (
                                                <a href={msg.imageUrl} target="_blank" rel="noopener noreferrer" className="mt-3 inline-block">
                                                    <img src={msg.imageUrl} alt="Anexo" className="max-h-80 max-w-full rounded-lg border border-[#EEF0F4] object-contain" />
                                                    <span className="mt-1 block text-[12px] font-semibold text-primary">Ver imagem</span>
                                                </a>
                                            )}
                                        </div>
                                    </div>
                                ))
                            )}
                        </div>
                        <div className="border-t border-[#EEF0F4] bg-[#FAFBFC] p-[18px]">
                            <Textarea
                                placeholder={ticket.status === 'Fechado' ? "Ticket fechado" : "Digite sua resposta aqui..."}
                                value={newMessage}
                                onChange={(e) => setNewMessage(e.target.value)}
                                rows={4}
                                disabled={isSending || ticket.status === 'Fechado'}
                            />
                            <div className="mt-3 flex flex-wrap items-center justify-between gap-2">
                                <span className="text-[12px] text-[#98A1B1]">{ticket.status === 'Fechado' ? "Respostas desativadas para tickets fechados." : "A resposta será registrada no histórico do ticket."}</span>
                                <Button onClick={handleReply} disabled={isSending || ticket.status === 'Fechado' || !newMessage.trim()} className="gap-2">
                                    {isSending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
                                    Responder
                                </Button>
                            </div>
                        </div>
                    </CardContent>
                </Card>

                <div className="space-y-4">
                    <Card>
                        <CardHeader className="border-b border-[#EEF0F4]">
                            <CardTitle>Detalhes</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4 p-[18px] text-[12.5px]">
                            <div>
                                <p className="mb-1 text-[#98A1B1]">Provedor</p>
                                <p className="font-semibold text-[#1A2233]">{ticket.providerName}</p>
                            </div>
                            <div>
                                <p className="mb-1 text-[#98A1B1]">Solicitante</p>
                                <p className="break-words font-semibold text-[#1A2233]">{ticket.createdBy}</p>
                            </div>
                            <div>
                                <p className="mb-1 text-[#98A1B1]">Prioridade</p>
                                <StatusBadge status="Média" tone="gray" />
                            </div>
                            <div>
                                <p className="mb-1 text-[#98A1B1]">Última atualização</p>
                                <p className="font-mono text-[11.5px] text-[#4A5364]">{ticket.updatedAt ? formatTimestamp(ticket.updatedAt) : '-'}</p>
                            </div>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader className="border-b border-[#EEF0F4]">
                            <CardTitle>Ações</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-2 p-[18px]">
                            <Button variant="outline" className="w-full justify-start" onClick={() => handleUpdateStatus('Aberto')} disabled={ticket.status === 'Aberto'}>
                                Reabrir ticket
                            </Button>
                            <Button variant="outline" className="w-full justify-start" onClick={() => handleUpdateStatus('Em Andamento')} disabled={ticket.status === 'Em Andamento'}>
                                Colocar em andamento
                            </Button>
                            <Button className="w-full justify-start bg-[#157347] text-white hover:bg-[#12613c]" onClick={() => handleUpdateStatus('Fechado')} disabled={ticket.status === 'Fechado'}>
                                Marcar como resolvido
                            </Button>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    );
}
