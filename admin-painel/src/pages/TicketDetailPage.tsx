import { useState, useEffect, useCallback, useMemo } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { doc, collection, onSnapshot, query, orderBy, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '@/firebase/config';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Textarea } from '@/components/ui/textarea';
import { Loader2, ArrowLeft } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
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
    const { user, userRole } = useAuth();
    const [ticket, setTicket] = useState<Ticket | null>(null);
    const [messages, setMessages] = useState<Message[]>([]);
    const [newMessage, setNewMessage] = useState('');
    const [loading, setLoading] = useState(true);
    const [isSending, setIsSending] = useState(false);

    const ticketRef = useMemo(() => {
        if (!ticketId) return null;
        return doc(db, 'tickets', ticketId);
    }, [ticketId]);

    // 1. Fetch Ticket Data and Messages
    useEffect(() => {
        if (!ticketRef) return;

        const unsubscribeTicket = onSnapshot(ticketRef, (docSnap) => {
            if (docSnap.exists()) {
                setTicket({ id: docSnap.id, ...docSnap.data() } as Ticket);
            } else {
                toast.error("Ticket não encontrado.");
                setTicket(null);
            }
            setLoading(false);
        }, (error) => {
            console.error("Error fetching ticket:", error);
            setLoading(false);
            toast.error("Erro ao carregar detalhes do ticket.");
        });

        const messagesCollectionRef = collection(ticketRef, 'messages');
        const q = query(messagesCollectionRef, orderBy('timestamp', 'asc'));

        const unsubscribeMessages = onSnapshot(q, (snapshot) => {
            const msgs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Message));
            setMessages(msgs);
        }, (error) => {
            console.error("Error fetching messages:", error);
            toast.error("Erro ao carregar mensagens.");
        });

        return () => {
            unsubscribeTicket();
            unsubscribeMessages();
        };
    }, [ticketRef]);


    // 2. Reply Logic
    const handleReply = useCallback(async () => {
        if (!ticketId || !user || !newMessage.trim()) return;

        setIsSending(true);
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                unsubscribe();
                const response = docSnap.data();
                if (response.result) {
                    setNewMessage('');
                    // Messages update automatically via onSnapshot
                } else {
                    toast.error(`Erro ao enviar resposta: ${response.error}`);
                }
                setIsSending(false);
            }
        });

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'REPLY_TO_TICKET',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: {
                    ticketId,
                    message: newMessage.trim(),
                    userEmail: user.email,
                    isSuperAdmin: userRole === 'superAdmin',
                }
            });
        } catch (error: any) {
            toast.error(`Falha ao solicitar a resposta: ${error.message}`);
            setIsSending(false);
            unsubscribe();
        }
    }, [ticketId, user, newMessage, userRole]);

    // 3. Status Update Logic
    const handleUpdateStatus = useCallback(async (newStatus: 'Aberto' | 'Em Andamento' | 'Fechado') => {
        if (!ticketId || !user || !ticket || ticket.status === newStatus) return;

        const toastId = toast.loading(`A mudar status para ${newStatus}...`);
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                unsubscribe();
                const response = docSnap.data();
                if (response.result) {
                    toast.success(response.result.message, { id: toastId });
                } else {
                    toast.error(`Erro ao atualizar status: ${response.error}`, { id: toastId });
                }
            }
        });

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'UPDATE_TICKET_STATUS',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: {
                    ticketId,
                    status: newStatus,
                }
            });
        } catch (error: any) {
            toast.error(`Falha ao solicitar atualização de status: ${error.message}`, { id: toastId });
            unsubscribe();
        }
    }, [ticketId, user, ticket]);


    const getStatusVariant = (status: Ticket['status']) => {
        switch (status) {
            case 'Aberto': return 'default';
            case 'Em Andamento': return 'secondary';
            case 'Fechado': return 'outline';
            default: return 'default';
        }
    };

    if (loading) {
        return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin" /></div>;
    }

    if (!ticket) {
        return <div className="text-center p-8">Ticket não encontrado ou foi apagado.</div>;
    }

    return (
        <div className="flex flex-col gap-6 h-full">
            <div className="flex items-center justify-between">
                <Button variant="outline" onClick={() => navigate(-1)} className="gap-2">
                    <ArrowLeft className="h-4 w-4" /> Voltar
                </Button>
                <div className="flex gap-2">
                    {ticket.status !== 'Em Andamento' && <Button variant="secondary" onClick={() => handleUpdateStatus('Em Andamento')}>Iniciar Trabalho</Button>}
                    {ticket.status !== 'Fechado' && <Button variant="destructive" onClick={() => handleUpdateStatus('Fechado')}>Fechar Ticket</Button>}
                </div>
            </div>

            <Card className="flex-shrink-0">
                <CardHeader>
                    <CardTitle className="flex items-center justify-between">
                        {ticket.subject}
                        <Badge variant={getStatusVariant(ticket.status)}>{ticket.status}</Badge>
                    </CardTitle>
                    <CardDescription>ID: {ticket.id} | Provedor: {ticket.providerName} | Cliente: {ticket.createdBy}</CardDescription>
                </CardHeader>
            </Card>

            <Card className="flex-1 min-h-0 flex flex-col">
                <CardHeader>
                    <CardTitle>Histórico de Mensagens</CardTitle>
                </CardHeader>
                <CardContent className="flex-1 overflow-y-auto space-y-4">
                    {messages.map((msg) => (
                        <div key={msg.id} className={`p-3 rounded-lg max-w-[80%] ${msg.senderEmail === user?.email ? 'bg-primary text-primary-foreground ml-auto' : 'bg-muted text-muted-foreground mr-auto'}`}>
                            <p className="text-xs font-semibold mb-1">
                                {msg.senderEmail === user?.email ? 'Você' : ticket.createdBy}
                                <span className="ml-2 font-normal text-[10px] opacity-70">{formatTimestamp(msg.timestamp)}</span>
                            </p>
                            {msg.message && <p className="text-sm">{msg.message}</p>}
                            {msg.imageUrl && (
                                <a href={msg.imageUrl} target="_blank" rel="noopener noreferrer" className="mt-2 block">
                                    <img src={msg.imageUrl} alt="Anexo" className="max-w-full h-auto rounded-md shadow-md cursor-pointer" />
                                    <p className="text-xs mt-1 underline">Ver Imagem</p>
                                </a>
                            )}
                        </div>
                    ))}
                </CardContent>
                <div className="p-4 border-t">
                    <Textarea
                        placeholder="Digite sua resposta aqui..."
                        value={newMessage}
                        onChange={(e) => setNewMessage(e.target.value)}
                        rows={3}
                        disabled={isSending || ticket.status === 'Fechado'}
                    />
                    <div className="flex justify-end mt-3">
                        <Button onClick={handleReply} disabled={isSending || ticket.status === 'Fechado' || !newMessage.trim()}>
                            {isSending ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : "Enviar Resposta"}
                        </Button>
                    </div>
                </div>
            </Card>
        </div>
    );
}
